from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.order import Order, OrderItem
from app.views.order import OrderCreate, OrderResponse, OrderItemResponse


router = APIRouter(prefix="/orders", tags=["Orders"])

@router.post("/", response_model=OrderResponse)
def create_order(order: OrderCreate, db: Session = Depends(get_db)):
    # 1. Create the order
    new_order = Order(
        total=order.total,
        tax=order.tax,
        discount=order.discount
    )
    db.add(new_order)
    db.commit()
    db.refresh(new_order)

    # 2. Add items to the order
    for item in order.items:
        db_item = OrderItem(
            order_id=new_order.id,
            product_id=item.product_id,
            quantity=item.quantity,
            price=item.price
        )
        db.add(db_item)

    db.commit()
    db.refresh(new_order)

    # 3. Return structured response
    return OrderResponse(
        id=new_order.id,
        total=new_order.total,
        tax=new_order.tax,
        discount=new_order.discount,
        created_at=new_order.created_at,
        items=[
            OrderItemResponse(
                product_id=i.product_id,
                quantity=i.quantity,
                price=i.price
            )
            for i in new_order.items
        ]
    )



@router.get("/{order_id}", response_model=OrderResponse)
def get_order(order_id: int, db: Session = Depends(get_db)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order

