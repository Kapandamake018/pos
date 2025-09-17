import requests
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.order import Order

router = APIRouter(prefix="/invoices", tags=["Invoices"])

# Replace with your actual Postman Mock Server URL
MOCK_API_URL = "https://03a97b42-21ba-4e38-a3d2-d3e8372e2189.mock.pstmn.io/invoices"

@router.post("/{order_id}")
def submit_invoice(order_id: int, db: Session = Depends(get_db)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    # Build invoice payload
    invoice_payload = {
        "invoice_id": f"INV-{order.id}",
        "order_id": order.id,
        "total": order.total,
        "tax": order.tax,
        "discount": order.discount,
        "items": [
            {"product_id": item.product_id, "quantity": item.quantity, "price": item.price}
            for item in order.items
        ]
    }

    # Send to Tax Authority Mock Server
    response = requests.post(MOCK_API_URL, json=invoice_payload)

    if response.status_code == 200:
        try:
            return {
                "message": "Invoice submitted successfully",
                "invoice_payload": invoice_payload,
                "authority_response": response.json()
            }
        except Exception:
            return {
                "message": "Invoice submitted successfully",
                "invoice_payload": invoice_payload,
                "authority_response": response.text  # fallback if not JSON
            }
    else:
        return {"error": "Failed to submit invoice", "status_code": response.status_code}
