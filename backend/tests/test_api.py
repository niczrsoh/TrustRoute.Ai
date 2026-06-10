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
        assert isinstance(payload["defect_type"], str)
        assert payload["defect_type"]
        assert 0 <= payload["confidence"] <= 1
        assert 0 <= payload["confidence_bps"] <= 10000
        assert payload["shipment_hash"].startswith("0x")
        assert payload["evidence_hash"].startswith("0x")
        assert payload["image_hash"].startswith("0x")
        assert payload["scores"]

        reports = client.get("/reports").json()
        assert any(report["id"] == payload["id"] for report in reports)

        blockchain_payload = client.get(f"/reports/{payload['id']}/blockchain").json()
        assert blockchain_payload["contract_function"] == "anchorReport"
        assert blockchain_payload["shipment_hash"] == payload["shipment_hash"]
        assert blockchain_payload["evidence_hash"] == payload["evidence_hash"]
        assert blockchain_payload["defect_type_chain_id"] == payload["defect_type_chain_id"]
        assert blockchain_payload["confidence_bps"] == payload["confidence_bps"]


def test_classes_are_dynamic_for_granite_labels() -> None:
    with TestClient(app) as client:
        response = client.get("/classes")

    assert response.status_code == 200
    payload = response.json()
    assert payload["classes"] == []
    assert payload["mode"] == "dynamic"


def test_rejects_non_image_extension() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/predict",
            data={"shipment_id": "SHIP-BAD"},
            files={"image": ("bad.txt", BytesIO(b"not image"), "text/plain")},
        )

    assert response.status_code == 400
