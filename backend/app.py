from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from dotenv import load_dotenv
import os
from models.models import SessionLocal, Product
from pydantic import BaseModel
from services.auth import validate_token
import jwt
from datetime import datetime, timedelta

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

class Login(BaseModel):
    username: str
    password: str

@app.get("/")
def root():
    return {"message": "Mpepo Kitchen POS Backend is running!"}

@app.get("/test-db")
def test_db(db: Session = Depends(get_db)):
    count = db.query(Product).count()
    return {"message": "Database connected", "product_count": count}

@app.post("/login")
def login(login: Login):
    if login.username != "admin" or login.password != "password":
        raise HTTPException(status_code=400, detail="Invalid credentials")
    token = jwt.encode(
        {"sub": login.username, "exp": datetime.utcnow() + timedelta(hours=1)},
        os.getenv("SECRET_KEY"),
        algorithm="HS256"
    )
    return {"access_token": token, "token_type": "bearer"}

@app.get("/protected-test")
def protected_test(payload: dict = Depends(validate_token)):
    return {"message": f"You are authenticated as {payload['sub']}!"}