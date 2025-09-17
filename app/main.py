from fastapi import FastAPI
from app.database import Base, engine
from app.models import product
from app.controllers import product as product_controller
from app.controllers import order as order_controller
from app.controllers import invoice as invoice_controller
from app.controllers import report as report_controller
# Create DB tables (if not exist)
Base.metadata.create_all(bind=engine)

# App instance
app = FastAPI(title="Smart POS Backend (MVC)")

# Register routes
app.include_router(product_controller.router)
app.include_router(order_controller.router)

app.include_router(invoice_controller.router)

app.include_router(report_controller.router)