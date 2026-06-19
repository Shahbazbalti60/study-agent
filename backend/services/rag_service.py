import os
import fitz                          # PyMuPDF
import chromadb
from chromadb.utils import embedding_functions
from dotenv import load_dotenv

load_dotenv()

CHROMA_DB_PATH   = os.getenv("CHROMA_DB_PATH", "./chroma_db")
EMBEDDING_MODEL  = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
MAX_CHUNK_SIZE   = int(os.getenv("MAX_CHUNK_SIZE", 500))
CHUNK_OVERLAP    = int(os.getenv("CHUNK_OVERLAP", 50))
TOP_K            = int(os.getenv("TOP_K_RESULTS", 5))


class RAGService:
    """
    Handles everything related to your documents:
      1. Parse PDF → raw text per page
      2. Chunk text into overlapping pieces
      3. Embed chunks and store in ChromaDB
      4. Retrieve relevant chunks for a query
    """

    def __init__(self):
        # SentenceTransformer runs locally — no API key needed
        self.embed_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
            model_name=EMBEDDING_MODEL
        )
        self.client = chromadb.PersistentClient(path=CHROMA_DB_PATH)

    # ── Parsing ───────────────────────────────────────────────────────────────

    def parse_pdf(self, file_bytes: bytes, filename: str) -> list[dict]:
        """
        Extract text from every page of a PDF.
        Returns a list of {page, text, source} dicts.
        """
        doc = fitz.open(stream=file_bytes, filetype="pdf")
        pages = []
        for page_num in range(len(doc)):
            text = doc[page_num].get_text().strip()
            if text:   # skip blank pages
                pages.append({
                    "page": page_num + 1,
                    "text": text,
                    "source": filename,
                })
        return pages

    # ── Chunking ──────────────────────────────────────────────────────────────

    def chunk_text(self, text: str, source: str, page: int) -> list[dict]:
        """
        Split a page's text into overlapping chunks so that long pages
        don't get truncated when we pass them to the LLM.
        """
        chunks = []
        start = 0
        while start < len(text):
            end = start + MAX_CHUNK_SIZE
            chunk = text[start:end]
            chunks.append({
                "text": chunk,
                "source": source,
                "page": page,
            })
            start += MAX_CHUNK_SIZE - CHUNK_OVERLAP   # slide with overlap
        return chunks

    # ── Storing ───────────────────────────────────────────────────────────────

    def store_document(self, file_bytes: bytes, filename: str,
                       collection_name: str = "default") -> int:
        """
        Full pipeline: parse PDF → chunk → embed → store in ChromaDB.
        Returns number of chunks stored.
        """
        collection = self.client.get_or_create_collection(
            name=collection_name,
            embedding_function=self.embed_fn,
        )

        pages = self.parse_pdf(file_bytes, filename)
        all_chunks = []
        for page_data in pages:
            chunks = self.chunk_text(page_data["text"], filename, page_data["page"])
            all_chunks.extend(chunks)

        # ChromaDB needs unique IDs per chunk
        ids       = [f"{filename}_p{c['page']}_{i}" for i, c in enumerate(all_chunks)]
        documents = [c["text"] for c in all_chunks]
        metadatas = [{"source": c["source"], "page": c["page"]} for c in all_chunks]

        collection.add(documents=documents, metadatas=metadatas, ids=ids)
        return len(all_chunks)

    # ── Retrieving ────────────────────────────────────────────────────────────

    def retrieve(self, query: str, collection_name: str = "default") -> list[dict]:
        """
        Embed the user's question and find the top-K most similar chunks.
        Returns list of {text, source, page} dicts — ready to pass to the LLM.
        """
        try:
            collection = self.client.get_collection(
                name=collection_name,
                embedding_function=self.embed_fn,
            )
        except Exception:
            return []   # no documents uploaded yet

        results = collection.query(query_texts=[query], n_results=TOP_K)

        chunks = []
        for i, doc in enumerate(results["documents"][0]):
            meta = results["metadatas"][0][i]
            chunks.append({
                "text": doc,
                "source": meta.get("source", "unknown"),
                "page": meta.get("page", 0),
            })
        return chunks

    # ── Utils ─────────────────────────────────────────────────────────────────

    def list_collections(self) -> list[str]:
        return [c.name for c in self.client.list_collections()]
