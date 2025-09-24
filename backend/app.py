from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from dotenv import load_dotenv
import os
from models.models import SessionLocal, Product

load_dotenv()

app = FastAPI(title="Mpepo POS Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def root():
    return {"message": "Mpepo Kitchen POS Backend is running!"}

@app.get("/test-db")
def test_db(db: Session = Depends(get_db)):
    count = db.query(Product).count()
    return {"message": "Database connected", "product_count": count}