from io import BytesIO
import os
import tempfile

from fastapi.testclient import TestClient
from PIL import Image, ImageDraw

os.environ["SLT_DATA_DIR"] = tempfile.mkdtemp(prefix="slt-api-test-")
os.environ["SLT_CLASSIFIER_BACKEND"] = "baseline"

from app.main import app


def make_image(kind: str = "normal") -> BytesIO:
    image = Image.new("RGB", (220, 160), (214, 216, 212))
    draw = ImageDraw.Draw(image)
    if kind == "crack":
        draw.line([(30, 20), (70, 55), (110, 48), (170, 125)], fill=(15, 15, 15), width=5)
    buffer = BytesIO()
    image.save(buffer, format="JPEG")
    buffer.seek(0)
    return buffer


def test_health() -> None:
    with TestClient(app) as client:
        response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_predict_stores_report() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/predict",
            data={"shipment_id": "SHIP-TEST-001"},
            files={"image": ("crack.jpg", make_image("crack"), "image/jpeg")},
        )

        assert response.status_code == 200
        payload = response.json()
        assert payload["shipment_id"] == "SHIP-TEST-001"
        assert payload["defect_type"] in {"normal", "crack", "dent", "leakage"}
        assert 0 <= payload["confidence"] <= 1
        assert payload["scores"]

        reports = client.get("/reports").json()
        assert any(report["id"] == payload["id"] for report in reports)


def test_rejects_non_image_extension() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/predict",
            data={"shipment_id": "SHIP-BAD"},
            files={"image": ("bad.txt", BytesIO(b"not image"), "text/plain")},
        )

    assert response.status_code == 400
