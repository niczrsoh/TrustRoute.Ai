from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps


DEFECT_CLASSES = ("normal", "crack", "dent", "leakage")


@dataclass(frozen=True)
class Prediction:
    defect_type: str
    confidence: float
    scores: dict[str, float]
    model_name: str
    explanation: str
    item_type: str | None = None
    damage_location: str | None = None
    raw_model_output: str | None = None


class DefectClassifier:
    """Image-feature baseline with the same interface as a future CNN model."""

    model_name = "image-feature-baseline-v1"

    def predict(self, image_path: Path) -> Prediction:
        image = Image.open(image_path)
        rgb = ImageOps.exif_transpose(image).convert("RGB")
        rgb.thumbnail((384, 384))

        arr = np.asarray(rgb).astype(np.float32) / 255.0
        gray = self._rgb_to_gray(arr)
        edge = self._edge_magnitude(gray)

        crack_score = self._score_crack(gray, edge)
        dent_score = self._score_dent(gray, edge)
        leakage_score = self._score_leakage(arr, gray)

        defect_scores = {
            "crack": crack_score,
            "dent": dent_score,
            "leakage": leakage_score,
        }
        best_defect, best_score = max(defect_scores.items(), key=lambda item: item[1])

        if best_score < 0.34:
            defect_type = "normal"
            confidence = self._clamp(0.72 + (0.34 - best_score) * 0.55)
        else:
            defect_type = best_defect
            confidence = self._clamp(0.56 + best_score * 0.42)

        normal_score = self._clamp(1.0 - best_score * 1.35)
        scores = {
            "normal": normal_score,
            "crack": crack_score,
            "dent": dent_score,
            "leakage": leakage_score,
        }

        return Prediction(
            defect_type=defect_type,
            confidence=round(confidence, 4),
            scores={key: round(value, 4) for key, value in scores.items()},
            model_name=self.model_name,
            explanation=self._explain(defect_type, scores),
        )

    @staticmethod
    def _rgb_to_gray(arr: np.ndarray) -> np.ndarray:
        return arr[..., 0] * 0.299 + arr[..., 1] * 0.587 + arr[..., 2] * 0.114

    @staticmethod
    def _edge_magnitude(gray: np.ndarray) -> np.ndarray:
        gx = np.diff(gray, axis=1, append=gray[:, -1:])
        gy = np.diff(gray, axis=0, append=gray[-1:, :])
        return np.hypot(gx, gy)

    def _score_crack(self, gray: np.ndarray, edge: np.ndarray) -> float:
        dark_pixels = gray < 0.30
        dark_edges = dark_pixels & (edge > 0.12)
        strong_edges = edge > 0.18
        dark_ratio = float(dark_pixels.mean())
        thin_dark_bonus = dark_ratio * 6.0 if dark_ratio < 0.08 else 0.48
        score = dark_edges.mean() * 45.0 + strong_edges.mean() * 1.0 + thin_dark_bonus
        return self._clamp(score)

    def _score_dent(self, gray: np.ndarray, edge: np.ndarray) -> float:
        small = Image.fromarray((gray * 255).astype(np.uint8)).resize((24, 24), Image.Resampling.BILINEAR)
        low_freq = np.asarray(small).astype(np.float32) / 255.0
        shadow_threshold = max(float(gray.mean() - 0.13), 0.0)
        shadow_blocks = low_freq < shadow_threshold
        smooth_shadow = shadow_blocks.mean() * max(0.0, 1.0 - float(edge.mean()) * 8.0)
        local_variation = float(gray.std())
        score = smooth_shadow * 4.0 + local_variation * 0.45
        return self._clamp(score)

    def _score_leakage(self, arr: np.ndarray, gray: np.ndarray) -> float:
        red = arr[..., 0]
        green = arr[..., 1]
        blue = arr[..., 2]

        max_channel = arr.max(axis=2)
        min_channel = arr.min(axis=2)
        saturation = (max_channel - min_channel) / np.maximum(max_channel, 1e-6)

        blue_green_stain = (blue > red * 1.08) & (green > red * 0.90) & (saturation > 0.14)
        brown_stain = (red > green * 1.04) & (green > blue * 1.04) & (saturation > 0.16) & (gray < 0.78)
        wet_dark_area = (gray < 0.36) & (saturation > 0.08)
        stain_pixels = blue_green_stain | brown_stain | wet_dark_area

        score = stain_pixels.mean() * 7.0 + float(saturation.mean()) * 0.18
        return self._clamp(score)

    @staticmethod
    def _clamp(value: float, lower: float = 0.0, upper: float = 0.99) -> float:
        return max(lower, min(upper, float(value)))

    @staticmethod
    def _explain(defect_type: str, scores: dict[str, float]) -> str:
        if defect_type == "normal":
            return "No strong crack, dent, or leakage visual pattern was detected by the MVP baseline."
        if defect_type == "crack":
            return "Dark high-contrast edge patterns were strongest in the image."
        if defect_type == "dent":
            return "Smooth shadow or depression-like regions were strongest in the image."
        if defect_type == "leakage":
            return "Stain-like color or wet dark regions were strongest in the image."
        return f"Top score was {defect_type}: {scores.get(defect_type, 0.0):.2f}."
