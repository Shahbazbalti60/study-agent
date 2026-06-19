import os
import json
from groq import Groq
from tavily import TavilyClient
from dotenv import load_dotenv

from services.rag_service import RAGService
from models.schemas import Citation, ChatResponse, QuizQuestion, MCQOption, Flashcard

load_dotenv()

LLM_MODEL = os.getenv("LLM_MODEL", "llama-3.1-70b-versatile")


class LLMService:
    """
    The agent brain. Given a user question it:
      1. Tries to answer from your notes (RAG)
      2. Falls back to web search if notes don't have enough info
      3. Generates quizzes and flashcards from retrieved context
    """

    def __init__(self, rag_service: RAGService):
        self.rag    = rag_service
        self.llm    = Groq(api_key=os.getenv("GROQ_API_KEY"))
        self.tavily = TavilyClient(api_key=os.getenv("TAVILY_API_KEY"))

    def _call_llm(self, system: str, user: str, max_tokens: int = 1024) -> str:
        """Helper — calls Groq and returns the text response."""
        response = self.llm.chat.completions.create(
            model=LLM_MODEL,
            max_tokens=max_tokens,
            messages=[
                {"role": "system", "content": system},
                {"role": "user",   "content": user},
            ],
        )
        return response.choices[0].message.content

    # ── Chat ──────────────────────────────────────────────────────────────────

    def chat(self, question: str, collection_name: str = "default") -> ChatResponse:
        # Step 1: retrieve relevant chunks from your notes
        chunks = self.rag.retrieve(question, collection_name)

        used_web = False
        context_text = ""
        citations: list[Citation] = []

        if chunks:
            context_parts = []
            for c in chunks:
                context_parts.append(
                    f"[Source: {c['source']}, Page {c['page']}]\n{c['text']}"
                )
                citations.append(Citation(
                    source=c["source"],
                    page=c["page"],
                    snippet=c["text"][:200],
                ))
            context_text = "\n\n---\n\n".join(context_parts)

        # Step 2: ask the LLM
        system_prompt = """You are a study assistant. Answer questions using ONLY 
the provided context from the student's notes. If the context does not contain 
enough information to answer, respond with exactly: NEED_WEB_SEARCH"""

        user_message = f"""Context from notes:
{context_text if context_text else "(no relevant notes found)"}

Question: {question}"""

        answer = self._call_llm(system_prompt, user_message)

        # Step 3: web search fallback
        if "NEED_WEB_SEARCH" in answer or not chunks:
            used_web = True
            citations = []

            search_results = self.tavily.search(question, max_results=3)
            web_context = "\n\n".join([
                f"[{r['url']}]\n{r['content']}"
                for r in search_results.get("results", [])
            ])

            web_prompt = f"""Answer this question using the web search results below.
Be concise and cite which URL you used.

Search results:
{web_context}

Question: {question}"""

            answer = self._call_llm("You are a helpful study assistant.", web_prompt)

        return ChatResponse(
            answer=answer,
            citations=citations,
            used_web_search=used_web,
        )

    # ── Quiz generation ───────────────────────────────────────────────────────

    def generate_quiz(self, topic: str, num_questions: int,
                      question_type: str, collection_name: str) -> list[QuizQuestion]:
        chunks = self.rag.retrieve(topic, collection_name)
        context = "\n\n".join([c["text"] for c in chunks]) if chunks else topic

        prompt = f"""Generate {num_questions} {question_type} questions about: {topic}

Use this content from the student's notes:
{context}

Return ONLY a valid JSON array. No explanation, no markdown. Format:
[
  {{
    "question": "...",
    "options": [{{"label": "A", "text": "..."}}, {{"label": "B", "text": "..."}}, 
                {{"label": "C", "text": "..."}}, {{"label": "D", "text": "..."}}],
    "correct_answer": "A",
    "explanation": "..."
  }}
]

For short_answer type, set options to null and put the answer in correct_answer."""

        raw = self._call_llm("You are a quiz generator. Return only valid JSON.", prompt, max_tokens=2048)
        raw = raw.replace("```json", "").replace("```", "").strip()
        data = json.loads(raw)

        questions = []
        for q in data:
            options = None
            if q.get("options"):
                options = [MCQOption(label=o["label"], text=o["text"])
                           for o in q["options"]]
            questions.append(QuizQuestion(
                question=q["question"],
                options=options,
                correct_answer=q["correct_answer"],
                explanation=q["explanation"],
            ))
        return questions

    # ── Flashcard generation ──────────────────────────────────────────────────

    def generate_flashcards(self, topic: str, num_cards: int,
                            collection_name: str) -> list[Flashcard]:
        chunks = self.rag.retrieve(topic, collection_name)
        context = "\n\n".join([c["text"] for c in chunks]) if chunks else topic

        prompt = f"""Create {num_cards} flashcards about: {topic}

Use this content from the student's notes:
{context}

Return ONLY a valid JSON array. No explanation, no markdown. Format:
[
  {{"front": "Question or term", "back": "Answer or definition"}}
]"""

        raw = self._call_llm("You are a flashcard generator. Return only valid JSON.", prompt, max_tokens=2048)
        raw = raw.replace("```json", "").replace("```", "").strip()
        data = json.loads(raw)

        return [Flashcard(front=c["front"], back=c["back"]) for c in data]
