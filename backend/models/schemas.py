from pydantic import BaseModel
from typing import Optional


# ── Upload ────────────────────────────────────────────────────────────────────

class UploadResponse(BaseModel):
    message: str
    filename: str
    chunks_stored: int


# ── Chat ──────────────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    question: str
    collection_name: Optional[str] = "default"   # which doc collection to search


class Citation(BaseModel):
    source: str          # filename
    page: int
    snippet: str         # short excerpt from that chunk


class ChatResponse(BaseModel):
    answer: str
    citations: list[Citation]
    used_web_search: bool


# ── Quiz ──────────────────────────────────────────────────────────────────────

class QuizRequest(BaseModel):
    topic: str                              # e.g. "neural networks"
    num_questions: int = 5
    question_type: str = "mcq"             # "mcq" or "short_answer"
    collection_name: Optional[str] = "default"


class MCQOption(BaseModel):
    label: str    # "A", "B", "C", "D"
    text: str


class QuizQuestion(BaseModel):
    question: str
    options: Optional[list[MCQOption]] = None   # None for short_answer
    correct_answer: str
    explanation: str


class QuizResponse(BaseModel):
    topic: str
    questions: list[QuizQuestion]


# ── Flashcards ────────────────────────────────────────────────────────────────

class FlashcardRequest(BaseModel):
    topic: str
    num_cards: int = 10
    collection_name: Optional[str] = "default"


class Flashcard(BaseModel):
    front: str
    back: str


class FlashcardResponse(BaseModel):
    topic: str
    cards: list[Flashcard]


# ── Collections (list of uploaded docs) ───────────────────────────────────────

class CollectionInfo(BaseModel):
    name: str
    document_count: int
