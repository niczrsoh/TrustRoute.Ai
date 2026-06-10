# Raspberry Pi Integration Plan

The final hardware direction is a Raspberry Pi with a high-definition camera. The MVP should still use image upload first, then move to video after the rest of the system is stable.

## Current MVP: Still Image Upload

For now, the Raspberry Pi should capture one image at a time and send it to the backend:

```text
Raspberry Pi camera -> captured image -> POST /predict -> Granite Vision result -> database -> mobile app/dashboard
```

This uses the existing endpoint:

```text
POST /predict
```

Request format:

```text
multipart/form-data
image=<captured image file>
shipment_id=<optional shipment/package id>
```

This is enough for the first demo because the backend, AI classification, database, and mobile result display all work with the same response format.

The Raspberry Pi should not run the VLM during the MVP. It should capture images and send them to the backend server, where IBM Granite Vision runs locally.

## Recommended Pi MVP Behavior

1. Camera points at the shipment/package inspection area.
2. Operator presses a capture button or the Pi captures at fixed intervals.
3. Pi saves a still image.
4. Pi sends the image to `POST /predict`.
5. Backend returns the classification result.
6. Mobile app/dashboard shows the latest defect result.

## Future Upgrade: Video Stream

When the team is ready for video, there are two practical paths.

### Option A: Frame Sampling

The Raspberry Pi records or reads a live camera feed, extracts frames every few seconds, and sends those frames to the existing `/predict` endpoint.

```text
Pi video feed -> selected frames -> POST /predict -> same response format
```

This is the recommended first video upgrade because it reuses the current backend and AI classifier.

Good starting settings:

```text
1 frame per second for demo
1 frame every 3 to 5 seconds for lighter network use
JPEG image quality around 70 to 85
```

### Option B: True Stream Endpoint

Later, the backend can add a dedicated stream endpoint, for example:

```text
POST /predict-stream
```

Possible stream sources:

- MJPEG stream
- RTSP stream
- WebRTC stream
- uploaded video file

The backend would decode frames, run classification on selected frames, and return either the latest result or a timeline of detections.

## Why Image First Is Best

The image-first MVP proves the core pipeline:

```text
camera input -> AI classification -> saved report -> mobile app result
```

Once that works, video is mainly an input upgrade. The AI result JSON can stay the same, so the mobile app does not need to be rebuilt when the hardware moves from still images to video.

## Future Video Result Shape

A future video endpoint can reuse the current fields and add frame-level metadata:

```json
{
  "shipment_id": "SHIP-001",
  "defect_type": "leakage",
  "confidence": 0.86,
  "timestamp": "2026-06-10T05:17:30.038162+00:00",
  "source": "video_stream",
  "frame_time_seconds": 4.2
}
```

For now, the mobile app should integrate against the existing `/predict` image response.
