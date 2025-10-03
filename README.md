# Mpepo Kitchen POS — Run Guide

Flutter mobile app + FastAPI backend + SQLite. This guide shows how to run everything locally on Windows using PowerShell.

## Stack Overview
- Mobile: Flutter (Provider, http, sqflite, connectivity_plus)
- Backend: FastAPI, SQLModel/SQLAlchemy, SQLite
- Mock Tax Authority: FastAPI service used for local invoice submission tests

## Quick Start (Windows PowerShell)

### 1) Backend API (port 8001)
```powershell
# (Optional) Create venv if you don't have one
python -m venv .venv

# Activate venv
./.venv/Scripts/Activate.ps1

# Install dependencies
python -m pip install -r backend/requirements.txt

# Start API
python -m uvicorn backend.app:app --host 127.0.0.1 --port 8001 --reload
```

Optional: seed the database
```powershell
python backend/seed.py
```

### 2) Mock Tax Authority (port 8002)
```powershell
python -m uvicorn backend.mock_tax:app --host 127.0.0.1 --port 8002 --reload
```

Health check: http://127.0.0.1:8002/health

### 3) Run the Flutter app
- For Android Emulator (defaults already point to 10.0.2.2):
```powershell
flutter run
```

- To be explicit (Android Emulator):
```powershell
flutter run --dart-define=BASE_URL=http://10.0.2.2:8001 --dart-define=TAX_BASE_URL=http://10.0.2.2:8002
```

- For Windows desktop (or iOS on macOS), use 127.0.0.1:
```powershell
flutter run --dart-define=BASE_URL=http://127.0.0.1:8001 --dart-define=TAX_BASE_URL=http://127.0.0.1:8002
```

Config source: `lib/config/api_config.dart`

### 4) Verify the flow
1. Login in the app (backend must be running on 8001)
2. Fetch products, add to cart, Checkout
3. Open the Receipt screen:
	 - Totals are shown immediately
	 - “Tax Authority” section updates with status/message and also shows authority reference and received timestamp from the mock
4. Invoice response is logged to backend; you can fetch logs with Postman

## Postman Collection
- Import `backend/postman_collection.json`
- Run the Login request first (it auto-saves `access_token` to collection variables)
- Use Invoices group to Log/Get invoice responses
- Base URL points to `http://127.0.0.1:8001`; TAX_BASE_URL defaults to `http://127.0.0.1:8002`

## Troubleshooting
- Login “buffering” or failing:
	- Ensure backend is running on port 8001 and `BASE_URL` matches your platform (10.0.2.2 for Android emulator, 127.0.0.1 for desktop)
- Receipt stuck on “Submitting to tax authority…”:
	- Ensure mock tax server is running on 8002 and `TAX_BASE_URL` matches your platform
- Physical device (not emulator):
	- Use your PC’s LAN IP for `BASE_URL` and `TAX_BASE_URL` instead of 127.0.0.1/10.0.2.2
- Ports in use:
	- Change `--port` values and pass updated dart-define URLs if 8001/8002 are occupied

## Project Paths
- Mobile app: `lib/`
- Backend API: `backend/app.py`
- Mock Tax Authority: `backend/mock_tax.py`
- Postman collection: `backend/postman_collection.json`

## Notes
- Dependencies for backend are pinned in `backend/requirements.txt`
- SQLite DB file: `backend/pos.db` (generated/seeded locally)
