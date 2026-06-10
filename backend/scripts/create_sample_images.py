from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent.parent
SAMPLE_DIR = ROOT / "samples"


def save_normal() -> None:
    image = Image.new("RGB", (320, 220), (214, 218, 213))
    image.save(SAMPLE_DIR / "normal.jpg", quality=92)


def save_crack() -> None:
    image = Image.new("RGB", (320, 220), (210, 213, 208))
    draw = ImageDraw.Draw(image)
    points = [(55, 42), (92, 68), (126, 63), (164, 105), (207, 116), (252, 165)]
    draw.line(points, fill=(20, 22, 21), width=5)
    draw.line([(100, 70), (88, 101), (69, 126)], fill=(38, 38, 36), width=3)
    image.save(SAMPLE_DIR / "crack.jpg", quality=92)


def save_dent() -> None:
    image = Image.new("RGB", (320, 220), (204, 207, 202))
    shadow = Image.new("L", (320, 220), 0)
    draw = ImageDraw.Draw(shadow)
    draw.ellipse((96, 50, 230, 178), fill=125)
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    dark = Image.new("RGB", (320, 220), (95, 97, 94))
    image.paste(dark, mask=shadow)
    image.save(SAMPLE_DIR / "dent.jpg", quality=92)


def save_leakage() -> None:
    image = Image.new("RGB", (320, 220), (209, 210, 202))
    stain = Image.new("L", (320, 220), 0)
    draw = ImageDraw.Draw(stain)
    draw.ellipse((124, 58, 242, 170), fill=155)
    draw.ellipse((174, 124, 292, 207), fill=105)
    stain = stain.filter(ImageFilter.GaussianBlur(14))
    color = Image.new("RGB", (320, 220), (70, 118, 132))
    image.paste(color, mask=stain)
    image.save(SAMPLE_DIR / "leakage.jpg", quality=92)


def main() -> None:
    SAMPLE_DIR.mkdir(exist_ok=True)
    save_normal()
    save_crack()
    save_dent()
    save_leakage()
    print(f"Sample images written to {SAMPLE_DIR}")


if __name__ == "__main__":
    main()
