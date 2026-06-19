# 📚 Study Agent — Personal AI Study Assistant

A RAG-powered study assistant that ingests your course PDFs, answers questions with citations, generates quizzes and flashcards, and falls back to web search when your notes don't have the answer.

Built to demonstrate the **AI agent / LLM stack** skills required for modern AI internships.

---

## ✨ Features

- **RAG Chat** — Ask questions about your uploaded notes, get answers with source citations (filename + page number)
- **Web Search Fallback** — Automatically searches the web via Tavily when your notes don't cover the topic
- **Quiz Generation** — Generates MCQ quizzes from your notes on any topic
- **Flashcards** — Creates tap-to-flip flashcards for spaced repetition study
- **PDF Upload** — Upload multiple course PDFs; they're chunked, embedded, and stored in a vector database

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Web) |
| Backend | FastAPI (Python) |
| LLM | Groq — llama-3.3-70b-versatile |
| Embeddings | SentenceTransformers — all-MiniLM-L6-v2 (local, free) |
| Vector DB | ChromaDB (local, persistent) |
| PDF Parsing | PyMuPDF |
| Web Search | Tavily API |

---

## 🖼 Screenshots

### Chat with Citations
![Chat Screen](screenshots/chat.png)

### Quiz Generation
![Quiz Screen](screenshots/quiz.png)

### Flashcards
![Flashcard Screen](screenshots/flashcards.png)

---

## 🚀 Setup

### Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate.bat        # Windows
# source venv/bin/activate       # Mac/Linux

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env and add your API keys

# Run the server
python main.py
# API docs at http://localhost:8000/docs
```

### Flutter Frontend

```bash
cd flutter_app
flutter pub get
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

---

## 🔑 API Keys Required

| Service | Free Tier | Get Key |
|---------|-----------|---------|
| Groq | ✅ Free, no card | console.groq.com |
| Tavily | ✅ 1000 searches/month free | tavily.com |

---

## 📁 Project Structure

```
study-agent/
├── backend/
│   ├── main.py                  # FastAPI entry point
│   ├── requirements.txt
│   ├── .env.example
│   ├── models/
│   │   └── schemas.py           # Pydantic request/response models
│   ├── services/
│   │   ├── rag_service.py       # PDF parsing, chunking, embedding, retrieval
│   │   └── llm_service.py       # Chat, quiz gen, flashcard gen, web search
│   └── routers/
│       └── api.py               # All API endpoints
└── flutter_app/
    └── lib/
        ├── main.dart            # App entry + navigation
        ├── models/models.dart   # Data models
        ├── services/api_service.dart  # HTTP client
        ├── screens/
        │   ├── chat_screen.dart
        │   ├── upload_screen.dart
        │   ├── quiz_screen.dart
        │   └── flashcard_screen.dart
        └── widgets/
            └── citation_card.dart
```

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/upload` | Upload and index a PDF |
| POST | `/api/v1/chat` | Ask a question (RAG + web fallback) |
| POST | `/api/v1/quiz` | Generate quiz questions |
| POST | `/api/v1/flashcards` | Generate flashcards |
| GET | `/api/v1/collections` | List uploaded document sets |
| GET | `/api/v1/health` | Health check |

---

## 💡 How It Works

1. **Upload** — PDFs are parsed page by page with PyMuPDF, split into 500-character overlapping chunks, embedded with SentenceTransformers, and stored in ChromaDB
2. **Chat** — User question is embedded and compared against all stored chunks; top 5 most similar chunks are retrieved and passed as context to the LLM
3. **Web fallback** — If the LLM determines the context is insufficient, it automatically calls Tavily web search
4. **Quiz/Flashcards** — LLM generates structured JSON from retrieved context, rendered as interactive UI in Flutter
