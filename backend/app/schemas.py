from datetime import datetime

from pydantic import BaseModel, Field


class ScoreBreakdown(BaseModel):
    normal: float = Field(ge=0.0, le=1.0)
    crack: float = Field(ge=0.0, le=1.0)
    dent: float = Field(ge=0.0, le=1.0)
    leakage: float = Field(ge=0.0, le=1.0)


class PredictionResponse(BaseModel):
    id: int
    shipment_id: str
    defect_type: str
    confidence: float = Field(ge=0.0, le=1.0)
    scores: ScoreBreakdown
    model_name: str
    explanation: str
    item_type: str | None = None
    damage_location: str | None = None
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
    image_path: str
    timestamp: datetime


class HealthResponse(BaseModel):
    status: str
    service: str


class ClassesResponse(BaseModel):
    classes: list[str]
