from __future__ import annotations

import logging
from pathlib import Path
import traceback

from PIL import UnidentifiedImageError

from .granite_vision import GraniteVisionClassifier
from .inference import DefectClassifier, Prediction
from ..config import settings


logger = logging.getLogger(__name__)


class FallbackClassifier:
    def __init__(self, primary: object, fallback: DefectClassifier) -> None:
        self.primary = primary
        self.fallback = fallback
        self.model_name = f"{getattr(primary, 'model_name', 'primary')}+fallback"

    def predict(self, image_path: Path) -> Prediction:
        try:
            return self.primary.predict(image_path)
        except UnidentifiedImageError:
            raise
        except Exception as exc:
            logger.exception("Primary classifier failed; using fallback classifier")
            Path("data").mkdir(exist_ok=True)
            Path("data/granite_error.log").write_text(
                traceback.format_exc(),
                encoding="utf-8",
            )
            prediction = self.fallback.predict(image_path)
            reason = str(exc).replace("\n", " ")[:240]
            return Prediction(
                defect_type=prediction.defect_type,
                confidence=prediction.confidence,
                scores=prediction.scores,
                model_name=f"{prediction.model_name} (fallback: {reason})",
                explanation=prediction.explanation,
                item_type=prediction.item_type,
                damage_location=prediction.damage_location,
                raw_model_output=prediction.raw_model_output,
            )


def create_classifier() -> object:
    backend = settings.classifier_backend.strip().lower()
    baseline = DefectClassifier()

    if backend == "baseline":
        return baseline
    if backend != "granite":
        raise ValueError(f"Unsupported classifier backend: {settings.classifier_backend}")

    granite = GraniteVisionClassifier(
        model_id=settings.granite_model_id,
        trust_remote_code=settings.granite_trust_remote_code,
        max_new_tokens=settings.granite_max_new_tokens,
    )
    if settings.classifier_fallback_enabled:
        return FallbackClassifier(granite, baseline)
    return granite
