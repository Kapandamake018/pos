"""
Mock Tax Authority Service

This is a lightweight FastAPI app that simulates a tax authority endpoint used by the POS app.

Endpoints
- POST /invoices/submit: Accepts any JSON payload and returns a mock acceptance response.
- GET  /health: Simple health check.

Run
- As module (recommended):
    python -m uvicorn backend.mock_tax:app --host 0.0.0.0 --port 8002 --reload
- Directly:
    python backend/mock_tax.py

Notes
- Requires FastAPI and Uvicorn, which are already in backend/requirements.txt.
- The handler echoes common invoice fields (like cis_invc_no and total) when present.
"""

from __future__ import annotations

from datetime import datetime, timezone
import uuid
from typing import Optional, Any, Dict

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict


app = FastAPI(title="Mock Tax Authority", version="1.0.0")

# Allow all CORS (useful when testing from different origins/tools)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class InvoicePayload(BaseModel):
    """Accept any invoice JSON structure.

    We don't validate fields strictly here because the POS app
    and tests may send varying shapes. Everything is allowed and
    accessible via model_dump().
    """

    model_config = ConfigDict(extra="allow")


class AuthorityResponse(BaseModel):
    status: str = "accepted"
    authority_reference: str
    received_at: datetime
    message: str = "Invoice accepted"
    cis_invc_no: Optional[str] = None
    amount: Optional[float] = None


@app.get("/health")
async def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.post("/invoices/submit", response_model=AuthorityResponse)
async def submit_invoice(
    payload: InvoicePayload,
    fail: bool = Query(False, description="If true, simulate a rejection with HTTP 400"),
) -> AuthorityResponse:
    """Simulate invoice submission to a tax authority.

    - If `fail=true` is provided as a query parameter, return a 400 rejection.
    - Otherwise, return a 200/201 style acceptance payload with an authority reference id.
    """
    if fail:
        # Simulate a rejection path
        raise HTTPException(status_code=400, detail="Rejected by mock authority")

    data = payload.model_dump()

    # Try to infer commonly used fields from arbitrary payloads
    inv_no: Optional[str] = None
    for key in ["cis_invc_no", "invoice_number", "invoiceNo", "invoice_no", "id", "number"]:
        if key in data and data[key] is not None:
            inv_no = str(data[key])
            break

    amount: Optional[float] = None
    for key in ["total", "total_amount", "grand_total", "amount", "totalAmount"]:
        val = data.get(key)
        if isinstance(val, (int, float)):
            amount = float(val)
            break

    return AuthorityResponse(
        authority_reference=f"AUTH-{uuid.uuid4().hex[:12].upper()}",
        received_at=datetime.now(timezone.utc),
        cis_invc_no=inv_no,
        amount=amount,
    )


if __name__ == "__main__":
    # Allow running directly with `python backend/mock_tax.py`
    import uvicorn

    uvicorn.run(
        "backend.mock_tax:app",
        host="0.0.0.0",
        port=8002,
        reload=False,
    )
