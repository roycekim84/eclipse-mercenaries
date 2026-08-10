#!/usr/bin/env bash
set -euo pipefail

export SOURCE_DATE_EPOCH=315532800

font_build_dir="$(mktemp -d)"
trap 'rm -r "$font_build_dir"' EXIT

google_fonts_revision="2d85e20401920891efb7cd6272d6339685df2820"
google_fonts_raw="https://raw.githubusercontent.com/google/fonts/${google_fonts_revision}/ofl"

python3 -m pip install --quiet --target "$font_build_dir/python" fonttools brotli
curl -L --fail --silent --show-error \
  "$google_fonts_raw/notosanskr/NotoSansKR%5Bwght%5D.ttf" \
  -o "$font_build_dir/NotoSansKR.ttf"
rg --no-filename -o '[가-힣]+' lib test > "$font_build_dir/korean-text.txt"

for font_weight in Regular Bold; do
  if [[ "$font_weight" == "Regular" ]]; then
    weight_value=400
  else
    weight_value=700
  fi
  PYTHONPATH="$font_build_dir/python" python3 -m fontTools.varLib.instancer \
    "$font_build_dir/NotoSansKR.ttf" "wght=$weight_value" \
    --output "$font_build_dir/NotoSansKR-$font_weight-full.ttf"
  PYTHONPATH="$font_build_dir/python" python3 -m fontTools.subset \
    "$font_build_dir/NotoSansKR-$font_weight-full.ttf" \
    --output-file="assets/fonts/NotoSansKR-$font_weight.ttf" \
    --text-file="$font_build_dir/korean-text.txt" \
    --unicodes='U+0000-00FF,U+2000-206F' \
    --layout-features='*' --name-IDs='*' --name-legacy \
    --name-languages='*' --notdef-glyph --notdef-outline \
    --recommended-glyphs
done

curl -L --fail --silent --show-error \
  "$google_fonts_raw/notosanskr/OFL.txt" \
  -o assets/fonts/OFL-NotoSansKR.txt
curl -L --fail --silent --show-error \
  "$google_fonts_raw/cinzel/Cinzel%5Bwght%5D.ttf" \
  -o assets/fonts/Cinzel-Variable.ttf
curl -L --fail --silent --show-error \
  "$google_fonts_raw/cinzel/OFL.txt" \
  -o assets/fonts/OFL-Cinzel.txt

echo "Updated deterministic Noto Sans KR and Cinzel font assets."
