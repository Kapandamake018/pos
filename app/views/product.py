from pydantic import BaseModel

# Base structure (shared)
class ProductBase(BaseModel):
    name: str
    price: float
    stock: int

# For creating a new product
class ProductCreate(ProductBase):
    pass

# For responses (includes ID)
class ProductResponse(ProductBase):
    id: int

    class Config:
        from_attributes = True   # Tells Pydantic to work with SQLAlchemy objects
