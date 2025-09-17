from app.database import SessionLocal, engine, Base
from app.models.product import Product

# Create tables if they don't exist
Base.metadata.create_all(bind=engine)

db = SessionLocal()

# Sample products
products = [
    Product(name="Chicken Curry", price=50.0, stock=20),
    Product(name="Beef Stew", price=65.0, stock=15),
    Product(name="Veggie Wrap", price=30.0, stock=25),
]

# Add only if DB is empty
if not db.query(Product).first():
    db.add_all(products)
    db.commit()
    print("✅ Seeded database with sample products")
else:
    print("⚠️ Database already has products")

db.close()
