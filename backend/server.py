import os
import shutil
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

from langchain_community.vectorstores import Chroma
from langchain_community.document_loaders import TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
# Use Local Embeddings (Free, Unlimited, Fast) to avoid Google Rate Limits
from langchain_huggingface import HuggingFaceEmbeddings
# Use Cloud LLM (Gemini) for the heavy lifting
from langchain_google_genai import ChatGoogleGenerativeAI

# LCEL Imports
from langchain_core.prompts import PromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser
import uvicorn

# Load environment variables
load_dotenv()
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

if not GOOGLE_API_KEY:
    print("CRITICAL ERROR: GOOGLE_API_KEY not found in .env")

# --- Configuration ---
CHROMA_PATH = "chroma_db"

# Get absolute path to the directory containing this script
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# Data path relative to this script
DATA_PATH = os.path.join(BASE_DIR, "knowledge_base", "college_data.txt")

# --- Global RAG Chain ---
rag_chain = None

def get_local_embeddings():
    # Uses local CPU, very fast, no rate limits
    return HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    global rag_chain
    print("Initializing Hybrid RAG system (Local Embeddings + Cloud Gemini)...")
    
    # 1. Load Data
    if not os.path.exists(DATA_PATH):
        print(f"Warning: {DATA_PATH} not found. RAG will be empty.")
    else:
        # Clear DB to ensure we use valid Local Embeddings (Google Embeddings are incompatible)
        if os.path.exists(CHROMA_PATH):
             print("Switching embedding model. Clearing old Vector Store...")
             try:
                 shutil.rmtree(CHROMA_PATH)
             except Exception as e:
                 print(f"Could not delete old DB: {e}. If it fails, delete 'backend/chroma_db' manually.")

        loader = TextLoader(DATA_PATH, encoding="utf-8")
        documents = loader.load()

        # 2. Split Text
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
        chunks = text_splitter.split_documents(documents)

        # 3. Embeddings & Vector Store
        print("Loading Local Embeddings (all-MiniLM-L6-v2)...")
        embeddings = get_local_embeddings()

        print("Creating vector store locally...")
        vectorstore = Chroma.from_documents(
            documents=chunks,
            embedding=embeddings,
            persist_directory=CHROMA_PATH
        )
        
        # 4. LLM - Cloud
        print("Connecting to Gemini 2.0 Flash (Experimental)...")
        llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash", temperature=0.3)

        # 5. Retrieval Chain (LCEL)
        retriever = vectorstore.as_retriever(search_kwargs={"k": 3})
        
        template = """You are KIRA, an AI assistant for United Institute of Technology (UIT).
        Use the following pieces of context to answer the question at the end.
        If the context doesn't contain the answer, answer from your general knowledge but mention you are not sure if it applies to UIT specifically.
        Keep the answer concise, friendly, and helpful.
        
        Context:
        {context}
        
        Question: {question}
        
        Helpful Answer:"""
        
        custom_rag_prompt = PromptTemplate.from_template(template)

        def format_docs(docs):
            return "\n\n".join(doc.page_content for doc in docs)

        rag_chain = (
            {"context": retriever | format_docs, "question": RunnablePassthrough()}
            | custom_rag_prompt
            | llm
            | StrOutputParser()
        )
        print("Hybrid RAG system initialized successfully.")
    
    yield
    # Shutdown logic (if any)
    print("Shutting down RAG system...")

app = FastAPI(title="Campus AI Backend", lifespan=lifespan)

# Add CORS Middleware to allow requests from Flutter Web and Android
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    message: str

@app.post("/chat")
async def chat_endpoint(request: ChatRequest):
    global rag_chain
    if not rag_chain:
        if not os.path.exists(DATA_PATH):
            return {"response": "I'm sorry, I cannot access my knowledge base right now."}
        raise HTTPException(status_code=503, detail="RAG system not initialized")
    
    try:
        print(f"Received query: {request.message}")
        result = rag_chain.invoke(request.message)
        print("Response generated.")
        return {"response": result}
    except Exception as e:
        print(f"Error processing request: {e}")
        # Improve error message for quota issues (LLM side)
        if "429" in str(e):
            return {"response": "I'm a bit busy right now (Quota Exceeded). Please try again in a moment."}
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)
