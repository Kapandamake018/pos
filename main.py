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
    cis_invc_no = Column(String)
    status = Column(String)
    response = Column(JSON)
    timestamp = Column(DateTime)

Base.metadata.create_all(ENGINE)

class Item(BaseModel):
    itemSeq: int = Field(...)
    itemCd: str | None = None
    itemClsCd: str | None = None
    itemNm: str = Field(...)
    bcd: str | None = None
    pkgUnitCd: str | None = None
    pkg: float | None = None
    qtyUnitCd: str | None = None
    qty: float = Field(...)
    prc: float = Field(...)
    splyAmt: float = Field(...)
    dcRt: float = 0.0
    dcAmt: float = 0.0
    zeroVatAmt: float | None = None
    taxTyCd: str = Field(...)
    taxblAmt: float = Field(...)
    taxAmt: float = Field(...)
    totAmt: float = Field(...)

class Invoice(BaseModel):
    tpin: str = Field(max_length=10)
    bhfId: str = Field(max_length=3)
    sarNo: str = Field(max_length=50)
    cisInvcNo: str = Field(max_length=50)
    orgInvcNo: int | None = None
    custTpin: str | None = None
    custNm: str | None = None
    salesTyCd: str = Field(...)
    rcptTyCd: str = Field(...)
    pmtTyCd: str | None = None
    salesSttsCd: str = Field(...)
    cfmDt: str = Field(pattern=r'^\d{14}$')
    salesDt: str = Field(pattern=r'^\d{8}$')
    stockRlsDt: str | None = None
    cnclReqDt: str = Field(pattern=r'^\d{14}$')
    cnclDt: str | None = None
    rfdDt: str | None = None
    rfdRsnCd: str | None = None
    totItemCnt: int = Field(...)
    taxblAmtA: float = Field(...)
    taxblAmtB: float | None = None
    taxblAmtC: float | None = None
    taxblAmtD: float | None = None
    taxblAmtE: float | None = None
    taxAmtA: float = Field(...)
    taxAmtB: float | None = None
    taxAmtC: float | None = None
    taxAmtD: float | None = None
    taxAmtE: float | None = None
    totTaxblAmt: float = Field(...)
    totTaxAmt: float = Field(...)
    totAmt: float = Field(...)
    prtMsg: str | None = None
    remark: str | None = None
    regrId: str | None = None
    regrNm: str | None = None
    modrId: str | None = None
    modrNm: str | None = None
    itemList: list[Item] = Field(...)

@app.post("/api/invoices/submit")
def submit_and_log(invoice: Invoice):
    api_url = os.getenv("TAX_API_URL", "https://dd0f746d-52ee-4490-b6fc-f3bee400bf4f.mock.pstmn.io")
    result = submit_invoice(invoice.dict(), api_url, invoice.tpin, invoice.bhfId, invoice.sarNo)
    
    status = "SUCCESS" if result.get("resultCd") == "0000" else "ERROR"
    
    session = Session()
    log = InvoiceLog(
        cis_invc_no=invoice.cisInvcNo,
        status=status,
        response=result,
        timestamp=datetime.now()
    )
    session.add(log)
    session.commit()
    session.close()
    
    if status != "SUCCESS":
        raise HTTPException(400, result.get("resultMsg", "Submission failed"))
    return result

@app.get("/api/invoices/logs/{cis_invc_no}")
def get_log(cis_invc_no: str):
    session = Session()
    log = session.query(InvoiceLog).filter_by(cis_invc_no=cis_invc_no).first()
    session.close()
    if not log:
        raise HTTPException(404, "Not found")
    return {"status": log.status, "response": log.response}