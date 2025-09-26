from sqlalchemy import Column, Integer, String, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv
from sqlmodel import SQLModel, Field
from typing import Optional



load_dotenv()
DATABASE_URL = os.getenv("DB_URL")

Base = declarative_base()


from sqlmodel import SQLModel, Field
from typing import Optional

class Product(SQLModel, table=True):
    __tablename__ = "products"
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    description: Optional[str] = None
    price: float
    stock: int

class Order(SQLModel, table=True):
    __tablename__ = "orders"
    id: Optional[int] = Field(default=None, primary_key=True)
    product_id: int = Field(foreign_key="products.id")
    quantity: int
    total_price: float
    order_date: str

class Invoice(SQLModel, table=True):
    __tablename__ = "invoices"
    id: Optional[int] = Field(default=None, primary_key=True)
    order_id: int = Field(foreign_key="orders.id")
    cis_invc_no: str
    total_amount: float
    tax_amount: float
    invoice_date: str

class InvoiceLog(SQLModel, table=True):
    __tablename__ = "invoice_logs"
    id: Optional[int] = Field(default=None, primary_key=True)
    cis_invc_no: str = Field(index=True)
    response: str

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
#Base.metadata.create_all(bind=engine)