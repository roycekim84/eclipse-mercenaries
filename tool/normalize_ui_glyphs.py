#!/usr/bin/env python3
"""Build transparent, consistently padded production UI glyphs.

Legacy glyph sources were rendered on a nearly-black square.  This tool turns
that matte into alpha, crops the visible object, and places it on a shared
313x313 canvas.  The source files remain under assets/source/generated so the
operation is repeatable and does not progressively erode the final PNGs.
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/generated/ui_glyphs"
OUTPUT = ROOT / "assets/images/ui/glyphs"
CANVAS = 313
CONTENT = 265


def remove_dark_matte(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    # All legacy sources use a cool near-black matte.  Difference from a
    # blurred corner-derived background retains metal, leather and gems while
    # suppressing the square and its faint compression texture.
    corners = [rgb.getpixel(point) for point in [(0, 0), (312, 0), (0, 312), (312, 312)]]
    background = tuple(sum(pixel[channel] for pixel in corners) // 4 for channel in range(3))
    matte = Image.new("RGB", rgb.size, background)
    difference = ImageChops.difference(rgb, matte)
    alpha = difference.convert("L").point(
        lambda value: 0 if value <= 16 else min(255, (value - 16) * 12)
    )
    alpha = alpha.filter(ImageFilter.GaussianBlur(.55))
    rgba = rgb.convert("RGBA")
    rgba.putalpha(alpha)
    return rgba


def fit_canvas(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > 16 else 0).getbbox()
    if bbox is None:
        raise ValueError("glyph has no visible pixels")
    cropped = image.crop(bbox)
    cropped.thumbnail((CONTENT, CONTENT), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.alpha_composite(
        cropped,
        ((CANVAS - cropped.width) // 2, (CANVAS - cropped.height) // 2),
    )
    return canvas


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    sources = sorted(SOURCE.glob("*.png"))
    if not sources:
        raise SystemExit(f"no source glyphs found in {SOURCE}")
    for source in sources:
        image = Image.open(source)
        if image.mode == "RGBA" and image.getchannel("A").getextrema()[0] == 0:
            transparent = image.convert("RGBA")
        else:
            transparent = remove_dark_matte(image)
        destination = OUTPUT / source.name
        fit_canvas(transparent).save(destination, optimize=True)
        print(destination.relative_to(ROOT))


if __name__ == "__main__":
    main()
