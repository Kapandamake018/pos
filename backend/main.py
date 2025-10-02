from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import sqlite3
from datetime import datetime

app = FastAPI()

# ---- DB Setup ----
conn = sqlite3.connect("invoices.db", check_same_thread=False)
cursor = conn.cursor()
cursor.execute("""
CREATE TABLE IF NOT EXISTS responses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoiceId TEXT,
    status TEXT,
    message TEXT,
    timestamp TEXT
)
""")
conn.commit()

# ---- Models ----
class Invoice(BaseModel):
    tpin: str
    bhfId: str
    deviceSerialNo: str
    invcNo: str
    salesDt: str
    invoiceType: str
    transactionType: str
    paymentType: str
    customerTpin: str
    customerNm: str
    totalItemCnt: int
    items: list
    totTaxblAmt: float
    totTaxAmt: float
    totAmt: float

# ---- Helper ----
def save_response(invoiceId, status, message):
    timestamp = datetime.utcnow().isoformat()
    cursor.execute(
        "INSERT INTO responses (invoiceId, status, message, timestamp) VALUES (?,?,?,?)",
        (invoiceId, status, message, timestamp),
    )
    conn.commit()

# ---- Endpoints ----
@app.post("/api/invoices/submit")
def submit_invoice(invoice: Invoice):
    response = {
        "status": "success",
        "message": "Invoice submitted successfully to Tax Authority.",
        "authorityReferenceId": "TA_REF_123456",
        "invoiceId": invoice.invcNo
    }
    save_response(invoice.invcNo, "success", response["message"])
    return response

@app.post("/api/invoices/fail")
def fail_invoice(invoice: Invoice):
    response = {
        "detail": {
            "status": "failed",
            "message": "Invoice rejected by Tax Authority.",
            "errorCode": "TA_ERR_400",
            "invoiceId": invoice.invcNo
        }
    }
    save_response(invoice.invcNo, "failed", response["detail"]["message"])
    raise HTTPException(status_code=400, detail=response["detail"])

@app.get("/api/invoices/responses")
def get_responses():
    cursor.execute("SELECT invoiceId, status, message, timestamp FROM responses")
    rows = cursor.fetchall()
    return [
        {"invoiceId": r[0], "status": r[1], "message": r[2], "timestamp": r[3]}
        for r in rows
    ]

@app.get("/api/invoices/responses/{invoiceId}")
def get_response(invoiceId: str):
    cursor.execute("SELECT invoiceId, status, message, timestamp FROM responses WHERE invoiceId=?", (invoiceId,))
    row = cursor.fetchone()
    if row:
        return {"invoiceId": row[0], "status": row[1], "message": row[2], "timestamp": row[3]}
    raise HTTPException(status_code=404, detail="Invoice response not found")
