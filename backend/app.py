from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy.sql import func
from dotenv import load_dotenv
import os
from models.models import SessionLocal, Product, Order, Invoice
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

@app.get("/reports/sales")
def get_sales_report(db: Session = Depends(get_db), payload: dict = Depends(validate_token)):
    """Get total sales and tax from invoices."""
    result = db.query(
        func.count(Invoice.id).label("total_invoices"),
        func.sum(Invoice.total_amount).label("total_sales"),
        func.sum(Invoice.tax_amount).label("total_tax")
    ).first()
    return {
        "total_invoices": result.total_invoices or 0,
        "total_sales": float(result.total_sales or 0.0),
        "total_tax": float(result.total_tax or 0.0),
        "generated_by": payload["sub"]
    }