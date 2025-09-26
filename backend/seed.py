from sqlmodel import Session, create_engine, select
from models.models import Product, Order, Invoice
from sqlalchemy.sql import func
from dotenv import load_dotenv
import os

load_dotenv()
DATABASE_URL = os.getenv("DB_URL", "sqlite:///C:/projects/pos/backend/pos.db")
engine = create_engine(DATABASE_URL, echo=True)

def seed_data():
    """Insert sample data into products, orders, and invoices tables."""
    with Session(engine) as db:
        try:
            # Seed products
            if db.exec(select(func.count()).select_from(Product)).one() == 0:
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
            if db.exec(select(func.count()).select_from(Order)).one() == 0:
                orders = [
                    Order(product_id=1, quantity=2, total_price=10.0, order_date="2025-09-24"),
                    Order(product_id=2, quantity=1, total_price=8.0, order_date="2025-09-24"),
                    Order(product_id=3, quantity=5, total_price=7.5, order_date="2025-09-23"),
                    Order(product_id=6, quantity=3, total_price=90.0, order_date="2025-09-23"),  # Nshima order
                ]
                db.add_all(orders)
                db.commit()
                print("Seeded 4 orders.")
            else:
                print("Orders already exist. Skipping order seeding.")

            # Seed invoices
            if db.exec(select(func.count()).select_from(Invoice)).one() == 0:
                invoices = [
                    Invoice(order_id=1, cis_invc_no="INV123", total_amount=10.0, tax_amount=1.0, invoice_date="2025-09-24"),
                    Invoice(order_id=2, cis_invc_no="INV-002", total_amount=8.0, tax_amount=0.8, invoice_date="2025-09-24"),
                    Invoice(order_id=3, cis_invc_no="INV-003", total_amount=7.5, tax_amount=0.75, invoice_date="2025-09-23"),
                    Invoice(order_id=4, cis_invc_no="INV-004", total_amount=90.0, tax_amount=9.0, invoice_date="2025-09-23"),
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