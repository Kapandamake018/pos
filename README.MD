# Smart POS with E-Invoicing - Student B Contributions

This repo contains my (Student B) contributions to the group project for CCS3142 Mobile Application Development. My focus is on e-invoicing: designing the invoice JSON schema, implementing the tax authority API client with retries/error handling, setting up the Postman mock server, adding backend endpoints for logging/storing responses, and extending the Flutter mobile app for invoice submission/display. This is ready for merging with Student A's cart/receipt and Student C's backend/DB/reporting.

The full group submission will include this in the single shared repo, with clear ownership.

## Project Context
As per the assignment, this is a mobile POS for Mpepo Kitchen, integrated with the Tax Authority's e-invoicing via REST APIs. I simulated the service with a Postman mock. The backend uses FastAPI, mobile uses Flutter, DB is SQLite.

## Setup and Deployment Guide
### Prerequisites
- Python 3.10+ for backend.
- Flutter 3.0+ for mobile (Android/iOS emulator or device).
- Postman for mock/API testing.
- Git for cloning.

### 1. Clone the Repo

### 2. Backend Setup (Python/FastAPI)
- Navigate: `cd backend`
- Create venv: `python3 -m venv venv`
- Activate: `source venv/bin/activate`
- Install deps: `pip install -r requirements.txt`
- Copy env: `cp .env.example .env` (edit TAX_API_URL if needed, e.g., your mock URL)
- Run: `uvicorn main:app --reload`
- Test: Open http://127.0.0.1:8000/docs for Swagger UI (OpenAPI spec).

Purpose: Runs the API with your endpoints (/api/invoices/submit for submission/logging, /api/invoices/logs for retrieval). Logs stored in pos.db (SQLite).

### 3. Mobile Setup (Flutter)
- Navigate: `cd mobile`
- Install deps: `flutter pub get`
- Run: `flutter run` (on emulator/device)
- Test: Navigate to InvoiceSubmissionScreen (integrate with group's cart; pass invoiceData from cart).

Purpose: Extends the app with submission button and display for confirmation/responses (success/error from backend/mock).

### 4. Mock Server Setup (Postman)
- Import postman/tax_authority_mock.json into Postman.
- Mock URL: https://0d4ed8e3-2aaf-4e28-81fe-47e19f5423a7.mock.pstmn.io/trnsSales/saveSales
- Test: Use "Success Response" and "Error Response" examples in the collection (valid/invalid bodies).

Purpose: Simulates the Tax Authority API for e-invoicing (200 success with confirmation, 400 error for invalid data).

### 5. Testing the Full Flow
- Run backend.
- In Postman, POST to http://127.0.0.1:8000/api/invoices/submit with sample body (from docs/technical_report.md or invoice_schema.json).
- Check pos.db for logs (use sqlite3 tool: sqlite3 pos.db "SELECT * FROM invoice_logs;").
- In Flutter app, submit from InvoiceSubmissionScreen—display response.
- Offline test: Stop mock, submit (retries in client should log error).

### Individual Ownership
As per the assignment, each member owns distinct tasks. My (Student B) contributions:
- backend/tax_client.py: API client with retries/error handling.
- backend/main.py: Endpoints for logging/storing responses (submit_and_log, get_log).
- backend/invoice_schema.json: Designed JSON schema for tax submissions.
- postman/tax_authority_mock.json: Mock server setup and collection.
- mobile/lib/services/invoice_service.dart: Service for submission/get log.
- mobile/lib/screens/invoice_submission_screen.dart: Screen for submission/display.
- docs/openapi.yaml: OpenAPI spec for my endpoints.
- docs/technical_report.md: My section of the report.

All commits by Student B. Ready for merging with Student A's cart and Student C's backend/DB.

### Notes
- Group merge: Add my endpoints to Student C's main.py; integrate mobile screen with Student A's cart.
- Report: See docs/technical_report.md for my part (keep group report <8 pages).
- Issues: If 422, check body matches model in main.py.
- Due: 3 October 2025 at 23:59.

For questions, contact me 
}
