from __future__ import annotations

from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

from fastapi import FastAPI, File, Form, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import UnidentifiedImageError

from .ai import create_classifier
from .blockchain import build_blockchain_fields
from .blockchain_client import BlockchainNotConfigured, send_anchor_report, send_delivery_certificate
from .config import settings
from .database import (
    get_delivery_certificate,
    get_report,
    init_db,
    insert_delivery_certificate,
    insert_report,
    list_reports,
    update_certificate_blockchain_status,
    update_report_blockchain_status,
)
from .schemas import (
    BlockchainAnchorPayload,
    BlockchainTransactionResponse,
    ClassesResponse,
    DeliveryCertificatePayload,
    DeliveryCertificateRequest,
    DeliveryCertificateResponse,
    HealthResponse,
    PredictionResponse,
    ReportResponse,
)


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
    if settings.auto_anchor_reports:
        report = anchor_report_after_prediction(report)

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


@app.post("/reports/{report_id}/blockchain/anchor", response_model=BlockchainTransactionResponse)
def anchor_report_on_chain(report_id: int) -> dict[str, object]:
    report = get_report(report_id)
    if report is None:
        raise HTTPException(status_code=404, detail="Report not found")
    updated = anchor_report_after_prediction(report)
    payload = report_blockchain_payload(report_id)
    return {
        "status": updated.get("blockchain_status") or "not_submitted",
        "tx_hash": updated.get("blockchain_tx_hash"),
        "message": updated.get("blockchain_error"),
        "payload": payload,
    }


@app.post("/delivery-certificates", response_model=DeliveryCertificateResponse)
def create_delivery_certificate(request: DeliveryCertificateRequest) -> dict[str, object]:
    delivered_at = request.delivered_at or datetime.now(timezone.utc)
    certificate = insert_delivery_certificate(
        shipment_id=request.shipment_id.strip() or "UNASSIGNED",
        recipient_reference=request.recipient_reference.strip() or "UNKNOWN_RECIPIENT",
        condition_summary=request.condition_summary.strip() or "received",
        delivered_at=delivered_at.isoformat(),
    )
    return certificate_payload(certificate)


@app.get("/delivery-certificates/{certificate_id}", response_model=DeliveryCertificateResponse)
def delivery_certificate_detail(certificate_id: int) -> dict[str, object]:
    certificate = get_delivery_certificate(certificate_id)
    if certificate is None:
        raise HTTPException(status_code=404, detail="Delivery certificate not found")
    return certificate_payload(certificate)


@app.get("/delivery-certificates/{certificate_id}/blockchain", response_model=DeliveryCertificatePayload)
def delivery_certificate_blockchain_payload(certificate_id: int) -> dict[str, object]:
    certificate = get_delivery_certificate(certificate_id)
    if certificate is None:
        raise HTTPException(status_code=404, detail="Delivery certificate not found")
    return certificate_blockchain_payload(certificate)


@app.post("/delivery-certificates/{certificate_id}/blockchain/issue", response_model=BlockchainTransactionResponse)
def issue_delivery_certificate_on_chain(certificate_id: int) -> dict[str, object]:
    payload = delivery_certificate_blockchain_payload(certificate_id)
    try:
        tx_hash = send_delivery_certificate(payload)
    except BlockchainNotConfigured as exc:
        return {
            "status": "not_configured",
            "tx_hash": None,
            "message": str(exc),
            "payload": payload,
        }
    except Exception as exc:
        update_certificate_blockchain_status(certificate_id, status="failed", tx_hash=None)
        return {
            "status": "failed",
            "tx_hash": None,
            "message": str(exc),
            "payload": payload,
        }

    update_certificate_blockchain_status(certificate_id, status="submitted", tx_hash=tx_hash)
    return {
        "status": "submitted",
        "tx_hash": tx_hash,
        "message": "Delivery certificate transaction submitted.",
        "payload": payload,
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
        "blockchain_status": report.get("blockchain_status") or "not_submitted",
        "blockchain_tx_hash": report.get("blockchain_tx_hash"),
        "blockchain_error": report.get("blockchain_error"),
        "image_path": report["image_path"],
        "timestamp": report["created_at"],
    }


def certificate_payload(certificate: dict[str, object]) -> dict[str, object]:
    return {
        "id": certificate["id"],
        "shipment_id": certificate["shipment_id"],
        "recipient_reference": certificate["recipient_reference"],
        "condition_summary": certificate["condition_summary"],
        "delivered_at": certificate["delivered_at"],
        "shipment_hash": certificate["shipment_hash"],
        "certificate_hash": certificate["certificate_hash"],
        "recipient_hash": certificate["recipient_hash"],
        "condition_hash": certificate["condition_hash"],
        "delivered_at_unix": certificate["delivered_at_unix"],
        "blockchain_tx_hash": certificate.get("blockchain_tx_hash"),
        "blockchain_status": certificate.get("blockchain_status") or "not_submitted",
    }


def certificate_blockchain_payload(certificate: dict[str, object]) -> dict[str, object]:
    return {
        "certificate_id": certificate["id"],
        "contract_function": "issueDeliveryCertificate",
        "shipment_hash": certificate["shipment_hash"],
        "certificate_hash": certificate["certificate_hash"],
        "recipient_hash": certificate["recipient_hash"],
        "condition_hash": certificate["condition_hash"],
        "delivered_at_unix": certificate["delivered_at_unix"],
    }


def anchor_report_after_prediction(report: dict[str, object]) -> dict[str, object]:
    report = report_with_blockchain_fields(report)
    payload = {
        "report_id": report["id"],
        "contract_function": "anchorReport",
        "shipment_hash": report["shipment_hash"],
        "evidence_hash": report["evidence_hash"],
        "defect_type_chain_id": report["defect_type_chain_id"],
        "confidence_bps": report["confidence_bps"],
        "detected_at_unix": report["detected_at_unix"],
    }
    try:
        tx_hash = send_anchor_report(payload)
    except BlockchainNotConfigured as exc:
        return update_report_blockchain_status(
            int(report["id"]),
            status="not_configured",
            error=str(exc),
        )
    except Exception as exc:
        return update_report_blockchain_status(
            int(report["id"]),
            status="failed",
            error=str(exc),
        )
    return update_report_blockchain_status(
        int(report["id"]),
        status="submitted",
        tx_hash=tx_hash,
        error=None,
    )


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
