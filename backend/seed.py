from sqlalchemy.orm import Session
from models.models import SessionLocal, Product

def seed_products():
    """Insert sample products into the products table."""
    db: Session = SessionLocal()
    try:
        if db.query(Product).count() > 0:
            print("Products already exist in the database. Skipping seeding.")
            return
        products = [
            Product(name="Burger", description="Beef burger with cheese", price=5.0, stock=100),
            Product(name="Pizza", description="Margherita pizza", price=8.0, stock=50),
            Product(name="Soda", description="Cola 500ml", price=1.5, stock=200),
            Product(name="Fries", description="Crispy french fries", price=2.5, stock=150),
            Product(name="Salad", description="Fresh garden salad", price=3.0, stock=80),
            Product(name="Nshima", description="Tasty nshima", price=30.0, stock=200),
        ]
        db.add_all(products)
        db.commit()
        print("Successfully seeded 6 products into the database.")
    except Exception as e:
        print(f"Error seeding products: {str(e)}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_products()