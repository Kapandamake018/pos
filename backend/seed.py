from sqlalchemy.orm import Session
from models.models import SessionLocal, Product, Order, Invoice
from datetime import datetime

def seed_data():
    """Insert sample data into products, orders, and invoices tables."""
    db: Session = SessionLocal()
    try:
        # Seed products
        if db.query(Product).count() == 0:
            products = [
                Product(name="Burger", description="Beef burger with cheese", price=5.0, stock=100),
                Product(name="Pizza", description="Margherita pizza", price=8.0, stock=50),
                Product(name="Soda", description="Cola 500ml", price=1.5, stock=200),
                Product(name="Fries", description="Crispy french fries", price=2.5, stock=150),
                Product(name="Salad", description="Fresh garden salad", price=3.0, stock=80),
                Product(name="Nshima", description="Tasty Nshima", price=30.0, stock=200),
            ]
            db.add_all(products)
            db.commit()
            print("Seeded 6 products.")
        else:
            print("Products already exist. Skipping product seeding.")

        # Seed orders
        if db.query(Order).count() == 0:
            orders = [
                Order(product_id=1, quantity=2, total_price=10.0, order_date="2025-09-24"),
                Order(product_id=2, quantity=1, total_price=8.0, order_date="2025-09-24"),
                Order(product_id=3, quantity=5, total_price=7.5, order_date="2025-09-23"),
                Order(product_id=6, quantity=3, total_price=6.0, order_date="2025-09-23"),  # Coffee order
            ]
            db.add_all(orders)
            db.commit()
            print("Seeded 4 orders.")
        else:
            print("Orders already exist. Skipping order seeding.")

        # Seed invoices
        if db.query(Invoice).count() == 0:
            invoices = [
                Invoice(order_id=1, invoice_date="2025-09-24", total_amount=10.0, tax_amount=1.0),
                Invoice(order_id=2, invoice_date="2025-09-24", total_amount=8.0, tax_amount=0.8),
                Invoice(order_id=3, invoice_date="2025-09-23", total_amount=7.5, tax_amount=0.75),
                Invoice(order_id=4, invoice_date="2025-09-23", total_amount=6.0, tax_amount=0.6),
            ]
            db.add_all(invoices)
            db.commit()
            print("Seeded 4 invoices.")
        else:
            print("Invoices already exist. Skipping invoice seeding.")

    except Exception as e:
        print(f"Error seeding data: {str(e)}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_data()