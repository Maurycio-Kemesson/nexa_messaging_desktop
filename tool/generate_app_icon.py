from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "logo-icon.png"
OUTPUT = ROOT / "assets" / "app_icon.png"
LINUX_OUTPUT = ROOT / "linux" / "nexa_messaging_desktop.png"

NAVY = (1, 28, 38, 255)
SIZE = 1024
PADDING_RATIO = 0.16


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    bbox = source.getbbox()
    if bbox is None:
        raise SystemExit("logo-icon.png has no visible pixels")

    cropped = source.crop(bbox)
    # Keep the mark (owl) when the wordmark sits on a lower row.
    width, height = cropped.size
    owl = cropped.crop((0, 0, width, int(height * 0.62)))
    owl_bbox = owl.getbbox()
    if owl_bbox is not None:
        owl = owl.crop(owl_bbox)

    canvas = Image.new("RGBA", (SIZE, SIZE), NAVY)
    max_side = int(SIZE * (1 - 2 * PADDING_RATIO))
    ratio = min(max_side / owl.width, max_side / owl.height)
    logo = owl.resize(
        (max(1, int(owl.width * ratio)), max(1, int(owl.height * ratio))),
        Image.Resampling.LANCZOS,
    )
    x = (SIZE - logo.width) // 2
    y = (SIZE - logo.height) // 2
    canvas.paste(logo, (x, y), logo)
    canvas.save(OUTPUT, format="PNG")

    LINUX_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.resize((256, 256), Image.Resampling.LANCZOS).save(
        LINUX_OUTPUT,
        format="PNG",
    )
    print(f"wrote {OUTPUT} and {LINUX_OUTPUT}")


if __name__ == "__main__":
    main()
