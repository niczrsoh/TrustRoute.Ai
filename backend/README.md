# TrustRoute.Ai Backend

FastAPI backend for the TrustRoute.Ai delivery defect detection MVP.

The backend receives images of delivered goods, runs AI classification with IBM Granite Vision, stores reports in SQLite, returns results to the mobile app, and can submit compact proof data to the Sepolia smart contract.

## What It Does

- Accepts still-image uploads through `POST /predict`.
- Uses IBM Granite Vision by default for freeform visible-condition classification.
- Falls back to the local image-feature baseline when fallback is enabled and Granite cannot run.
- Stores defect reports in SQLite under `backend/data/`.
- Builds privacy-preserving hashes for shipment and evidence data.
- Optionally anchors defect reports to `DefectReportRegistry.anchorReport`.
- Creates delivery certificates for recipient handoff.
- Optionally issues delivery certificates on-chain through `issueDeliveryCertificate`.

The current MVP is image-first. Raspberry Pi video support should be added later by sampling frames and sending selected still images to the same `/predict` endpoint.

## Requirements

- Python 3.11 recommended
- Sepolia ETH on the backend wallet if blockchain writes are enabled
- A Sepolia RPC URL
- Optional but recommended: enough memory/disk for local Granite Vision model loading

## Setup

From this folder:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
```

For IBM Granite Vision, install the VLM dependencies too:

```powershell
pip install torch==2.6.0 --index-url https://download.pytorch.org/whl/cpu
pip install -r requirements-vlm.txt
```

## Environment Variables

The backend reads variables from the shell and also loads `backend/.env` when present.

Minimum Granite setup:

```powershell
$env:SLT_CLASSIFIER_BACKEND = "granite"
$env:SLT_GRANITE_MODEL_ID = "ibm-granite/granite-vision-3.2-2b"
```

Optional Granite settings:

```powershell
$env:SLT_CLASSIFIER_FALLBACK = "true"
$env:SLT_GRANITE_MAX_NEW_TOKENS = "8"
$env:SLT_GRANITE_TRUST_REMOTE_CODE = "false"
```

Blockchain setup:

```powershell
$env:ETH_RPC_URL = "https://ethereum-sepolia-rpc.publicnode.com"
$env:ETH_PRIVATE_KEY = "YOUR_BACKEND_WALLET_PRIVATE_KEY"
$env:ETH_CHAIN_ID = "11155111"
$env:DEFECT_REGISTRY_ADDRESS = "0xA93F08342849139c96e6ac26C757259968edcF14"
$env:SLT_AUTO_ANCHOR_REPORTS = "true"
```

Storage and upload settings:

```powershell
$env:SLT_DATA_DIR = "C:\path\to\backend\data"
$env:SLT_MAX_UPLOAD_BYTES = "10485760"
```

Important:

- Do not commit `.env` or private keys.
- The backend wallet must be authorized in the contract with `setReporter(walletAddress, true)`.
- The backend wallet needs Sepolia ETH for gas.
- Sepolia chain ID is `11155111`.
- If blockchain variables are missing, prediction still works and the report will show a blockchain error or `not_configured` status.

## Run The Server

Local development:

```powershell
uvicorn app.main:app --reload
```

LAN/mobile testing:

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Useful URLs:

- Health check: `http://127.0.0.1:8000/health`
- Swagger docs: `http://127.0.0.1:8000/docs`
- Mobile/LAN base URL: `http://<server-device-lan-ip>:8000`

## API Endpoints

### Health

```text
GET /health
```

Returns backend status and service name.

### Compatibility Classes

```text
GET /classes
```

Returns dynamic-classification metadata. Granite Vision is not limited to a fixed defect class list, but the endpoint remains for mobile compatibility.

### Predict Defect

```text
POST /predict
```

Multipart form fields:

- `shipment_id`: shipment or delivery reference
- `image`: uploaded image file

PowerShell example:

```powershell
$form = @{
  shipment_id = "SHIP-TEST-001"
  image = Get-Item "C:\path\to\image.jpg"
}

Invoke-RestMethod `
  -Uri "http://127.0.0.1:8000/predict" `
  -Method Post `
  -Form $form
```

The response includes:

- `defect_type`
- `confidence`
- `explanation`
- `item_type`
- `damage_location`
- `shipment_hash`
- `evidence_hash`
- `image_hash`
- `defect_type_chain_id`
- `blockchain_status`
- `blockchain_tx_hash`

### Reports

```text
GET /reports?limit=50
GET /reports/{report_id}
```

Used by the mobile dashboard history.

### Report Blockchain Payload

```text
GET /reports/{report_id}/blockchain
```

Returns the compact payload that will be submitted to the smart contract.

### Submit Or Retry Report Anchor

```text
POST /reports/{report_id}/blockchain/anchor
```

Calls `DefectReportRegistry.anchorReport` with:

- `shipmentHash`
- `evidenceHash`
- `defectType`
- `confidenceBps`
- `detectedAt`

### Create Delivery Certificate

```text
POST /delivery-certificates
```

JSON body:

```json
{
  "shipment_id": "SHIP-TEST-001",
  "recipient_reference": "recipient-or-proof-reference",
  "condition_summary": "received with visible parcel damage",
  "delivered_at": "2026-06-14T10:30:00Z"
}
```

`delivered_at` is optional. If omitted, the backend uses the current server time.

### Delivery Certificate Detail

```text
GET /delivery-certificates/{certificate_id}
```

### Delivery Certificate Blockchain Payload

```text
GET /delivery-certificates/{certificate_id}/blockchain
```

### Issue Delivery Certificate On-Chain

```text
POST /delivery-certificates/{certificate_id}/blockchain/issue
```

Calls `DefectReportRegistry.issueDeliveryCertificate` with:

- `shipmentHash`
- `certificateHash`
- `recipientHash`
- `conditionHash`
- `deliveredAt`

## Defect Type Mapping For Smart Contract

Granite Vision can return freeform labels. For the smart contract enum, the backend maps known labels to compact IDs and maps unknown/freeform labels to `Other`.

```text
0 = Normal
1 = Crack
2 = Dent
3 = Leakage
4 = Other
```

This keeps the smart contract compact while preserving the full AI label and explanation in SQLite.

## Mobile App Integration

The mobile app should:

1. Send multipart image uploads to `POST /predict`.
2. Display the prediction response fields.
3. Use `GET /reports` for dashboard history.
4. Show `blockchain_status` and `blockchain_tx_hash` when available.
5. Create delivery certificates when recipient handoff is confirmed.

Full response examples are documented in `docs/mobile_api_contract.md`.

## Raspberry Pi Integration

Current flow:

```text
Raspberry Pi HD camera -> captured image -> POST /predict -> Granite Vision result -> report history
```

Future flow:

```text
Raspberry Pi HD camera -> video stream -> sampled frames -> POST /predict -> report history
```

See `docs/raspberry_pi_integration.md`.

## Tests

Run backend tests:

```powershell
.\.venv\Scripts\Activate.ps1
python -m pytest -q
```

## Related Docs

- Server runbook: `README-server.md`
- Mobile API contract: `docs/mobile_api_contract.md`
- Granite Vision notes: `docs/granite_vision_classifier.md`
- Raspberry Pi notes: `docs/raspberry_pi_integration.md`
- Smart contract: `..\blockchain\contracts\DefectReportRegistry.sol`
