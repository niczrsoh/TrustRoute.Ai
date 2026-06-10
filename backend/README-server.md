# SLT Defect Detection MVP

Image-first MVP for the defect detection pipeline:

1. Upload a package/shipment image.
2. Run defect inference.
3. Store the result in SQLite.
4. Read prediction history for the dashboard.

The final hardware plan is a Raspberry Pi with an HD camera. For the MVP, the Pi should send captured still images to the backend. Later, video can be added by sampling frames from the Pi camera stream and sending those frames through the same classification pipeline.

The current AI layer is a deterministic image-feature baseline so the full pipeline can run before a real image dataset exists. It exposes the same API shape a CNN/MobileNet model will use later.

## Tech Stack

- FastAPI backend
- SQLite database
- IBM Granite Vision local VLM classifier
- Pillow + NumPy fallback image inference baseline
- Pytest API tests

## Setup

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
```

## Run The API

```powershell
uvicorn app.main:app --reload
```

Open:

- API health: http://127.0.0.1:8000/health
- API docs: http://127.0.0.1:8000/docs

## AI Classifier

The intended classifier is IBM Granite Vision:

```text
ibm-granite/granite-vision-3.2-2b
```

The backend is configured to try Granite Vision first and fall back to the local image-feature baseline if VLM dependencies or model weights are unavailable.

Optional VLM setup:

```powershell
pip install -r requirements-vlm.txt
$env:SLT_CLASSIFIER_BACKEND = "granite"
$env:SLT_GRANITE_MODEL_ID = "ibm-granite/granite-vision-3.2-2b"
```

Granite Vision setup notes: `docs/granite_vision_classifier.md`.

## Generate Sample Images

```powershell
python scripts/create_sample_images.py
```

This creates demo images in `samples/`.

## Predict Defect From Image

PowerShell 7:

```powershell
$form = @{
  shipment_id = "SHIP-001"
  image = Get-Item ".\samples\crack.jpg"
}
Invoke-RestMethod -Uri "http://127.0.0.1:8000/predict" -Method Post -Form $form
```

curl:

```bash
curl -X POST "http://127.0.0.1:8000/predict" \
  -F "shipment_id=SHIP-001" \
  -F "image=@samples/crack.jpg"
```

## View History

```powershell
Invoke-RestMethod "http://127.0.0.1:8000/reports"
```

## Mobile App Integration

The mobile app is developed separately. This backend already returns JSON that the app can display after classification.

Mobile app flow:

1. Capture/select image in the mobile app.
2. Send multipart form data to `POST /predict`.
3. Display `defect_type`, `confidence`, `shipment_id`, `timestamp`, and `explanation`.
4. Optionally display `item_type` and `damage_location`.
5. Use `GET /reports` for the history screen.

For physical phone testing on the same Wi-Fi network, run:

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Then call:

```text
http://<computer-lan-ip>:8000/predict
```

Full mobile contract: `docs/mobile_api_contract.md`.

## Raspberry Pi Camera Flow

Current MVP:

```text
Raspberry Pi camera -> still image -> POST /predict -> classification result
```

Future video upgrade:

```text
Raspberry Pi video stream -> sampled frames -> POST /predict -> classification result
```

Detailed hardware/video plan: `docs/raspberry_pi_integration.md`.
Granite Vision classifier plan: `docs/granite_vision_classifier.md`.

## API Endpoints

- `GET /health` - service status
- `GET /classes` - supported defect classes
- `POST /predict` - upload an image, infer defect, store report
- `GET /reports` - list report history
- `GET /reports/{report_id}` - get one report

## Dataset Plan For Real Model

When images are available, collect them in this shape:

```text
dataset/
  train/
    crack/
    dent/
    leakage/
    normal/
  val/
    crack/
    dent/
    leakage/
    normal/
```

Minimum useful target for a hackathon MVP:

- 30 to 50 images per class if possible
- Mix lighting angles and package materials
- Include clear normal examples
- Keep labels strict: one dominant class per image

After the dataset exists, replace the baseline in `app/ai/inference.py` with a trained MobileNet/CNN loader while preserving the `predict(image_path)` interface.
