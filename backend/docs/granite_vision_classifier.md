# IBM Granite Vision Classifier

The backend now supports IBM Granite Vision as the local VLM classifier for delivered goods.

## Why Granite Vision

The delivered item may be a parcel, car, appliance, furniture, electronics, or another type of good. A vision-language model is a better MVP fit than fixed image heuristics because it can inspect the image semantically and describe what item appears damaged.

The backend still returns the same main classification fields:

```json
{
  "defect_type": "normal | crack | dent | leakage",
  "confidence": 0.0,
  "explanation": "short reason"
}
```

It can also return:

```json
{
  "item_type": "cardboard parcel",
  "damage_location": "front-left corner"
}
```

## Selected Model

Default model:

```text
ibm-granite/granite-vision-3.2-2b
```

This is the default because it is lighter and suitable for general image understanding. IBM also provides `ibm-granite/granite-vision-4.1-4b`, but that version is more strongly focused on document/chart/table extraction. It can still be used by changing `SLT_GRANITE_MODEL_ID`.

## Enable Granite Vision

Install the normal backend dependencies first:

```powershell
pip install -r requirements-dev.txt
```

Then install PyTorch for your machine from the official PyTorch selector. On Windows CPU-only machines, prefer the official CPU wheel command instead of letting `pip install torch` choose a default build:

```powershell
pip install torch --index-url https://download.pytorch.org/whl/cpu
```

Then install the remaining VLM dependencies:

```powershell
pip install -r requirements-vlm.txt
```

Run the API:

```powershell
$env:SLT_CLASSIFIER_BACKEND = "granite"
$env:SLT_GRANITE_MODEL_ID = "ibm-granite/granite-vision-3.2-2b"
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The first prediction may take time because the model weights need to download and load.

## Windows Torch DLL Error

If `/predict` falls back with an error like this:

```text
[WinError 1114] A dynamic link library (DLL) initialization routine failed.
Error loading ... torch\lib\c10.dll
```

Torch is installed but cannot load in that Python environment. Fix it by reinstalling a compatible CPU wheel:

```powershell
pip uninstall -y torch
pip install torch --index-url https://download.pytorch.org/whl/cpu
python -c "import torch; print(torch.__version__)"
```

If another Python environment already has a working Torch install, run the server from that same environment:

```powershell
python -c "import sys, torch; print(sys.executable); print(torch.__version__)"
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Fallback Behavior

By default:

```text
SLT_CLASSIFIER_FALLBACK=true
```

If Granite Vision dependencies or model weights are unavailable, the backend falls back to the simple image-feature baseline so the demo does not break.

For a strict Granite-only run:

```powershell
$env:SLT_CLASSIFIER_FALLBACK = "false"
```

## Change Model Version

Use Granite Vision 4.1:

```powershell
$env:SLT_GRANITE_MODEL_ID = "ibm-granite/granite-vision-4.1-4b"
$env:SLT_GRANITE_TRUST_REMOTE_CODE = "true"
```

Use this only if the machine has enough memory and the required Transformers version. For the hackathon MVP, `granite-vision-3.2-2b` is the safer default.

## Raspberry Pi Role

Do not run Granite Vision on the Raspberry Pi for the MVP. Use this split:

```text
Raspberry Pi + HD camera = capture image/frame
Backend server/laptop = run Granite Vision
Mobile app/dashboard = display result
```

When video is added later, the Raspberry Pi can sample frames and send those frames to the same `/predict` endpoint.
