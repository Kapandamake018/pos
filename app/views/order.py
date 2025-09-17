from pydantic import BaseModel
from typing import List
from datetime import datetime

# Request model for items
class OrderItemCreate(BaseModel):
    product_id: int
    quantity: int
    price: float


# Response model for items
class OrderItemResponse(BaseModel):
    product_id: int
    quantity: int
    price: float

    class Config:
        from_attributes = True  # for Pydantic v2


# Request model for order
class OrderCreate(BaseModel):
    total: float
    tax: float
    discount: float
    items: List[OrderItemCreate]


# Response model for order
class OrderResponse(BaseModel):
    id: int
    total: float
    tax: float
    discount: float
    created_at: datetime
    items: List[OrderItemResponse]

    class Config:
        from_attributes = True  # for Pydantic v2
