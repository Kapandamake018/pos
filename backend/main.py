from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import create_engine, Column, Integer, String, JSON, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from tax_client import submit_invoice
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI()

ENGINE = create_engine("sqlite:///pos.db")
Base = declarative_base()
Session = sessionmaker(bind=ENGINE)

class InvoiceLog(Base):
    __tablename__ = "invoice_logs"
    id = Column(Integer, primary_key=True)
    invc_no = Column(String)
    status = Column(String)
    response = Column(JSON)
    timestamp = Column(DateTime)

Base.metadata.create_all(ENGINE)

class Item(BaseModel):
    itemCd: str | None = Field(default=None)
    itemNm: str = Field(...)
    qty: float = Field(...)
    prc: float = Field(...)
    taxblAmt: float = Field(...)
    taxAmt: float = Field(...)
    totAmt: float = Field(...)

class Invoice(BaseModel):
    tpin: str = Field(max_length=10, min_length=1)
    bhfId: str = Field(max_length=3, min_length=1)
    deviceSerialNo: str = Field(max_length=50, min_length=1)
    invcNo: str = Field(max_length=50, min_length=1)
    salesDt: str = Field(...)
    invoiceType: str = Field(...)
    transactionType: str = Field(...)
    paymentType: str = Field(...)
    customerTpin: str | None = Field(default=None, max_length=10)
    customerNm: str | None = Field(default=None, max_length=60)
    totalItemCnt: int = Field(...)
    items: list[Item] = Field(...)
    totTaxblAmt: float = Field(...)
    totTaxAmt: float = Field(...)
    totAmt: float = Field(...)

@app.post("/api/invoices/submit")
def submit_and_log(invoice: Invoice):
    api_url = os.getenv("TAX_API_URL", "https://0d4ed8e3-2aaf-4e28-81fe-47e19f5423a7.mock.pstmn.io")
    result = submit_invoice(invoice.dict(), api_url, invoice.tpin, invoice.bhfId, invoice.deviceSerialNo)
    
    status = result.get("status", "UNKNOWN")
    
    session = Session()
    log = InvoiceLog(
        invc_no=invoice.invcNo,
        status=status,
        response=result,
        timestamp=datetime.now()
    )
    session.add(log)
    session.commit()
    session.close()
    
    if status != "SUCCESS":
        raise HTTPException(400, result.get("message", "Submission failed"))
    return result

@app.get("/api/invoices/logs/{invc_no}")
def get_log(invc_no: str):
    session = Session()
    log = session.query(InvoiceLog).filter_by(invc_no=invc_no).first()
    session.close()
    if not log:
        raise HTTPException(404, "Log not found")
    return {"status": log.status, "response": log.response}