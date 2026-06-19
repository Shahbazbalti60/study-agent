from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers.api import router

app = FastAPI(
    title="Study Agent API",
    description="RAG-powered personal study assistant with quiz generation and web search.",
    version="1.0.0",
)

# Allow Flutter app (on any local port or device) to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # tighten this in production
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix="/api/v1")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
