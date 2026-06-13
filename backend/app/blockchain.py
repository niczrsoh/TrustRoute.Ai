from __future__ import annotations

from datetime import datetime
from pathlib import Path
from typing import Any

from eth_hash.auto import keccak


DEFECT_TYPE_TO_CHAIN_ID = {
    "normal": 0,
    "crack": 1,
    "dent": 2,
    "leakage": 3,
}
OTHER_DEFECT_CHAIN_ID = 4


def keccak_hex(value: str | bytes) -> str:
    data = value.encode("utf-8") if isinstance(value, str) else value
    return "0x" + keccak(data).hex()


def image_sha256_hex(image_path: Path) -> str:
    import hashlib

    digest = hashlib.sha256()
    with image_path.open("rb") as image_file:
        for chunk in iter(lambda: image_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return "0x" + digest.hexdigest()


def confidence_to_bps(confidence: float) -> int:
    return max(0, min(10000, int(round(confidence * 10000))))


def timestamp_to_unix(timestamp: str) -> int:
    normalized = timestamp.replace("Z", "+00:00")
    parsed = datetime.fromisoformat(normalized)
    return int(parsed.timestamp())


def build_evidence_string(
    *,
    report_id: int,
    shipment_id: str,
    defect_type: str,
    confidence_bps: int,
    timestamp: str,
    image_hash: str,
    model_name: str,
) -> str:
    return "|".join(
        [
            str(report_id),
            shipment_id,
            defect_type,
            str(confidence_bps),
            timestamp,
            image_hash,
            model_name,
        ]
    )


def build_blockchain_fields(report: dict[str, Any], absolute_image_path: Path | None = None) -> dict[str, Any]:
    confidence_bps = confidence_to_bps(float(report["confidence"]))
    image_hash = image_sha256_hex(absolute_image_path) if absolute_image_path else str(report.get("image_hash") or "")
    evidence_string = build_evidence_string(
        report_id=int(report["id"]),
        shipment_id=str(report["shipment_id"]),
        defect_type=str(report["defect_type"]),
        confidence_bps=confidence_bps,
        timestamp=str(report["created_at"]),
        image_hash=image_hash,
        model_name=str(report["model_name"]),
    )

    return {
        "shipment_hash": keccak_hex(str(report["shipment_id"])),
        "evidence_hash": keccak_hex(evidence_string),
        "image_hash": image_hash,
        "confidence_bps": confidence_bps,
        "defect_type_chain_id": DEFECT_TYPE_TO_CHAIN_ID.get(
            str(report["defect_type"]),
            OTHER_DEFECT_CHAIN_ID,
        ),
        "detected_at_unix": timestamp_to_unix(str(report["created_at"])),
        "evidence_string": evidence_string,
    }


def build_certificate_string(
    *,
    certificate_id: int,
    shipment_id: str,
    recipient_reference: str,
    condition_summary: str,
    delivered_at: str,
) -> str:
    return "|".join(
        [
            str(certificate_id),
            shipment_id,
            recipient_reference,
            condition_summary,
            delivered_at,
        ]
    )


def build_certificate_fields(certificate: dict[str, Any]) -> dict[str, Any]:
    certificate_string = build_certificate_string(
        certificate_id=int(certificate["id"]),
        shipment_id=str(certificate["shipment_id"]),
        recipient_reference=str(certificate["recipient_reference"]),
        condition_summary=str(certificate["condition_summary"]),
        delivered_at=str(certificate["delivered_at"]),
    )
    return {
        "shipment_hash": keccak_hex(str(certificate["shipment_id"])),
        "certificate_hash": keccak_hex(certificate_string),
        "recipient_hash": keccak_hex(str(certificate["recipient_reference"])),
        "condition_hash": keccak_hex(str(certificate["condition_summary"])),
        "delivered_at_unix": timestamp_to_unix(str(certificate["delivered_at"])),
        "certificate_string": certificate_string,
    }
