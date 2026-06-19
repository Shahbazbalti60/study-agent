# Personal Study & Research Agent

RAG-powered study assistant. Upload your course PDFs, ask questions with citations,
generate quizzes, and get web search fallback — all via a Flutter app.

## Stack
- **Backend**: FastAPI + Python
- **RAG**: PyMuPDF → ChromaDB + SentenceTransformers
- **LLM**: Claude (Anthropic API)
- **Web search**: Tavily
- **Frontend**: Flutter

## Backend Setup

```bash
cd backend

# 1. Create virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Set up environment variables
cp .env.example .env
# Open .env and add your API keys

# 4. Run the server
python main.py
# Server starts at http://localhost:8000
# API docs at  http://localhost:8000/docs
```

## API Endpoints

| Method | Endpoint | What it does |
|--------|----------|--------------|
| POST | `/api/v1/upload` | Upload a PDF for indexing |
| POST | `/api/v1/chat` | Ask a question (RAG + web fallback) |
| POST | `/api/v1/quiz` | Generate quiz questions |
| POST | `/api/v1/flashcards` | Generate flashcards |
| GET  | `/api/v1/collections` | List uploaded document sets |
| GET  | `/api/v1/health` | Health check |

## Get API Keys (all free tiers available)
- **Anthropic**: https://console.anthropic.com
- **Tavily**: https://tavily.com  (free 1000 searches/month)

## Project Structure

```
study_agent/
├── backend/
│   ├── main.py               # FastAPI app entry point
│   ├── requirements.txt
│   ├── .env.example
│   ├── models/
│   │   └── schemas.py        # Pydantic request/response models
│   ├── services/
│   │   ├── rag_service.py    # PDF parsing, chunking, embedding, retrieval
│   │   └── llm_service.py    # Chat, quiz gen, flashcard gen
│   └── routers/
│       └── api.py            # All API endpoints
└── flutter_app/              # Flutter frontend (Step 2)
```
