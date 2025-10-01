# Mpepo Kitchen POS Backend (Student C)

## Overview
Developed the Python backend for the Mpepo Kitchen POS system using FastAPI, SQLModel, and SQLAlchemy. Implemented authentication, invoice submission, and reporting endpoints, with a seeded database for testing.

## Achievements
- Built FastAPI server with `/login`, `/api/invoices/submit`, `/api/invoices/logs/{cis_invc_no}`, `/reports/sales`, `/api/reports/daily-sales`, and `/api/reports/tax` endpoints.
- Fixed deprecated `session.query()` warning in `seed.py`.
- Seeded `pos.db` with 6 products, 4 orders, and 4 invoices.
- Resolved empty `invoice_logs` issue after database deletion.
- Added debug logging and duplicate `cis_invc_no` checks in `app.py`.
- Fixed Pylance warnings for `date` and `select` in `app.py`.
- Fixed `/api/reports/daily-sales` and `/api/reports/tax` to use `db.query` instead of `db.exec`.
- Updated Student B's Postman collection (`Tax Authority Mock`) with `/login`, `/api/invoices/logs/{cis_invc_no}`, `/reports/sales`, `/api/reports/daily-sales`, and `/api/reports/tax`, with JWT authentication.

## Database Schema
- `products`: Stores menu items (id, name, description, price, stock).
- `orders`: Stores customer orders (id, product_id, quantity, total_price, order_date).
- `invoices`: Stores invoice details (id, order_id, cis_invc_no, total_amount, tax_amount, invoice_date).
- `invoice_logs`: Stores tax API responses (id, cis_invc_no, response).

## Endpoints
- `POST /login`: Authenticates users (username: "admin", password: "password").
- `POST /api/invoices/submit`: Submits invoices to tax API and logs responses.
- `GET /api/invoices/logs/{cis_invc_no}`: Retrieves invoice logs.
- `GET /reports/sales`: Returns overall sales and tax summary.
- `GET /api/reports/daily-sales?date_str=YYYY-MM-DD`: Returns daily sales summary.
- `GET /api/reports/tax?date_str=YYYY-MM-DD`: Returns daily tax summary.

## How to Run
1. Activate virtual environment: `.\venv\Scripts\Activate.ps1`
2. Start server: `uvicorn app:app --reload --host 127.0.0.1 --port 8000 --log-level debug`
3. Seed database: `python seed.py`
4. Test endpoints using Postman collection: `Mpepo_POS_API.postman_collection.json`

## Postman Collection
Import `Mpepo_POS_API.postman_collection.json` for testing all backend endpoints. Updated Student B's `Tax Authority Mock` collection to include `/login`, `/api/invoices/logs/{cis_invc_no}`, `/reports/sales`, `/api/reports/daily-sales`, and `/api/reports/tax`, with JWT authentication. Retains Student B's mock tax API request.

## Test Results
- Seeded data: 6 products, 4 orders, 4 invoices.
- Successful `/api/invoices/submit` for INV-006, INV-007, INV-009, logged in `invoice_logs`.
- Successful `/reports/sales`, `/api/reports/daily-sales`, and `/api/reports/tax` for 2025-09-24.
- All endpoints return `200 OK`.