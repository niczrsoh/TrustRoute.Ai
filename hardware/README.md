<p align="center">
  <img src="images/banner.png" alt="Parcel Defect Detection Camera System" width="100%">
</p>

<h1 align="center">Parcel Defect Detection Camera System</h1>

<p align="center">
  A Raspberry&nbsp;Pi&nbsp;5 based vision station that inspects parcels on a conveyor line,
  classifies them as <b>PASS</b> or <b>DEFECT</b> with an on-device AI model, and signals a
  diverter/PLC to reject faulty items.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Raspberry%20Pi%205-c51a4a">
  <img src="https://img.shields.io/badge/hardware-custom%20HAT-1a4d6e">
  <img src="https://img.shields.io/badge/status-prototype-d4a017">
  <img src="https://img.shields.io/badge/license-MIT-green">
</p>

---

## Overview

This project is a custom Raspberry Pi HAT (Hardware Attached on Top) and the supporting
electronics for an automated parcel inspection station. A photoelectric sensor detects when a
parcel enters the camera's field of view, controlled LED lighting freezes the exposure, the Pi
captures an image over the CSI port, and an AI defect-classification model decides whether the
parcel passes. The result drives status LEDs and an isolated relay output that can trigger a
conveyor diverter or feed a PLC.

The board takes a single **12 V** industrial supply and derives everything it needs on-board,
so the whole station runs from one power input.

### Key features

- **Single 12 V input** with fuse, TVS surge protection, and reverse-polarity protection
- **On-board 5.1 V / 5 A+ buck converter** sized for the Raspberry Pi 5
- **Opto-isolated sensor input** so the 12 V photoelectric trigger never touches Pi GPIO directly
- **PWM-dimmable LED lighting** driver (logic-level MOSFET) for consistent exposure
- **PASS / DEFECT status LEDs** for at-a-glance line monitoring
- **Isolated relay output** for a diverter gate or PLC reject signal
- **Pi Camera Module 3 Wide** over the native CSI ribbon (not GPIO)

---

## System Architecture

The complete electrical schematic, from power entry to the reject output:

<p align="center">
  <img src="images/schematic.png" alt="System schematic" width="80%">
</p>

| Stage | Function |
|---|---|
| **J1 -> F1 -> D1/D2** | 12 V input with fuse, TVS clamp, and reverse-polarity diode |
| **U1 buck** | Steps 12 V down to a regulated 5.1 V rail for the Pi |
| **S1 + opto** | Photoelectric parcel trigger, isolated into `GPIO17` |
| **Q1 LED driver** | `GPIO18` PWM dims the 12 V LED bar via a logic-level MOSFET |
| **U3 camera** | Pi Camera Module 3 Wide on the CSI ribbon |
| **Status LEDs** | `GPIO23` -> green PASS, `GPIO24` -> red DEFECT |
| **Q2 + K1 relay** | `GPIO27` drives an isolated relay to the diverter / PLC |

---

## PCB

Four-layer Raspberry Pi HAT, designed in [Flux](https://www.flux.ai/).

<table>
  <tr>
    <td align="center"><b>Top</b></td>
    <td align="center"><b>Bottom</b></td>
  </tr>
  <tr>
    <td><img src="images/pcb_top.png" alt="PCB top" width="100%"></td>
    <td><img src="images/pcb_bottom.png" alt="PCB bottom" width="100%"></td>
  </tr>
</table>

Manufacturing outputs (Gerbers, drill, pick-and-place, BOM) are in [`hardware/`](hardware/)
and can be uploaded directly to JLCPCB, PCBWay, or NextPCB.

---

## Bill of Materials

| Ref | Part | Value / Type |
|---|---|---|
| J1 | DC input | Barrel jack or terminal block, 12 V 3–5 A |
| F1 | Fuse | 5 A |
| D1 | Reverse-polarity | SS54 Schottky, 5 A |
| D2 | TVS | SMBJ12A |
| C1 / C2 | Bulk caps | 100  uF / 220  uF, 25 V |
| U1 | Buck converter | 12 V -> 5.1 V, 5 A+ |
| R1 / R2 | Sensor interface | 10 k ohm pull-up / 1 k ohm series |
| U4 | Optocoupler | PC817 |
| Q1 | LED MOSFET | IRLZ44N (logic-level) |
| R3 / R4 | Gate network | 100  ohm gate / 100 k ohm pulldown |
| D4 / D5 | Status LEDs | Green (PASS) / Red (DEFECT) + 330  ohm |
| Q2 / D6 / K1 | Reject output | NPN driver / 1N4007 flyback / 5 V relay |

> A complete, manufacturer-formatted BOM is exported with the Gerbers in [`hardware/`](hardware/).

---

## GPIO Pin Map

| Pi Pin | Net | Direction | Function |
|---|---|---|---|
| GPIO17 | `GPIO17_TRIGGER` | Input | Parcel sensor (isolated, pulled to 3.3 V) |
| GPIO18 | `GPIO18_LED_PWM` | PWM out | LED lighting brightness |
| GPIO23 | `GPIO23_PASS_LED` | Output | Green PASS indicator |
| GPIO24 | `GPIO24_DEFECT_LED` | Output | Red DEFECT indicator |
| GPIO27 | `GPIO27_RELAY_CTRL` | Output | Relay / diverter (via transistor) |
| CSI | — | Camera bus | Pi Camera Module 3 Wide |

---

## Getting Started

### Hardware

1. Assemble the HAT (or order it assembled from the files in [`hardware/`](hardware/)).
2. Follow the [**Board Bring-Up Plan**](docs/board_bringup_plan.pdf) — it walks through power-rail
   verification, signal checks, and functional tests with a pass/fail checklist.
3. **Important:** bring up the 5.1 V rail and confirm it *before* seating the Raspberry Pi.

### Software

```bash
# Enable the camera and GPIO interfaces
sudo raspi-config        # Interface Options -> enable Camera

# Clone and set up
git clone https://github.com/<your-username>/parcel-defect-detection.git
cd parcel-defect-detection
pip install -r requirements.txt

# Run the inspection loop
python3 src/inspect.py
```

---

## Repository Structure

```
parcel-defect-detection/
├── README.md
├── images/                 # Schematic, PCB renders, banner
├── hardware/               # Gerbers, drill, pick-and-place, BOM
├── docs/
│   ├── schematic.pdf
│   └── board_bringup_plan.pdf
└── src/                    # Inspection + classification code
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
Radiation Protection Officer · Billion Prima Technologies Sdn Bhd

---

## License

Released under the MIT License — see [`LICENSE`](LICENSE) for details.
