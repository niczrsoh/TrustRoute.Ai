<h1 align="center">Parcel Defect Detection Camera System</h1>

<p align="center">
  A Raspberry&nbsp;Pi&nbsp;based vision station that inspects parcels on a conveyor line,
  classifies them as <b>PASS</b> or <b>DEFECT</b> with an on-device AI model, and signals a
  diverter/PLC to reject faulty items.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Raspberry%20Pi-c51a4a">
  <img src="https://img.shields.io/badge/hardware-custom%20board-1a4d6e">
  <img src="https://img.shields.io/badge/board-4--layer%20160%C3%97100mm-2c7a7b">
  <img src="https://img.shields.io/badge/status-prototype-d4a017">
  <img src="https://img.shields.io/badge/license-MIT-green">
</p>

---

## Overview

This project is a custom Raspberry Pi carrier board and the supporting electronics for an
automated parcel inspection station. A photoelectric sensor detects when a parcel arrives,
controlled LED lighting freezes the exposure, the Pi captures an image over the CSI port, and
an AI defect-classification model decides whether the parcel passes. The result drives status
LEDs and an isolated relay output that can trigger a conveyor diverter or feed a PLC.

The board runs from a single **12 V** industrial supply and derives the **5.1 V** rail for the
Raspberry Pi on-board, so the whole station needs only one power input.

---

## How It Works

| Step | Component | Function |
|---|---|---|
| 1 | **Sensor** | Detects when a parcel arrives at the inspection area and sends a trigger signal to the Raspberry Pi to start the check. |
| 2 | **Camera** | Captures the parcel image, which the AI defect-detection model uses to decide whether the parcel is normal or defective. |
| 3 | **Raspberry Pi** | The main controller: receives the sensor signal, captures and processes the image, runs the AI model, and decides the output result. |
| 4 | **LED** | Provides lighting for a clear image; indicator LEDs also show system status (pass/normal or defect/fail). |

```
Sensor detects parcel  ->  Camera captures image  ->  Pi analyzes defect  ->  LED shows result
```

### Key features

- **Single 12 V input** with fuse, TVS surge protection, and reverse-polarity protection
- **On-board 5.1 V / 5 A+ buck converter** sized for the Raspberry Pi
- **Opto-isolated sensor input** so the 12 V photoelectric trigger never touches Pi GPIO directly
- **PWM-dimmable LED lighting** driver (logic-level MOSFET) for consistent exposure
- **PASS / DEFECT status LEDs** for at-a-glance line monitoring
- **Isolated relay output** for a diverter gate or PLC reject signal
- **Pi Camera Module 3 Wide** over the native CSI ribbon (not GPIO)

---

## Documentation

All design documents are included in this repository:

| File | What's inside |
|---|---|
| [parcel_defect_detection_full_document.pdf](parcel_defect_detection_full_document.pdf) | **Full project document (3 pages):** real-object board layout with every component labelled, the schematic diagram, and a component-function summary. Start here for the complete picture. |
| [parceldefect_schematic.pdf](parceldefect_schematic.pdf) | **Electrical schematic** (Rev B, A4): power entry, sensor input, Raspberry Pi, LED driver, status LEDs, relay output, and CSI camera. |
| [parcel_defect_camera_pcb_layout.pdf](parcel_defect_camera_pcb_layout.pdf) | **PCB layout (3 pages):** top assembly view with reference designators, bottom copper view, and 4-layer stack overview. |
| [board_bringup_plan.pdf](board_bringup_plan.pdf) | **Board bring-up plan:** step-by-step power-rail, signal, and functional tests with a pass/fail checklist and sign-off. |

> These are PDFs - click any link to open them in GitHub's viewer.

---

## PCB

Four-layer Raspberry Pi carrier board designed in [Flux](https://www.flux.ai/).
See [parcel_defect_camera_pcb_layout.pdf](parcel_defect_camera_pcb_layout.pdf) for the full layout.

| Spec | Value |
|---|---|
| Board size | 160.1 mm x 100.1 mm |
| Copper layers | 4 (Top, Inner 1, Inner 2, Bottom) |
| Components (pick-and-place) | 31 |
| Drill hits | 153 |
| Gerber set | copper, mask, paste, silk, drill, BOM |

---

## Bill of Materials

| Ref | Part | Value / Type |
|---|---|---|
| J1 | DC input | Barrel jack or terminal block, 12 V 3-5 A |
| F1 | Fuse | 5 A |
| D1 | Reverse-polarity | SS54 Schottky, 5 A |
| D2 | TVS | SMBJ12A |
| C1 / C2 | Bulk caps | 100 uF / 220 uF, 25 V |
| U1 | Buck converter | 12 V -> 5.1 V, 5 A+ |
| R1 / R2 | Sensor interface | 10 k ohm pull-up / 1 k ohm series |
| U4 | Optocoupler | PC817 |
| Q1 | LED MOSFET | IRLZ44N (logic-level) |
| R3 / R4 | Gate network | 100 ohm gate / 100 k ohm pulldown |
| D4 / D5 | Status LEDs | Green (PASS) / Red (DEFECT) + 330 ohm (R5/R6) |
| Q2 / D6 / K1 | Reject output | NPN driver / 1N4007 flyback (D6) / 5 V relay |

---

## GPIO Pin Map

| Pi Pin | Net | Direction | Function |
|---|---|---|---|
| GPIO17 | `GPIO17_TRIGGER` | Input | Parcel sensor (isolated via PC817, pulled to 3.3 V) |
| GPIO18 | `GPIO18_LED_PWM` | PWM out | LED lighting brightness (drives Q1 via R3) |
| GPIO23 | `GPIO23_PASS_LED` | Output | Green PASS indicator (D4 via R5) |
| GPIO24 | `GPIO24_DEFECT_LED` | Output | Red DEFECT indicator (D5 via R6) |
| GPIO27 | `GPIO27_RELAY_CTRL` | Output | Relay / diverter (Q2 drives K1, D6 clamps flyback) |
| CSI | - | Camera bus | Pi Camera Module 3 Wide |

---

## Getting Started

### Hardware

1. Assemble the board following the [PCB layout](parcel_defect_camera_pcb_layout.pdf) and
   [schematic](parceldefect_schematic.pdf).
2. Run through the [Board Bring-Up Plan](board_bringup_plan.pdf) - it covers power-rail
   verification, signal checks, and functional tests with a pass/fail checklist.
3. **Important:** bring up the 5.1 V rail and confirm it *before* seating the Raspberry Pi.
   Do not connect the 12 V sensor output directly to GPIO - verify the U4 optocoupler is populated.

### Software

```bash
# Enable the camera and GPIO interfaces
sudo raspi-config        # Interface Options -> enable Camera

# Clone and set up
git clone https://github.com/<your-username>/parcel-defect-detection.git
cd parcel-defect-detection
pip install -r requirements.txt

# Run the inspection loop
python3 inspect.py
```

---

## Repository Contents

```
.
├── README.md                                  # This page
├── parcel_defect_detection_full_document.pdf  # Full project document
├── parceldefect_schematic.pdf                 # Electrical schematic
├── parcel_defect_camera_pcb_layout.pdf        # PCB layout (top / bottom / stack)
└── board_bringup_plan.pdf                     # Test + validation checklist
```

---

## Roadmap

- [ ] First-spin board bring-up and validation
- [ ] Capture pipeline + trigger synchronization
- [ ] Defect classification model integration
- [ ] PLC / diverter field test on a live line
- [ ] Enclosure (STEP) + mounting hardware

---

## Author

**Muhammad Hafiz bin Kamaruddin**

