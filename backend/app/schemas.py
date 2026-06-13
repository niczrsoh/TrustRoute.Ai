from datetime import datetime

from pydantic import BaseModel, Field


class PredictionResponse(BaseModel):
    id: int
    shipment_id: str
    defect_type: str
    confidence: float = Field(ge=0.0, le=1.0)
    scores: dict[str, float]
    model_name: str
    explanation: str
    item_type: str | None = None
    damage_location: str | None = None
    shipment_hash: str
    evidence_hash: str
    image_hash: str
    confidence_bps: int = Field(ge=0, le=10000)
    defect_type_chain_id: int = Field(ge=0, le=4)
    detected_at_unix: int
    blockchain_status: str | None = None
    blockchain_tx_hash: str | None = None
    blockchain_error: str | None = None
    image_path: str
    timestamp: datetime


class ReportResponse(BaseModel):
    id: int
    shipment_id: str
    defect_type: str
    confidence: float = Field(ge=0.0, le=1.0)
    model_name: str
    explanation: str
    item_type: str | None = None
    damage_location: str | None = None
    shipment_hash: str
    evidence_hash: str
    image_hash: str
    confidence_bps: int = Field(ge=0, le=10000)
    defect_type_chain_id: int = Field(ge=0, le=4)
    detected_at_unix: int
    blockchain_status: str | None = None
    blockchain_tx_hash: str | None = None
    blockchain_error: str | None = None
    image_path: str
    timestamp: datetime


class BlockchainAnchorPayload(BaseModel):
    report_id: int
    contract_function: str
    shipment_hash: str
    evidence_hash: str
    defect_type_chain_id: int = Field(ge=0, le=4)
    confidence_bps: int = Field(ge=0, le=10000)
    detected_at_unix: int


class BlockchainTransactionResponse(BaseModel):
    status: str
    tx_hash: str | None = None
    message: str | None = None
    payload: dict


class DeliveryCertificateRequest(BaseModel):
    shipment_id: str
    recipient_reference: str
    condition_summary: str = "received"
    delivered_at: datetime | None = None


class DeliveryCertificateResponse(BaseModel):
    id: int
    shipment_id: str
    recipient_reference: str
    condition_summary: str
    delivered_at: datetime
    shipment_hash: str
    certificate_hash: str
    recipient_hash: str
    condition_hash: str
    delivered_at_unix: int
    blockchain_tx_hash: str | None = None
    blockchain_status: str


class DeliveryCertificatePayload(BaseModel):
    certificate_id: int
    contract_function: str
    shipment_hash: str
    certificate_hash: str
    recipient_hash: str
    condition_hash: str
    delivered_at_unix: int


class HealthResponse(BaseModel):
    status: str
    service: str


class ClassesResponse(BaseModel):
    classes: list[str]
    mode: str = "dynamic"
    note: str | None = None
