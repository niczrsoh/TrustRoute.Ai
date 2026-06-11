from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
import sqlite3
from typing import Any, Iterator

from .blockchain import build_blockchain_fields
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
    image_path TEXT NOT NULL,
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
