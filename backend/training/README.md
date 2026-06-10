# AI Training Notes

The running MVP uses `app/ai/inference.py`, which is a deterministic image-feature baseline. Use this folder when the team has real defect images and is ready to train a CNN/MobileNet model.

## Dataset Layout

```text
dataset/
  train/
    crack/
    dent/
    leakage/
    normal/
  val/
    crack/
    dent/
    leakage/
    normal/
```

## Recommended Collection Rules

- Capture images with the same Raspberry Pi camera setup planned for the demo.
- Include multiple angles, lighting conditions, and package materials.
- Keep one dominant label per image.
- Collect normal images too; the model needs to learn what "not defective" looks like.

## MVP Model Path

1. Start with the current baseline for end-to-end integration.
2. Collect and label images.
3. Train MobileNet or a small CNN.
4. Replace `DefectClassifier.predict()` internals without changing the API endpoint.

Keeping the `predict(image_path)` interface stable means the frontend, dashboard, Raspberry Pi uploader, and database do not need to change when the real model arrives.
