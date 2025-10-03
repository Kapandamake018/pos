from sqlmodel import Session, create_engine, select
from models.models import Product, Order, Invoice, InvoiceLog
from sqlalchemy.sql import func
from dotenv import load_dotenv
import os
import json
from datetime import date, timedelta

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///C:/projects/pos/backend/pos.db")  # Fixed variable name
engine = create_engine(DATABASE_URL, echo=True)

def seed_data():
    """Insert sample data into products, orders, invoices, and invoice_logs tables."""
    with Session(engine) as db:
        try:
            # Seed products - Mpepo Kitchen menu
            if db.exec(select(func.count()).select_from(Product)).one() == 0:
                products = [
                    Product(name="Nshima with Chicken", description="Traditional Zambian meal with grilled chicken", price=45.0, stock=50),
                    Product(name="T-Bone Steak", description="Grilled T-bone steak with vegetables", price=85.0, stock=30),
                    Product(name="Fish and Chips", description="Fried tilapia with french fries", price=55.0, stock=40),
                    Product(name="Vegetable Curry", description="Mixed vegetables in curry sauce with rice", price=35.0, stock=60),
                    Product(name="Burger", description="Beef burger with cheese and fries", price=40.0, stock=45),
                    Product(name="Pizza", description="Margherita pizza", price=65.0, stock=25),
                    Product(name="Coca Cola", description="330ml bottle", price=8.0, stock=100),
                    Product(name="Fresh Juice", description="Freshly squeezed orange juice", price=15.0, stock=50),
                ]
                db.add_all(products)
                db.commit()
                print("✅ Seeded 8 products.")
            else:
                print("⚠️  Products already exist. Skipping product seeding.")

            # Seed orders - past week of sales
            if db.exec(select(func.count()).select_from(Order)).one() == 0:
                today = date.today()
                orders = []
                
                # Generate orders for past 7 days
                for i in range(7):
                    order_date = str(today - timedelta(days=i))
                    # Create 3-5 orders per day
                    orders.extend([
                        Order(product_id=1, quantity=2, total_price=90.0, order_date=order_date),
                        Order(product_id=2, quantity=1, total_price=85.0, order_date=order_date),
                        Order(product_id=3, quantity=3, total_price=165.0, order_date=order_date),
                        Order(product_id=5, quantity=2, total_price=80.0, order_date=order_date),
                    ])
                
                db.add_all(orders)
                db.commit()
                print(f"✅ Seeded {len(orders)} orders.")
            else:
                print("⚠️  Orders already exist. Skipping order seeding.")

            # Seed invoices
            if db.exec(select(func.count()).select_from(Invoice)).one() == 0:
                # Get the first 10 orders
                orders = db.exec(select(Order).limit(10)).all()
                invoices = []
                
                for idx, order in enumerate(orders, start=1):
                    invoice = Invoice(
                        order_id=order.id,
                        cis_invc_no=f"INV-{idx:03d}",
                        total_amount=order.total_price * 1.16,  # 16% VAT
                        tax_amount=order.total_price * 0.16,
                        invoice_date=order.order_date
                    )
                    invoices.append(invoice)
                
                db.add_all(invoices)
                db.commit()
                print(f"✅ Seeded {len(invoices)} invoices.")
            else:
                print("⚠️  Invoices already exist. Skipping invoice seeding.")

            # Seed invoice logs
            if db.exec(select(func.count()).select_from(InvoiceLog)).one() == 0:
                # Get the first 5 invoices
                invoices = db.exec(select(Invoice).limit(5)).all()
                logs = []
                
                for invoice in invoices:
                    log = InvoiceLog(
                        cis_invc_no=invoice.cis_invc_no,
                        response=json.dumps({
                            "resultCd": "000",
                            "resultMsg": "Success",
                            "resultDt": str(date.today()),
                            "data": {
                                "rcptNo": f"RCP-{invoice.cis_invc_no}",
                                "intrlData": "MOCK_INTERNAL_DATA",
                                "rcptSign": "MOCK_SIGNATURE",
                                "sdcDateTime": str(date.today())
                            }
                        })
                    )
                    logs.append(log)
                
                db.add_all(logs)
                db.commit()
                print(f"✅ Seeded {len(logs)} invoice logs.")
            else:
                print("⚠️  Invoice logs already exist. Skipping invoice log seeding.")

            print("\n🎉 Database seeding completed successfully!")

        except Exception as e:
            print(f"❌ Error seeding data: {str(e)}")
            db.rollback()

if __name__ == "__main__":
    seed_data()