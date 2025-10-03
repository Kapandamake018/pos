# Mpepo Kitchen POS Backend

## Overview
FastAPI + SQLModel + SQLite backend for the POS app. Includes authentication, products/orders, reporting, and invoice logging of tax authority responses. A lightweight mock tax authority is included for local testing.

## Key Endpoints
- `POST /login`
- `GET /api/products`, `POST /api/orders`, `GET /api/reports/sales`
- `POST /api/invoices/log` — store authority response for an invoice
- `GET /api/invoices/logs` — list/search stored responses

## Database Schema (SQLite)
- `products`: menu items
- `orders`: placed orders
- `invoices`: invoice summary rows
- `invoice_logs`: raw authority response payloads per `cis_invc_no`

## Setup and Run (Windows PowerShell)
1) Create/activate venv and install deps
	- Activate: `./.venv/Scripts/Activate.ps1`
	- Install: `python -m pip install -r backend/requirements.txt`

2) Start API server (port 8001)
	- `python -m uvicorn backend.app:app --host 127.0.0.1 --port 8001 --reload`

3) Seed database (optional)
	- `python backend/seed.py`

4) Postman collection
	- Import `backend/postman_collection.json`

## Mock Tax Authority (for local testing)
A small service that simulates a tax authority.

- File: `backend/mock_tax.py`
- Start on port 8002:
  - `python -m uvicorn backend.mock_tax:app --host 127.0.0.1 --port 8002 --reload`
- Health check: `GET http://127.0.0.1:8002/health`
- Submit invoice: `POST http://127.0.0.1:8002/invoices/submit`
  - Optional rejection: add `?fail=true` to simulate a 400 error

### Configure the mobile app
Run Flutter with:
- `--dart-define=BASE_URL=http://127.0.0.1:8001`
- `--dart-define=TAX_BASE_URL=http://127.0.0.1:8002`

On Android emulator, use `http://10.0.2.2:<port>` instead of `127.0.0.1`.

## Notes
- Dependencies are pinned in `backend/requirements.txt`.
- Logs are written under `backend/logs/` when enabled.