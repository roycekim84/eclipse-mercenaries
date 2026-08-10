#!/usr/bin/env python3
"""Build the drawAtlas-ready battlefield unit sheet from the source atlas."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/images/battlefield/unit_role_atlas.png"
TARGET = ROOT / "assets/images/battlefield/unit_role_batch.png"

# Twice the existing logical render size. Keeping each role's aspect ratio in
# the source rect lets drawAtlas use a uniform 0.5 scale without visual drift.
ROLE_SIZES = [
    (88, 124),
    (88, 124),
    (88, 124),
    (136, 148),
    (88, 124),
    (148, 132),
    (108, 144),
]


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    source_cell_width = source.width // len(ROLE_SIZES)
    source_cell_height = source.height // 2
    output_width = sum(width for width, _ in ROLE_SIZES)
    output_row_height = max(height for _, height in ROLE_SIZES)
    output = Image.new("RGBA", (output_width, output_row_height * 2))

    for row in range(2):
        output_x = 0
        for column, size in enumerate(ROLE_SIZES):
            crop = source.crop(
                (
                    column * source_cell_width,
                    row * source_cell_height,
                    (column + 1) * source_cell_width,
                    (row + 1) * source_cell_height,
                )
            )
            resized = crop.resize(size, Image.Resampling.LANCZOS)
            output.alpha_composite(resized, (output_x, row * output_row_height))
            output_x += size[0]

    output.save(TARGET, optimize=True)
    print(f"Updated {TARGET.relative_to(ROOT)} ({output.width}x{output.height}).")


if __name__ == "__main__":
    main()
