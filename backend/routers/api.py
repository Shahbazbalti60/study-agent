from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from models.schemas import (
    UploadResponse, ChatRequest, ChatResponse,
    QuizRequest, QuizResponse,
    FlashcardRequest, FlashcardResponse,
    CollectionInfo,
)
from services.rag_service import RAGService
from services.llm_service import LLMService

router = APIRouter()

# Shared service instances (created once at startup)
rag_service = RAGService()
llm_service = LLMService(rag_service)


# ── 1. Upload a PDF ───────────────────────────────────────────────────────────

@router.post("/upload", response_model=UploadResponse)
async def upload_document(
    file: UploadFile = File(...),
    collection_name: str = "default",
):
    """
    Flutter sends a PDF here. We parse, chunk, embed, and store it.
    Flutter receives back how many chunks were stored.
    """
    if not file.filename.endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")

    file_bytes = await file.read()
    chunks_stored = rag_service.store_document(file_bytes, file.filename, collection_name)

    return UploadResponse(
        message="Document uploaded and indexed successfully.",
        filename=file.filename,
        chunks_stored=chunks_stored,
    )


# ── 2. Chat / Q&A ────────────────────────────────────────────────────────────

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Flutter sends a question. We retrieve relevant chunks from notes,
    ask the LLM, and return the answer + citations.
    Falls back to web search automatically if notes don't have the answer.
    """
    try:
        return llm_service.chat(request.question, request.collection_name)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 3. Generate quiz ─────────────────────────────────────────────────────────

@router.post("/quiz", response_model=QuizResponse)
async def generate_quiz(request: QuizRequest):
    """
    Flutter sends a topic + settings.
    Returns a list of MCQ or short-answer questions drawn from your notes.
    """
    try:
        questions = llm_service.generate_quiz(
            topic=request.topic,
            num_questions=request.num_questions,
            question_type=request.question_type,
            collection_name=request.collection_name,
        )
        return QuizResponse(topic=request.topic, questions=questions)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 4. Generate flashcards ────────────────────────────────────────────────────

@router.post("/flashcards", response_model=FlashcardResponse)
async def generate_flashcards(request: FlashcardRequest):
    """
    Flutter sends a topic. Returns front/back flashcard pairs from your notes.
    """
    try:
        cards = llm_service.generate_flashcards(
            topic=request.topic,
            num_cards=request.num_cards,
            collection_name=request.collection_name,
        )
        return FlashcardResponse(topic=request.topic, cards=cards)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 5. List uploaded collections ──────────────────────────────────────────────

@router.get("/collections", response_model=list[str])
async def list_collections():
    """Flutter calls this to show which document sets are available."""
    return rag_service.list_collections()


# ── 6. Health check ───────────────────────────────────────────────────────────

@router.get("/health")
async def health():
    return {"status": "ok"}
