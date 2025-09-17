from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models.order import Order, OrderItem
from app.models.product import Product

router = APIRouter(prefix="/reports", tags=["Reports"])

@router.get("/daily")
def daily_sales(db: Session = Depends(get_db)):
    # Group by date
    sales = (
        db.query(
            func.date(Order.created_at).label("date"),
            func.count(Order.id).label("total_orders"),
            func.sum(Order.total - Order.discount).label("total_revenue"),
            func.sum(Order.tax).label("total_tax"),
        )
        .group_by(func.date(Order.created_at))
        .all()
    )

    results = []
    for s in sales:
        # Top products sold that day
        top_products = (
            db.query(
                Product.id,
                Product.name,
                func.sum(OrderItem.quantity).label("quantity_sold"),
            )
            .join(OrderItem, OrderItem.product_id == Product.id)
            .join(Order, Order.id == OrderItem.order_id)
            .filter(func.date(Order.created_at) == s.date)
            .group_by(Product.id, Product.name)
            .order_by(func.sum(OrderItem.quantity).desc())
            .limit(5)
            .all()
        )
        results.append(
            {
                "date": s.date,
                "total_orders": s.total_orders,
                "total_revenue": float(s.total_revenue or 0),
                "total_tax": float(s.total_tax or 0),
                "top_products": [
                    {"product_id": p.id, "name": p.name, "quantity_sold": p.quantity_sold}
                    for p in top_products
                ],
            }
        )
    return results


@router.get("/monthly")
def monthly_sales(db: Session = Depends(get_db)):
    # Group by month (YYYY-MM format)
    sales = (
        db.query(
            func.strftime("%Y-%m", Order.created_at).label("month"),
            func.count(Order.id).label("total_orders"),
            func.sum(Order.total - Order.discount).label("total_revenue"),
            func.sum(Order.tax).label("total_tax"),
        )
        .group_by(func.strftime("%Y-%m", Order.created_at))
        .all()
    )

    results = []
    for s in sales:
        # Top products sold in that month
        top_products = (
            db.query(
                Product.id,
                Product.name,
                func.sum(OrderItem.quantity).label("quantity_sold"),
            )
            .join(OrderItem, OrderItem.product_id == Product.id)
            .join(Order, Order.id == OrderItem.order_id)
            .filter(func.strftime("%Y-%m", Order.created_at) == s.month)
            .group_by(Product.id, Product.name)
            .order_by(func.sum(OrderItem.quantity).desc())
            .limit(5)
            .all()
        )
        results.append(
            {
                "month": s.month,
                "total_orders": s.total_orders,
                "total_revenue": float(s.total_revenue or 0),
                "total_tax": float(s.total_tax or 0),
                "top_products": [
                    {"product_id": p.id, "name": p.name, "quantity_sold": p.quantity_sold}
                    for p in top_products
                ],
            }
        )
    return results
