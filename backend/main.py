from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import uvicorn

app = FastAPI(title="Invoice Submission API (Mocked)")

# ✅ Item Schema
class Item(BaseModel):
    itemCd: str
    itemNm: str
    qty: int
    prc: float
    taxblAmt: float
    taxAmt: float
    totAmt: float

# ✅ Invoice Schema
class Invoice(BaseModel):
    tpin: str
    bhfId: str
    deviceSerialNo: str
    invcNo: str
    salesDt: str
    invoiceType: str
    transactionType: str
    paymentType: str
    customerTpin: str = None
    customerNm: str = None
    totalItemCnt: int
    items: List[Item]
    totTaxblAmt: float
    totTaxAmt: float
    totAmt: float

# ✅ Always succeed
@app.post("/api/invoices/submit")
async def submit_invoice(invoice: Invoice):
    return {
        "status": "success",
        "message": "Invoice submitted successfully to Tax Authority.",
        "authorityReferenceId": "TA_REF_123456",
        "invoiceId": invoice.invcNo
    }

# ❌ Always fail with HTTP 400
@app.post("/api/invoices/fail")
async def fail_invoice(invoice: Invoice):
    raise HTTPException(
        status_code=400,
        detail={
            "status": "failed",
            "message": "Invoice rejected by Tax Authority.",
            "errorCode": "TA_ERR_400",
            "invoiceId": invoice.invcNo
        }
    )

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
