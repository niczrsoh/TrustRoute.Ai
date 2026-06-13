from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
import re
from typing import Any

from PIL import Image, ImageOps

from .inference import Prediction


GRANITE_DEFECT_PROMPT = """
Carefully inspect the entire image for any visible damage. If there are multiple items and ANY of them are damaged, you MUST report the damage instead of normal.
Reply with a maximum of two words describing the condition.
Do not write sentences. Do not write "the image shows". Just the condition.
Examples: normal, crushed package, torn box, wet package, broken glass, scratched car, dented panel, leaked liquid.
""".strip()


@dataclass
class GraniteVisionClassifier:
    model_id: str
    trust_remote_code: bool = False
    max_new_tokens: int = 220

    def __post_init__(self) -> None:
        self.model_name = self.model_id
        self._processor: Any | None = None
        self._model: Any | None = None
        self._torch: Any | None = None
        self._device: str | None = None

    def predict(self, image_path: Path) -> Prediction:
        self._load_model()
        raw_output = self._generate(image_path)
        return self._parse_prediction(raw_output)

    def _load_model(self) -> None:
        if self._processor is not None and self._model is not None:
            return

        try:
            import torch
            from transformers import AutoProcessor

            try:
                from transformers import AutoModelForImageTextToText as AutoModel
            except ImportError:
                from transformers import AutoModelForVision2Seq as AutoModel
        except ImportError as exc:
            raise RuntimeError(
                "Granite Vision dependencies are not installed. "
                "Install them with requirements-vlm.txt or use SLT_CLASSIFIER_BACKEND=baseline."
            ) from exc

        self._torch = torch
        if torch.cuda.is_available():
            self._device = "cuda"
        elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            self._device = "mps"
        else:
            self._device = "cpu"
        self._processor = AutoProcessor.from_pretrained(
            self.model_id,
            trust_remote_code=self.trust_remote_code,
        )
        if hasattr(self._processor, "tokenizer"):
            self._processor.tokenizer.padding_side = "left"

        if self._device == "cuda":
            dtype = torch.bfloat16
        elif self._device == "mps":
            dtype = torch.float16
        else:
            dtype = torch.float32
        try:
            self._model = AutoModel.from_pretrained(
                self.model_id,
                dtype=dtype,
                trust_remote_code=self.trust_remote_code,
            )
        except TypeError:
            self._model = AutoModel.from_pretrained(
                self.model_id,
                torch_dtype=dtype,
                trust_remote_code=self.trust_remote_code,
            )
        self._model = self._model.to(self._device).eval()

    def _generate(self, image_path: Path) -> str:
        if self._processor is None or self._model is None or self._torch is None or self._device is None:
            raise RuntimeError("Granite Vision model was not loaded")

        image = ImageOps.exif_transpose(Image.open(image_path)).convert("RGB")
        image.thumbnail((512, 512))
        conversation = [
            {
                "role": "user",
                "content": [
                    {"type": "image"},
                    {"type": "text", "text": GRANITE_DEFECT_PROMPT},
                ],
            }
        ]
        text = self._processor.apply_chat_template(
            conversation,
            tokenize=False,
            add_generation_prompt=True,
        )
        inputs = self._processor(
            text=[text],
            images=[image],
            return_tensors="pt",
            padding=True,
        ).to(self._device)

        with self._torch.no_grad():
            output = self._model.generate(
                **inputs,
                max_new_tokens=self.max_new_tokens,
                do_sample=False,
                use_cache=True,
            )

        generated = output[0][inputs["input_ids"].shape[1] :]
        return self._processor.decode(generated, skip_special_tokens=True).strip()

    def _parse_prediction(self, raw_output: str) -> Prediction:
        data = self._extract_json(raw_output)

        defect_type = self._normalize_defect_type(str(data.get("defect_type", raw_output)))
        confidence = self._clamp_float(data.get("confidence", 0.7))
        item_type = self._clean_optional_text(data.get("item_type"))
        damage_location = self._clean_optional_text(data.get("damage_location"))
        explanation = self._clean_optional_text(data.get("explanation")) or self._default_explanation(
            defect_type,
            item_type,
        )

        scores = self._scores_from_label(defect_type, confidence)
        return Prediction(
            defect_type=defect_type,
            confidence=round(confidence, 4),
            scores=scores,
            model_name=self.model_name,
            explanation=explanation,
            item_type=item_type,
            damage_location=damage_location,
            raw_model_output=raw_output,
        )

    @staticmethod
    def _extract_json(raw_output: str) -> dict[str, Any]:
        try:
            parsed = json.loads(raw_output)
            if isinstance(parsed, dict):
                return parsed
        except json.JSONDecodeError:
            pass

        match = re.search(r"\{.*\}", raw_output, flags=re.DOTALL)
        if not match:
            return {
                "defect_type": raw_output.strip(),
                "confidence": 0.7,
                "explanation": None,
            }

        try:
            parsed = json.loads(match.group(0))
        except json.JSONDecodeError:
            return {
                "defect_type": raw_output.strip(),
                "confidence": 0.7,
                "explanation": None,
            }
        return parsed if isinstance(parsed, dict) else {}

    @staticmethod
    def _normalize_defect_type(value: str) -> str:
        normalized = re.sub(r"[^a-z0-9]+", "_", value.strip().lower()).strip("_")
        if not normalized:
            return "unknown_condition"

        normal_phrases = {
            "normal",
            "none",
            "no_defect",
            "no_damage",
            "undamaged",
            "ok",
            "fine",
            "good_condition",
        }
        if normalized in normal_phrases:
            return "normal"
        return normalized[:80]

    @staticmethod
    def _clamp_float(value: Any) -> float:
        try:
            number = float(value)
        except (TypeError, ValueError):
            number = 0.65
        return max(0.0, min(0.99, number))

    @staticmethod
    def _clean_optional_text(value: Any) -> str | None:
        if value is None:
            return None
        text = str(value).strip()
        if not text or text.lower() in {"null", "none", "n/a", "unknown"}:
            return None
        return text[:500]

    @staticmethod
    def _scores_from_label(defect_type: str, confidence: float) -> dict[str, float]:
        return {defect_type: round(confidence, 4)}

    @staticmethod
    def _default_explanation(defect_type: str, item_type: str | None) -> str:
        subject = item_type or "delivered item"
        if defect_type == "normal":
            return f"No visible damage was found on the {subject}."
        return f"The {subject} appears to show visible condition: {defect_type}."
