import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import logging
from dotenv import load_dotenv
import os

load_dotenv()
logging.basicConfig(level=logging.INFO)

def submit_invoice(invoice_data, api_url, tpin, bhf_id, device_serial_no):
    session = requests.Session()
    retry = Retry(total=3, backoff_factor=1, status_forcelist=[429, 500, 502, 503, 504])
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)

    headers = {
        'Content-Type': 'application/json',
        'TPIN': tpin,
        'BhfId': bhf_id,
        'DeviceSerialNo': device_serial_no
    }

    full_url = api_url + '/trnsSales/saveSales'
    try:
        response = session.post(full_url, json=invoice_data, headers=headers, timeout=10)
        response.raise_for_status()
        logging.info(f"Success: {response.json()}")
        return response.json()
    except requests.exceptions.HTTPError as errh:
        logging.error(f"HTTP Error: {errh}")
        return {"status": "ERROR", "message": str(errh)}
    except requests.exceptions.ConnectionError as errc:
        logging.error(f"Connection Error: {errc}")
        return {"status": "ERROR", "message": str(errc)}
    except requests.exceptions.Timeout as errt:
        logging.error(f"Timeout Error: {errt}")
        return {"status": "ERROR", "message": str(errt)}
    except requests.exceptions.RequestException as err:
        logging.error(f"Request Error: {err}")
        return {"status": "ERROR", "message": str(err)}
