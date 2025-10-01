from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, create_engine, SQLModel, select  # Changed: Import Session from sqlmodel
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

load_dotenv()
logging.basicConfig(level=logging.INFO)

# Initialize database and create tables
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///C:/projects/pos/backend/pos.db")
engine = create_engine(DATABASE_URL, echo=True)
SQLModel.metadata.create_all(engine)

app = FastAPI(title="Mpepo POS Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    # Changed: Use SQLModel's Session instead of SQLAlchemy's Session
    with Session(engine) as db:
        yield db

class Login(BaseModel):
    username: str
    password: str

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

@app.get("/")
def root():
    return {"message": "Mpepo Kitchen POS Backend is running!"}

@app.get("/test-db")
def test_db(db: Session = Depends(get_db)):
    count = len(db.exec(select(Product)).all())
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

@app.post("/api/invoices/submit")
def submit_invoice(invoice: InvoiceSubmission, db: Session = Depends(get_db), payload: dict = Depends(validate_token)):
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
    log = db.exec(select(InvoiceLog).where(InvoiceLog.cis_invc_no == cis_invc_no)).first()
    if not log:
        raise HTTPException(status_code=404, detail="Log not found")
    return json.loads(log.response)

@app.get("/api/reports/daily-sales")
async def daily_sales(date_str: str = str(date.today()), db: Session = Depends(get_db), token: dict = Depends(validate_token)):
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