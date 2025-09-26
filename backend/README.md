# Mpepo Kitchen POS Backend (Student C)

## Overview
Developed the Python backend for the Mpepo Kitchen POS system using FastAPI, SQLModel, and SQLite. Implemented endpoints for authentication, invoice submission, and log retrieval, with a seeded database for testing.

## Achievements
- Implemented `/login`, `/api/invoices/submit`, and `/api/invoices/logs/{cis_invc_no}` endpoints.
- Fixed deprecated `session.query()` warning in `seed.py`.
- Seeded `pos.db` with 6 products, 4 orders, and 4 invoices.
- Resolved empty `invoice_logs` issue after database deletion.
- Added debug logging and duplicate `cis_invc_no` checks in `app.py`.
- Created Postman collection for API documentation.

## Database Schema
- `products`: Stores menu items (id, name, description, price, stock).
- `orders`: Stores customer orders (id, product_id, quantity, total_price, order_date).
- `invoices`: Stores invoice details (id, order_id, cis_invc_no, total_amount, tax_amount, invoice_date).
- `invoice_logs`: Stores tax API responses (id, cis_invc_no, response).

## How to Run
1. Activate virtual environment: `.\venv\Scripts\Activate.ps1`
2. Start server: `uvicorn app:app --reload --host 127.0.0.1 --port 8000 --log-level debug`
3. Seed database: `python seed.py`
4. Test endpoints using Postman collection: `Mpepo_POS_API.postman_collection.json`

## Test Results
- Seeded data: 6 products, 4 orders, 4 invoices.
- Successful `/api/invoices/submit` for INV-006 and INV-007, logged in `invoice_logs`.
- All endpoints return `200 OK`.