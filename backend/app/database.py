from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
import sqlite3
from typing import Any, Iterator

from .blockchain import build_blockchain_fields, build_certificate_fields
from .config import settings


SCHEMA = """
CREATE TABLE IF NOT EXISTS defect_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    shipment_id TEXT NOT NULL,
    defect_type TEXT NOT NULL,
    confidence REAL NOT NULL,
    model_name TEXT NOT NULL,
    explanation TEXT NOT NULL,
    item_type TEXT,
    damage_location TEXT,
    raw_model_output TEXT,
    shipment_hash TEXT,
    evidence_hash TEXT,
    image_hash TEXT,
    confidence_bps INTEGER,
    defect_type_chain_id INTEGER,
    detected_at_unix INTEGER,
    blockchain_tx_hash TEXT,
    blockchain_status TEXT NOT NULL DEFAULT 'not_submitted',
    blockchain_error TEXT,
    image_path TEXT NOT NULL,
    created_at TEXT NOT NULL
);
"""

CERTIFICATE_SCHEMA = """
CREATE TABLE IF NOT EXISTS delivery_certificates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    shipment_id TEXT NOT NULL,
    recipient_reference TEXT NOT NULL,
    condition_summary TEXT NOT NULL,
    delivered_at TEXT NOT NULL,
    shipment_hash TEXT,
    certificate_hash TEXT,
    recipient_hash TEXT,
    condition_hash TEXT,
    delivered_at_unix INTEGER,
    blockchain_tx_hash TEXT,
    blockchain_status TEXT NOT NULL DEFAULT 'not_submitted',
    created_at TEXT NOT NULL
);
"""

OPTIONAL_COLUMNS = {
    "item_type": "TEXT",
    "damage_location": "TEXT",
    "raw_model_output": "TEXT",
    "shipment_hash": "TEXT",
    "evidence_hash": "TEXT",
    "image_hash": "TEXT",
    "confidence_bps": "INTEGER",
    "defect_type_chain_id": "INTEGER",
    "detected_at_unix": "INTEGER",
    "blockchain_tx_hash": "TEXT",
    "blockchain_status": "TEXT NOT NULL DEFAULT 'not_submitted'",
    "blockchain_error": "TEXT",
}


@contextmanager
def get_connection() -> Iterator[sqlite3.Connection]:
    settings.data_dir.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(settings.db_path)
    connection.row_factory = sqlite3.Row
    try:
        yield connection
        connection.commit()
    finally:
        connection.close()


def init_db() -> None:
    with get_connection() as connection:
        connection.execute(SCHEMA)
        connection.execute(CERTIFICATE_SCHEMA)
        existing_columns = {
            row["name"]
            for row in connection.execute("PRAGMA table_info(defect_reports)").fetchall()
        }
        for column_name, column_type in OPTIONAL_COLUMNS.items():
            if column_name not in existing_columns:
                connection.execute(f"ALTER TABLE defect_reports ADD COLUMN {column_name} {column_type}")


def row_to_dict(row: sqlite3.Row | None) -> dict[str, Any] | None:
    if row is None:
        return None
    return dict(row)


def normalize_image_path(image_path: Path) -> str:
    try:
        return image_path.relative_to(settings.data_dir).as_posix()
    except ValueError:
        return image_path.as_posix()


def insert_report(
    *,
    shipment_id: str,
    defect_type: str,
    confidence: float,
    model_name: str,
    explanation: str,
    item_type: str | None = None,
    damage_location: str | None = None,
    raw_model_output: str | None = None,
    image_path: Path,
) -> dict[str, Any]:
    created_at = datetime.now(timezone.utc).isoformat()
    normalized_image_path = normalize_image_path(image_path)
    report_for_hashing = {
        "id": 0,
        "shipment_id": shipment_id,
        "defect_type": defect_type,
        "confidence": confidence,
        "model_name": model_name,
        "image_hash": None,
        "created_at": created_at,
    }
    initial_chain_fields = build_blockchain_fields(report_for_hashing, image_path)

    with get_connection() as connection:
        cursor = connection.execute(
            """
            INSERT INTO defect_reports (
                shipment_id,
                defect_type,
                confidence,
                model_name,
                explanation,
                item_type,
                damage_location,
                raw_model_output,
                shipment_hash,
                evidence_hash,
                image_hash,
                confidence_bps,
                defect_type_chain_id,
                detected_at_unix,
                image_path,
                created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                shipment_id,
                defect_type,
                confidence,
                model_name,
                explanation,
                item_type,
                damage_location,
                raw_model_output,
                initial_chain_fields["shipment_hash"],
                initial_chain_fields["evidence_hash"],
                initial_chain_fields["image_hash"],
                initial_chain_fields["confidence_bps"],
                initial_chain_fields["defect_type_chain_id"],
                initial_chain_fields["detected_at_unix"],
                normalized_image_path,
                created_at,
            ),
        )
        report_id = int(cursor.lastrowid)
        row = connection.execute(
            "SELECT * FROM defect_reports WHERE id = ?",
            (report_id,),
        ).fetchone()
        inserted_report = row_to_dict(row)
        if inserted_report is None:
            raise RuntimeError("Failed to read inserted report")

        final_chain_fields = build_blockchain_fields(inserted_report, image_path)
        connection.execute(
            """
            UPDATE defect_reports
            SET
                shipment_hash = ?,
                evidence_hash = ?,
                image_hash = ?,
                confidence_bps = ?,
                defect_type_chain_id = ?,
                detected_at_unix = ?
            WHERE id = ?
            """,
            (
                final_chain_fields["shipment_hash"],
                final_chain_fields["evidence_hash"],
                final_chain_fields["image_hash"],
                final_chain_fields["confidence_bps"],
                final_chain_fields["defect_type_chain_id"],
                final_chain_fields["detected_at_unix"],
                report_id,
            ),
        )
        row = connection.execute(
            "SELECT * FROM defect_reports WHERE id = ?",
            (report_id,),
        ).fetchone()
        report = row_to_dict(row)
        if report is None:
            raise RuntimeError("Failed to read inserted report")
        return report


def list_reports(limit: int = 50) -> list[dict[str, Any]]:
    with get_connection() as connection:
        rows = connection.execute(
            """
            SELECT * FROM defect_reports
            ORDER BY created_at DESC, id DESC
            LIMIT ?
            """,
            (limit,),
        ).fetchall()
    return [dict(row) for row in rows]


def get_report(report_id: int) -> dict[str, Any] | None:
    with get_connection() as connection:
        row = connection.execute(
            "SELECT * FROM defect_reports WHERE id = ?",
            (report_id,),
        ).fetchone()
    return row_to_dict(row)


def update_report_blockchain_status(
    report_id: int,
    *,
    status: str,
    tx_hash: str | None = None,
    error: str | None = None,
) -> dict[str, Any]:
    with get_connection() as connection:
        connection.execute(
            """
            UPDATE defect_reports
            SET blockchain_status = ?, blockchain_tx_hash = ?, blockchain_error = ?
            WHERE id = ?
            """,
            (status, tx_hash, error, report_id),
        )
        row = connection.execute(
            "SELECT * FROM defect_reports WHERE id = ?",
            (report_id,),
        ).fetchone()
    report = row_to_dict(row)
    if report is None:
        raise RuntimeError("Failed to read updated report")
    return report


def insert_delivery_certificate(
    *,
    shipment_id: str,
    recipient_reference: str,
    condition_summary: str,
    delivered_at: str,
) -> dict[str, Any]:
    created_at = datetime.now(timezone.utc).isoformat()
    with get_connection() as connection:
        cursor = connection.execute(
            """
            INSERT INTO delivery_certificates (
                shipment_id,
                recipient_reference,
                condition_summary,
                delivered_at,
                created_at
            )
            VALUES (?, ?, ?, ?, ?)
            """,
            (shipment_id, recipient_reference, condition_summary, delivered_at, created_at),
        )
        certificate_id = int(cursor.lastrowid)
        row = connection.execute(
            "SELECT * FROM delivery_certificates WHERE id = ?",
            (certificate_id,),
        ).fetchone()
        certificate = row_to_dict(row)
        if certificate is None:
            raise RuntimeError("Failed to read inserted certificate")

        fields = build_certificate_fields(certificate)
        connection.execute(
            """
            UPDATE delivery_certificates
            SET
                shipment_hash = ?,
                certificate_hash = ?,
                recipient_hash = ?,
                condition_hash = ?,
                delivered_at_unix = ?
            WHERE id = ?
            """,
            (
                fields["shipment_hash"],
                fields["certificate_hash"],
                fields["recipient_hash"],
                fields["condition_hash"],
                fields["delivered_at_unix"],
                certificate_id,
            ),
        )
        row = connection.execute(
            "SELECT * FROM delivery_certificates WHERE id = ?",
            (certificate_id,),
        ).fetchone()
    certificate = row_to_dict(row)
    if certificate is None:
        raise RuntimeError("Failed to read updated certificate")
    return certificate


def get_delivery_certificate(certificate_id: int) -> dict[str, Any] | None:
    with get_connection() as connection:
        row = connection.execute(
            "SELECT * FROM delivery_certificates WHERE id = ?",
            (certificate_id,),
        ).fetchone()
    return row_to_dict(row)


def update_certificate_blockchain_status(
    certificate_id: int,
    *,
    status: str,
    tx_hash: str | None = None,
) -> dict[str, Any]:
    with get_connection() as connection:
        connection.execute(
            """
            UPDATE delivery_certificates
            SET blockchain_tx_hash = ?, blockchain_status = ?
            WHERE id = ?
            """,
            (tx_hash, status, certificate_id),
        )
        row = connection.execute(
            "SELECT * FROM delivery_certificates WHERE id = ?",
            (certificate_id,),
        ).fetchone()
    certificate = row_to_dict(row)
    if certificate is None:
        raise RuntimeError("Failed to read updated certificate")
    return certificate
