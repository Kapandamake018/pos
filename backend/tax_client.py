import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import logging

logging.basicConfig(level=logging.INFO)

def submit_invoice(invoice_data, api_url, tpin, bhf_id, device_serial):
    session = requests.Session()
    retry = Retry(total=3, backoff_factor=1, status_forcelist=[429, 500, 502, 503, 504])
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)

    headers = {
        'Content-Type': 'application/json',
        'TPIN': tpin,
        'BhfId': bhf_id,
        'DeviceSerialNo': device_serial
    }

    try:
        response = session.post(api_url, json=invoice_data, headers=headers, timeout=10)
        response.raise_for_status()
        logging.info(f"Success: {response.json()}")
        return response.json()
    except requests.HTTPError as http_err:
        logging.error(f"HTTP error: {http_err} - Response: {response.text if 'response' in locals() else ''}")
        return {"status": "ERROR", "message": str(http_err)}
    except requests.RetryError:
        logging.error("Max retries exceeded")
        return {"status": "ERROR", "message": "Network failure after 3 retries"}
    except Exception as err:
        logging.error(f"Unexpected: {err}")
        return {"status": "ERROR", "message": str(err)}