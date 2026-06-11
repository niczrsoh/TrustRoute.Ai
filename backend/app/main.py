from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path
from uuid import uuid4

from fastapi import FastAPI, File, Form, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import UnidentifiedImageError

from .ai import create_classifier
from .blockchain import build_blockchain_fields
from .config import settings
from .database import get_report, init_db, insert_report, list_reports
from .schemas import BlockchainAnchorPayload, ClassesResponse, HealthResponse, PredictionResponse, ReportResponse


ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    settings.upload_dir.mkdir(parents=True, exist_ok=True)
    yield


app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)
classifier = create_classifier()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", response_model=HealthResponse)
def health() -> dict[str, str]:
    return {"status": "ok", "service": settings.app_name}


@app.get("/classes", response_model=ClassesResponse)
def classes() -> dict[str, object]:
    return {
        "classes": [],
        "mode": "dynamic",
        "note": "Granite Vision returns a freeform visible-condition label instead of fixed defect classes.",
    }


@app.post("/predict", response_model=PredictionResponse)
async def predict(
    image: UploadFile = File(...),
    shipment_id: str = Form(default="UNASSIGNED"),
) -> dict[str, object]:
    saved_path = await save_upload(image)

    try:
        prediction = classifier.predict(saved_path)
    except UnidentifiedImageError as exc:
        saved_path.unlink(missing_ok=True)
        raise HTTPException(status_code=400, detail="Uploaded file is not a readable image") from exc

    clean_shipment_id = shipment_id.strip() or "UNASSIGNED"
    report = insert_report(
        shipment_id=clean_shipment_id,
        defect_type=prediction.defect_type,
        confidence=prediction.confidence,
        model_name=prediction.model_name,
        explanation=prediction.explanation,
        item_type=prediction.item_type,
        damage_location=prediction.damage_location,
        raw_model_output=prediction.raw_model_output,
        image_path=saved_path,
    )

    return prediction_payload(report, prediction.scores)


@app.get("/reports", response_model=list[ReportResponse])
def reports(limit: int = Query(default=50, ge=1, le=200)) -> list[dict[str, object]]:
    return [report_payload(report) for report in list_reports(limit=limit)]


@app.get("/reports/{report_id}", response_model=ReportResponse)
def report_detail(report_id: int) -> dict[str, object]:
    report = get_report(report_id)
    if report is None:
        raise HTTPException(status_code=404, detail="Report not found")
    return report_payload(report)


@app.get("/reports/{report_id}/blockchain", response_model=BlockchainAnchorPayload)
def report_blockchain_payload(report_id: int) -> dict[str, object]:
    report = get_report(report_id)
    if report is None:
        raise HTTPException(status_code=404, detail="Report not found")
    report = report_with_blockchain_fields(report)
    return {
        "report_id": report["id"],
        "contract_function": "anchorReport",
        "shipment_hash": report["shipment_hash"],
        "evidence_hash": report["evidence_hash"],
        "defect_type_chain_id": report["defect_type_chain_id"],
        "confidence_bps": report["confidence_bps"],
        "detected_at_unix": report["detected_at_unix"],
    }


async def save_upload(image: UploadFile) -> Path:
    original_name = Path(image.filename or "upload.jpg").name
    extension = Path(original_name).suffix.lower()
    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported image type. Use one of: {', '.join(sorted(ALLOWED_EXTENSIONS))}",
        )

    settings.upload_dir.mkdir(parents=True, exist_ok=True)
    destination = settings.upload_dir / f"{uuid4().hex}{extension}"

    total_bytes = 0
    with destination.open("wb") as output:
        while chunk := await image.read(1024 * 1024):
            total_bytes += len(chunk)
            if total_bytes > settings.max_upload_bytes:
                output.close()
                destination.unlink(missing_ok=True)
                raise HTTPException(status_code=413, detail="Image exceeds upload size limit")
            output.write(chunk)

    if total_bytes == 0:
        destination.unlink(missing_ok=True)
        raise HTTPException(status_code=400, detail="Uploaded image is empty")

    return destination


def prediction_payload(report: dict[str, object], scores: dict[str, float]) -> dict[str, object]:
    payload = report_payload(report)
    payload["scores"] = scores
    return payload


def report_payload(report: dict[str, object]) -> dict[str, object]:
    report = report_with_blockchain_fields(report)
    return {
        "id": report["id"],
        "shipment_id": report["shipment_id"],
        "defect_type": report["defect_type"],
        "confidence": report["confidence"],
        "model_name": report["model_name"],
        "explanation": report["explanation"],
        "item_type": report.get("item_type"),
        "damage_location": report.get("damage_location"),
        "shipment_hash": report["shipment_hash"],
        "evidence_hash": report["evidence_hash"],
        "image_hash": report["image_hash"],
        "confidence_bps": report["confidence_bps"],
        "defect_type_chain_id": report["defect_type_chain_id"],
        "detected_at_unix": report["detected_at_unix"],
        "image_path": report["image_path"],
        "timestamp": report["created_at"],
    }


def report_with_blockchain_fields(report: dict[str, object]) -> dict[str, object]:
    if report.get("shipment_hash") and report.get("evidence_hash"):
        return report

    image_path = Path(str(report["image_path"]))
    absolute_image_path = image_path if image_path.is_absolute() else settings.data_dir / image_path
    chain_fields = build_blockchain_fields(
        report,
        absolute_image_path if absolute_image_path.exists() else None,
    )
    hydrated = dict(report)
    hydrated.update(chain_fields)
    return hydrated
