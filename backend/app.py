from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, create_engine, SQLModel, select
from sqlalchemy.sql import func
from dotenv import load_dotenv
import os
from models.models import Product, Order, Invoice, InvoiceLog
from pydantic import BaseModel
from services.auth import validate_token
import jwt
from datetime import datetime, timedelta, date
import json
from tax_client import submit_invoice as tax_submit_invoice
import logging
from typing import Optional
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

load_dotenv()
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'logs/app-{datetime.now().strftime("%Y%m%d")}.log'),
        logging.StreamHandler()
    ]
)

# Initialize database and create tables
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///C:/projects/pos/backend/pos.db")
engine = create_engine(DATABASE_URL, echo=True)
SQLModel.metadata.create_all(engine)

app = FastAPI(title="Mpepo POS Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",  # Flutter web
        "http://localhost:8000",  # Development
        "http://10.0.2.2:8000",  # Android emulator
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

def get_db():
    with Session(engine) as db:
        yield db

# Pydantic Models
class Login(BaseModel):
    username: str
    password: str

class ProductCreate(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    stock: int

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    stock: Optional[int] = None

class InvoiceSubmission(BaseModel):
    tpin: str
    bhfId: str
    orgInvcNo: float | None = None
    cisInvcNo: str
    custTpin: str | None = None
    custNm: str | None = None
    salesTyCd: str
    rcptTyCd: str
    pmtTyCd: str | None = None
    salesSttsCd: str
    cfmDt: str
    salesDt: str
    stockRlsDt: str | None = None
    cnclReqDt: str | None = None
    cnclDt: str | None = None
    rfdDt: str | None = None
    rfdRsnCd: str | None = None
    totItemCnt: int
    taxblAmtA: float
    taxblAmtB: float | None = None
    taxblAmtC: float | None = None
    taxblAmtD: float | None = None
    taxblAmtE: float | None = None
    taxAmtA: float
    taxAmtB: float | None = None
    taxAmtC: float | None = None
    taxAmtD: float | None = None
    taxAmtE: float | None = None
    totTaxblAmt: float
    totTaxAmt: float
    totAmt: float
    prtMsg: str | None = None
    remark: str | None = None
    regrId: str | None = None
    regrNm: str | None = None
    modrId: str | None = None
    modrNm: str | None = None
    itemList: list

# Health Check Endpoints
@app.get("/")
def root():
    return {"message": "Mpepo Kitchen POS Backend is running!"}

@app.get("/test-db")
def test_db(db: Session = Depends(get_db)):
    count = len(db.exec(select(Product)).all())
    return {"message": "Database connected", "product_count": count}

# Authentication Endpoints
@app.post("/login")
@limiter.limit("5/minute")
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

# Product CRUD Endpoints (Student C)
@app.post("/api/products", response_model=Product)
def create_product(
    product: ProductCreate,
    db: Session = Depends(get_db),
    payload: dict = Depends(validate_token)
):
    """Create a new product (requires authentication)"""
    db_product = Product(**product.model_dump())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@app.get("/api/products")
def get_products(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all products (no authentication required for listing)"""
    products = db.exec(select(Product).offset(skip).limit(limit)).all()
    return products

@app.get("/api/products/{product_id}", response_model=Product)
async def get_product(
    product_id: int,
    db: Session = Depends(get_db)
):
    """Get product by ID with better error handling"""
    product = db.exec(select(Product).where(Product.id == product_id)).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with id {product_id} not found"
        )
    return product

@app.put("/api/products/{product_id}", response_model=Product)
def update_product(
    product_id: int,
    product_update: ProductUpdate,
    db: Session = Depends(get_db),
    payload: dict = Depends(validate_token)
):
    """Update an existing product (requires authentication)"""
    db_product = db.exec(select(Product).where(Product.id == product_id)).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Update only provided fields
    update_data = product_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_product, key, value)
    
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@app.delete("/api/products/{product_id}")
def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    payload: dict = Depends(validate_token)
):
    """Delete a product (requires authentication)"""
    db_product = db.exec(select(Product).where(Product.id == product_id)).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    db.delete(db_product)
    db.commit()
    return {"message": "Product deleted successfully", "id": product_id}

# Reporting Endpoints (Student C)
@app.get("/reports/sales")
def get_sales_report(db: Session = Depends(get_db), payload: dict = Depends(validate_token)):
    """Get aggregated sales report (requires authentication)"""
    result = db.exec(
        select(
            func.count(Invoice.id).label("total_invoices"),
            func.sum(Invoice.total_amount).label("total_sales"),
            func.sum(Invoice.tax_amount).label("total_tax")
        )
    ).first()
    return {
        "total_invoices": result.total_invoices or 0,
        "total_sales": float(result.total_sales or 0.0),
        "total_tax": float(result.total_tax or 0.0),
        "generated_by": payload["sub"]
    }

@app.get("/api/reports/daily-sales")
async def daily_sales(date_str: str = str(date.today()), db: Session = Depends(get_db), token: dict = Depends(validate_token)):
    """Get daily sales report for a specific date (requires authentication)"""
    try:
        logging.debug(f"Fetching daily sales for {date_str}")
        sales = db.exec(select(Order).where(Order.order_date == date_str)).all()
        total_sales = sum(order.total_price for order in sales)
        report = {
            "date": date_str,
            "total_sales": total_sales,
            "orders": [{"id": o.id, "product_id": o.product_id, "quantity": o.quantity, "total_price": o.total_price} for o in sales]
        }
        logging.debug(f"Daily sales report: {json.dumps(report, indent=2)}")
        return report
    except Exception as e:
        logging.error(f"Error fetching daily sales: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/reports/tax")
async def tax_report(date_str: str = str(date.today()), db: Session = Depends(get_db), token: dict = Depends(validate_token)):
    """Get tax report for a specific date (requires authentication)"""
    try:
        logging.debug(f"Fetching tax report for {date_str}")
        invoices = db.exec(select(Invoice).where(Invoice.invoice_date == date_str)).all()
        total_tax = sum(invoice.tax_amount for invoice in invoices)
        report = {
            "date": date_str,
            "total_tax": total_tax,
            "invoices": [{"id": i.id, "cis_invc_no": i.cis_invc_no, "total_amount": i.total_amount, "tax_amount": i.tax_amount} for i in invoices]
        }
        logging.debug(f"Tax report: {json.dumps(report, indent=2)}")
        return report
    except Exception as e:
        logging.error(f"Error fetching tax report: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Invoice Endpoints (Student B)
@app.post("/api/invoices/submit")
def submit_invoice(invoice: InvoiceSubmission, db: Session = Depends(get_db), payload: dict = Depends(validate_token)):
    """Submit invoice to ZRA tax authority (requires authentication)"""
    try:
        invoice_data = invoice.model_dump()
        logging.info(f"Original invoice_data: {json.dumps(invoice_data, indent=2)}")

        USE_POSTMAN_MOCK = os.getenv("USE_POSTMAN_MOCK", "true").lower() == "true"

        if USE_POSTMAN_MOCK:
            transformed_data = {
                "bhfId": "000",
                "deviceSerialNo": "DEVICE123",
                "invcNo": "INV-001",
                "salesDt": "2025-09-25 12:00:00",
                "invoiceType": "NORMAL",
                "transactionType": "SALE",
                "paymentType": "CASH",
                "customerTpin": "0987654321",
                "customerNm": "Test Customer",
                "totalItemCnt": 1,
                "items": [
                    {
                        "itemCd": "PROD001",
                        "itemNm": "Burger",
                        "qty": 2,
                        "prc": 10.0,
                        "taxCategory": "VAT",
                        "taxRate": 16.0,
                        "taxAmt": 3.2,
                        "totAmt": 23.2
                    }
                ],
                "taxableAmt": 20.0,
                "taxAmt": 3.2,
                "totalAmt": 23.2
            }
        else:
            transformed_data = {
                "bhfId": invoice_data["bhfId"],
                "deviceSerialNo": os.getenv("DEVICE_SERIAL_NO", "DEVICE123"),
                "invcNo": invoice_data["cisInvcNo"],
                "salesDt": invoice_data["salesDt"] + " 12:00:00",
                "invoiceType": "NORMAL" if invoice_data["salesTyCd"] == "N" else "REFUND",
                "transactionType": "SALE" if invoice_data["rcptTyCd"] == "S" else "REFUND",
                "paymentType": invoice_data["pmtTyCd"] or "CASH",
                "customerTpin": invoice_data.get("custTpin", "0987654321"),
                "customerNm": invoice_data.get("custNm", "Test Customer"),
                "totalItemCnt": invoice_data["totItemCnt"],
                "taxableAmt": invoice_data["totTaxblAmt"],
                "taxAmt": invoice_data["totTaxAmt"],
                "totalAmt": invoice_data["totAmt"],
                "items": [
                    {
                        "itemCd": f"PROD{item['itemSeq']:03d}",
                        "itemNm": item["itemNm"],
                        "qty": item["qty"],
                        "prc": item["prc"],
                        "taxCategory": "VAT" if item["taxTyCd"] == "A" else "EXEMPT",
                        "taxRate": 16.0 if item["taxTyCd"] == "A" else 0.0,
                        "taxAmt": item["taxAmt"],
                        "totAmt": item["totAmt"]
                    }
                    for item in invoice_data["itemList"]
                ]
            }

        logging.info(f"Transformed data: {json.dumps(transformed_data, indent=2)}")

        response = tax_submit_invoice(
            invoice_data=transformed_data,
            api_url=os.getenv("TAX_API_URL"),
            tpin=os.getenv("TPIN"),
            bhf_id=os.getenv("BHF_ID"),
            device_serial_no=os.getenv("DEVICE_SERIAL_NO")
        )

        db_log = InvoiceLog(cis_invc_no=invoice_data["cisInvcNo"], response=json.dumps(response))
        db.add(db_log)
        db.commit()
        return response

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to submit invoice: {str(e)}")

@app.get("/api/invoices/logs/{cis_invc_no}")
def get_invoice_log(cis_invc_no: str, db: Session = Depends(get_db), payload: dict = Depends(validate_token)):
    """Get invoice submission log by invoice number (requires authentication)"""
    log = db.exec(select(InvoiceLog).where(InvoiceLog.cis_invc_no == cis_invc_no)).first()
    if not log:
        raise HTTPException(status_code=404, detail="Log not found")
    return json.loads(log.response)