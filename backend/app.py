from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

load_dotenv()  # Load DB_URL, SECRET_KEY from .env

app = FastAPI(title="Mpepo POS Backend", version="1.0.0")  # Name for auto-docs

# Allow mobile app to connect (CORS)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Later: restrict to Flutter app's URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "Mpepo Kitchen POS Backend is running!"}