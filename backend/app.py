from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

app = FastAPI(title="Riddle AI Backend 🚀")

# Enable CORS for Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Development only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load AI model once
model = SentenceTransformer("all-MiniLM-L6-v2")

# Request model for similarity API
class SimilarityRequest(BaseModel):
    main_word: str
    guess_word: str

@app.get("/")
def home():
    return {"message": "Riddle AI Backend Running 🚀"}

# Route to calculate similarity
@app.post("/similarity")
def calculate_similarity(data: SimilarityRequest):
    try:
        # Generate embeddings
        embeddings = model.encode([data.main_word, data.guess_word])

        # Compute cosine similarity
        similarity = cosine_similarity([embeddings[0]], [embeddings[1]])[0][0]

        # Convert to percentage
        percentage = round(float(similarity) * 100, 2)
        percentage = max(0, min(percentage, 100))

        return {"similarity_percentage": percentage}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
