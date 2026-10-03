#!/usr/bin/env bash
# Экспорт печатных деталей (STL) и обзорных рендеров (PNG) 5U-модуля.
# Требуется OpenSCAD ≥ 2021.01; для PNG без дисплея — xvfb-run; python3 для чертежей.
#
# Пока в scad/params.scad есть TO_MEASURE (undef), все STL/PNG помечаются PREVIEW.
# Сборка модуля при undef не собирается (assert) — для PREVIEW-рендеров сборки
# ниже передаются ПОДСТАНОВОЧНЫЕ значения (не измерения!). Они видны в имени
# файла и в docs/02_layout.md. После замеров: заполнить params.scad, убрать
# PREVIEW_RACK_ARGS и запустить скрипт без аргументов.
set -euo pipefail
cd "$(dirname "$0")/../scad"
mkdir -p ../stl ../docs/renders

# Если все rack-параметры измерены — суффикс пустой, иначе _PREVIEW
if openscad -o /dev/null -D 'part="base_plate_2d"' base_plate.scad >/dev/null 2>&1; then
  SUF=""; PREVIEW_RACK_ARGS=()
  echo "rack parameters present → final names"
else
  SUF="_PREVIEW"
  PREVIEW_RACK_ARGS=(-D rack_opening_w=450.85 -D shelf_top_z=25 -D shelf_depth=400 -D panel_t=1.2 -D panel_hole_pitch_v=31.75)
  echo "TO_MEASURE present → PREVIEW names; assembly renders use placeholders: ${PREVIEW_RACK_ARGS[*]}"
fi

echo "== STL =="
rm -f ../stl/*.stl
openscad -o "../stl/edgexpert_holder${SUF}.stl" edgexpert_holder.scad
openscad -o "../stl/bypass_baffle_050${SUF}.stl" -D 'part="baffle"' -D bypass_block=0.5 edgexpert_holder.scad
openscad -o "../stl/bypass_baffle_100${SUF}.stl" -D 'part="baffle"' -D bypass_block=1.0 edgexpert_holder.scad
openscad -o "../stl/duct${SUF}.stl" duct.scad
openscad -o "../stl/duct_part_a_plenum${SUF}.stl" -D 'duct_split=true' -D 'part="duct_a"' duct.scad
openscad -o "../stl/duct_part_b_nozzle${SUF}.stl" -D 'duct_split=true' -D 'part="duct_b"' duct.scad
openscad -o "../stl/panel_bracket${SUF}.stl" -D 'part="panel_bracket"' base_plate.scad
openscad -o "../stl/dc_jack_bracket${SUF}.stl" -D 'part="dc_jack_bracket"' base_plate.scad
openscad -o "../stl/fan_bracket_bench_OPTIONAL${SUF}.stl" fan_bracket.scad

echo "== PNG =="
rm -f ../docs/renders/*.png
X=""; command -v xvfb-run >/dev/null && X="xvfb-run -a"
P="--preview --viewall --autocenter --projection=p --colorscheme=Tomorrow"
$X openscad -o "../docs/renders/holder${SUF}.png" $P --imgsize=1400,1000 --camera=0,0,0,55,0,215,500 -D 'part="holder_with_baffle"' edgexpert_holder.scad
$X openscad -o "../docs/renders/duct${SUF}.png" $P --imgsize=1400,1000 --camera=0,0,0,60,0,215,500 duct.scad
$X openscad -o "../docs/renders/duct_section${SUF}.png" $P --imgsize=1400,1000 --camera=0,0,0,60,0,210,500 -D 'part="duct_section"' duct.scad
$X openscad -o "../docs/renders/panel_bracket${SUF}.png" $P --imgsize=1000,800 --camera=0,0,0,55,0,35,300 -D 'part="panel_bracket"' base_plate.scad
$X openscad -o "../docs/renders/track${SUF}.png" $P --imgsize=1600,1000 --camera=0,0,0,55,0,215,900 -D 'part="track"' assembly.scad
$X openscad -o "../docs/renders/module${SUF}.png" $P --imgsize=1600,1100 --camera=0,0,0,60,0,205,1500 "${PREVIEW_RACK_ARGS[@]}" assembly.scad
$X openscad -o "../docs/renders/module_front${SUF}.png" $P --imgsize=1600,1000 --camera=0,0,0,90,0,180,1300 "${PREVIEW_RACK_ARGS[@]}" assembly.scad
$X openscad -o "../docs/renders/module_top${SUF}.png" --preview --viewall --autocenter --projection=o --colorscheme=Tomorrow --imgsize=1600,1100 --camera=0,0,0,0,0,0,1400 "${PREVIEW_RACK_ARGS[@]}" assembly.scad
$X openscad -o "../docs/renders/exploded${SUF}.png" $P --imgsize=1600,1000 --camera=0,0,0,55,0,215,1500 -D 'part="exploded"' "${PREVIEW_RACK_ARGS[@]}" assembly.scad

echo "== drawings =="
python3 ../scripts/make_drawings.py
# растр SVG → PNG (headless Chromium, если есть; иначе остаются только SVG)
CH=$(command -v chromium || command -v chromium-browser || command -v google-chrome || find /opt/pw-browsers -maxdepth 3 -type f -name chrome 2>/dev/null | head -1 || true)
if [ -n "${CH:-}" ]; then
  for f in ../docs/drawings/*.svg; do
    W=$(grep -o 'width="[0-9]*"' "$f" | head -1 | tr -dc '0-9'); H=$(grep -o 'height="[0-9]*"' "$f" | head -1 | tr -dc '0-9')
    timeout 60 "$CH" --headless=new --no-sandbox --disable-gpu --hide-scrollbars --window-size="$W,$H" --screenshot="${f%.svg}.png" "file://$(readlink -f "$f")" >/dev/null 2>&1 || true
  done
fi
echo "done (suffix '${SUF}')"
