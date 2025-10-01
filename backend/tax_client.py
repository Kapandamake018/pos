import os
import httpx
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

TAX_API_URL = os.getenv("TAX_API_URL")
POSTMAN_API_KEY = os.getenv("POSTMAN_API_KEY")

if not TAX_API_URL or not POSTMAN_API_KEY:
    raise ValueError("❌ TAX_API_URL or POSTMAN_API_KEY is missing in .env file!")

async def submit_invoice_to_tax_authority(invoice_data: dict):
    url = f"{TAX_API_URL}/trnsSales/saveSales"
    headers = {
        "Content-Type": "application/json",
        "x-api-key": POSTMAN_API_KEY,   # ✅ Required for private mock servers
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=invoice_data, headers=headers)
        response.raise_for_status()
        return response.json()
