# Smart POS - Student B Repo

This repo contains my (Student B) contributions to the group project. It follows the assignment for my tasks: schema design, tax client, mock, backend endpoints, Flutter extension. For group submission, merge with others.

## Setup/Deployment Guide
1. Backend: cd backend; python3 -m venv venv; source venv/bin/activate; pip install -r requirements.txt; uvicorn main:app --reload
2. Copy backend/.env.example to .env and set values.
3. Mock: Import postman/tax_authority_mock.json into Postman. URL in .env. Test with sample JSON.
4. Mobile: cd mobile; flutter pub get; flutter run (integrate screen with group's app).
5. DB: Runs SQLite pos.db; logs stored in invoice_logs table.
6. API: OpenAPI at http://localhost:8000/docs; test with Postman.

## Ownership
Student B owned all files in this repo. See technical_report.md for details.

## Notes
For full group: Backend is FastAPI, mobile is Flutter. Mock is faithful to ZRA spec. Report is my part only.
