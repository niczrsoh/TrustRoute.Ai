# Mobile API Contract

This backend is ready for a separate mobile app to call after capturing or selecting an image.

## Base URL

Local machine:

```text
http://127.0.0.1:8000
```

Phone on the same Wi-Fi network:

```text
http://<computer-lan-ip>:8000
```

When testing from a physical phone, do not use `127.0.0.1`; that points to the phone itself. Use the server computer's LAN IP address.

Run the API so other devices can reach it:

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Main Mobile Flow

1. Mobile app captures or selects a package image.
2. Mobile app sends the image to `POST /predict` as multipart form data.
3. Backend classifies the image and stores the report.
4. Backend returns JSON with defect label, confidence, score breakdown, and timestamp.
5. Mobile app displays the result to the user.

## POST /predict

Upload an image for classification.

### Request

Content type:

```text
multipart/form-data
```

Fields:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `image` | file | Yes | Accepted extensions: `.jpg`, `.jpeg`, `.png`, `.bmp`, `.webp` |
| `shipment_id` | string | No | Defaults to `UNASSIGNED` if omitted or empty |

Maximum image size:

```text
10 MB
```

### Example Response

```json
{
  "id": 3,
  "shipment_id": "SHIP-DEMO-001",
  "defect_type": "crack",
  "confidence": 0.712,
  "scores": {
    "normal": 0.5113,
    "crack": 0.362,
    "dent": 0.1967,
    "leakage": 0.1153
  },
  "model_name": "ibm-granite/granite-vision-3.2-2b",
  "explanation": "Dark high-contrast edge patterns were strongest in the image.",
  "item_type": "cardboard parcel",
  "damage_location": "front-left corner",
  "image_path": "uploads/6f3d9f1a2a5f4f24a7f19b1c36f574a9.jpg",
  "timestamp": "2026-06-10T05:17:30.038162+00:00"
}
```

### Mobile UI Mapping

| API Field | Suggested Mobile Display |
| --- | --- |
| `defect_type` | Main result label: `Normal`, `Crack`, `Dent`, or `Leakage` |
| `confidence` | Confidence percentage, for example `71.2%` |
| `shipment_id` | Shipment/report reference |
| `timestamp` | Inspection time |
| `explanation` | Short supporting message |
| `item_type` | Optional item description detected by the VLM |
| `damage_location` | Optional visible location of the defect |
| `scores` | Optional debug/details view |

## GET /reports

Returns the latest saved reports for a history screen.

Query parameters:

| Parameter | Type | Default | Notes |
| --- | --- | --- | --- |
| `limit` | integer | `50` | Minimum `1`, maximum `200` |

Example:

```text
GET /reports?limit=20
```

## GET /reports/{report_id}

Returns one saved report by ID.

## GET /classes

Returns supported labels:

```json
{
  "classes": ["normal", "crack", "dent", "leakage"]
}
```

## Error Cases

| Status | Meaning | Mobile Handling |
| --- | --- | --- |
| `400` | Unsupported file type, empty file, or unreadable image | Ask user to retake/select another image |
| `413` | Image exceeds size limit | Compress image or lower camera resolution |
| `422` | Missing required `image` field | Fix request construction |
| `500` | Unexpected backend error | Show retry message and log details |

## Example Mobile Pseudocode

```text
form = new multipart form
form.addFile("image", capturedImage)
form.addText("shipment_id", shipmentId)

response = POST baseUrl + "/predict" with form

if response.ok:
    show result.defect_type
    show result.confidence * 100
else:
    show upload/classification error
```

## Demo Notes

For a smooth demo, the mobile app can start with still-image upload only. Video can be added later by extracting frames on the Raspberry Pi or mobile device and sending selected frames to the same `/predict` endpoint.
