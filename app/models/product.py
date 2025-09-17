from sqlalchemy import Column, Integer, String, Float
from app.database import Base

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)   # Auto ID
    name = Column(String, index=True)                   # Product name
    price = Column(Float)                               # Price
    stock = Column(Integer)                             # Available quantity
