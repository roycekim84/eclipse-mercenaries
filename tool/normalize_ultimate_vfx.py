#!/usr/bin/env python3
"""Normalize the generated ultimate VFX sheet into a safe 4x2 RGBA atlas."""

from pathlib import Path
import sys

from PIL import Image


COLUMNS = 4
ROWS = 2
CELL_SIZE = (512, 384)
CONTENT_SIZE = (464, 336)


def _remove_black_background(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    rgba = Image.new("RGBA", rgb.size)
    source = rgb.load()
    target = rgba.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            red, green, blue = source[x, y]
            peak = max(red, green, blue)
            alpha = max(0, min(255, (peak - 5) * 5))
            target[x, y] = (red, green, blue, alpha)
    return rgba


def normalize(source_path: Path, output_path: Path) -> None:
    source = Image.open(source_path).convert("RGB")
    atlas = Image.new(
        "RGBA",
        (CELL_SIZE[0] * COLUMNS, CELL_SIZE[1] * ROWS),
        (0, 0, 0, 0),
    )
    for row in range(ROWS):
        for column in range(COLUMNS):
            left = round(column * source.width / COLUMNS)
            right = round((column + 1) * source.width / COLUMNS)
            top = round(row * source.height / ROWS)
            bottom = round((row + 1) * source.height / ROWS)
            effect = _remove_black_background(
                source.crop(
                    (
                        left + round((right - left) * 0.075),
                        top + round((bottom - top) * 0.065),
                        right - round((right - left) * 0.075),
                        bottom - round((bottom - top) * 0.065),
                    ),
                ),
            )
            effect.thumbnail(CONTENT_SIZE, Image.Resampling.LANCZOS)
            x = column * CELL_SIZE[0] + (CELL_SIZE[0] - effect.width) // 2
            y = row * CELL_SIZE[1] + (CELL_SIZE[1] - effect.height) // 2
            atlas.alpha_composite(effect, (x, y))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output_path, optimize=True)


if __name__ == "__main__":
    source = Path(sys.argv[1])
    output = Path(sys.argv[2]) if len(sys.argv) > 2 else source
    normalize(source, output)
