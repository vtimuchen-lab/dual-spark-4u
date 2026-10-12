#!/usr/bin/env bash
# Экспорт печатных деталей (двоичный STL), рендеров (PNG), чертежей (SVG/PNG) и
# шаблонов разметки ФП-5 1:1 (PDF A4) 5U-модуля.
# Требуется OpenSCAD ≥ 2021.01; для PNG без дисплея — xvfb-run; python3 для чертежей.
#
# Правило: деталь экспортируется, когда заполнены все TO_MEASURE, от которых
# она зависит (её .scad собирается без ERROR: Assertion). Деталь с незаполненными
# зависимостями пропускается с сообщением — STL на выдуманных числах не создаётся.
set -euo pipefail
cd "$(dirname "$0")/../scad"
mkdir -p ../stl ../docs/renders

S=$(mktemp -d)
trap 'rm -rf "$S"' EXIT

# export_part <out.stl> <file.scad> [-D ...]
export_part() {
  local out="$1"; shift
  local scad="$1"; shift
  if openscad -o "$S/check.csg" "$@" "$scad" 2>"$S/err.log" && ! grep -q "Assertion" "$S/err.log"; then
    openscad -o "$out" "$@" "$scad" 2>/dev/null
    echo "  OK    $(basename "$out")"
  else
    echo "  SKIP  $(basename "$out"): $(grep -o 'TO_MEASURE[^"]*' "$S/err.log" | head -1)"
  fi
}

echo "== STL =="
rm -f ../stl/*.stl
export_part ../stl/edgexpert_holder.stl edgexpert_holder.scad
export_part ../stl/bypass_baffle_050.stl edgexpert_holder.scad -D 'part="baffle"' -D bypass_block=0.5
export_part ../stl/bypass_baffle_100.stl edgexpert_holder.scad -D 'part="baffle"' -D bypass_block=1.0
export_part ../stl/duct.stl duct.scad
export_part ../stl/duct_sealed_variant.stl duct.scad -D under_feed=false
export_part ../stl/duct_part_a_plenum.stl duct.scad -D duct_split=true -D 'part="duct_a"'
export_part ../stl/duct_part_b_nozzle.stl duct.scad -D duct_split=true -D 'part="duct_b"'
export_part ../stl/panel_bracket_OPTIONAL.stl base_plate.scad -D 'part="panel_bracket"'
export_part ../stl/dc_jack_bracket.stl base_plate.scad -D 'part="dc_jack_bracket"'
export_part ../stl/ctrl_bezel.stl ctrl_bezel.scad
export_part ../stl/fan_bracket_bench_OPTIONAL.stl fan_bracket.scad

echo "== Сборка для просмотра (не для печати) =="
python3 ../scripts/export_assembly_view.py ../stl/assembly_module_VIEW_ONLY.stl module
python3 ../scripts/export_assembly_view.py ../stl/assembly_exploded_VIEW_ONLY.stl exploded

echo "== Тестовый комплект на один тракт, стол ${PRINT_BED:-330x320} (stl/kit) =="
mkdir -p ../stl/kit
export_part ../stl/kit/kit_1_duct_fanstand.stl print_plates.scad -D 'part="kit_1"'
export_part ../stl/kit/kit_2_holder_baffles.stl print_plates.scad -D 'part="kit_2"'

echo "== STL → двоичный (меньше в 4–5 раз, геометрия та же) =="
python3 ../scripts/stl_to_binary.py ../stl/*.stl ../stl/kit/*.stl

echo "== 2D для резки/сверловки (DXF) =="
mkdir -p ../docs/drawings
openscad -o ../docs/drawings/panel_fp5.dxf -D 'part="panel_2d"' front_panel.scad 2>/dev/null && echo "  OK    panel_fp5.dxf"
openscad -o ../docs/drawings/base_plate.dxf -D 'part="base_plate_2d"' base_plate.scad 2>/dev/null && echo "  OK    base_plate.dxf"

echo "== PNG =="
rm -f ../docs/renders/*.png
X=""; command -v xvfb-run >/dev/null && X="xvfb-run -a"
P="--preview --viewall --autocenter --projection=p --colorscheme=Tomorrow"
$X openscad -o ../docs/renders/holder.png $P --imgsize=1400,1000 --camera=0,0,0,55,0,35,600 -D 'part="holder_with_baffle"' edgexpert_holder.scad
$X openscad -o ../docs/renders/holder_with_msi.png $P --imgsize=1400,1000 --camera=0,0,0,60,0,215,600 -D 'part="holder_with_device"' edgexpert_holder.scad
$X openscad -o ../docs/renders/duct.png $P --imgsize=1400,1000 --camera=0,0,0,60,0,215,600 duct.scad
$X openscad -o ../docs/renders/duct_section.png --preview --viewall --autocenter --projection=o --colorscheme=Tomorrow --imgsize=1400,900 --camera=0,0,0,90,0,90,600 -D 'part="duct_section"' duct.scad
$X openscad -o ../docs/renders/panel_bracket.png $P --imgsize=1000,800 --camera=0,0,0,55,0,35,300 -D 'part="panel_bracket"' base_plate.scad
$X openscad -o ../docs/renders/track.png $P --imgsize=1600,1000 --camera=0,0,0,55,0,215,1000 -D 'part="track"' assembly.scad
$X openscad -o ../docs/renders/module.png $P --imgsize=1600,1100 --camera=0,0,0,60,0,205,1600 assembly.scad
$X openscad -o ../docs/renders/module_front.png $P --imgsize=1600,1000 --camera=0,0,0,75,0,335,1400 assembly.scad
$X openscad -o ../docs/renders/module_top.png --preview --viewall --autocenter --projection=o --colorscheme=Tomorrow --imgsize=1600,1100 --camera=0,0,0,0,0,0,1400 assembly.scad
$X openscad -o ../docs/renders/exploded.png $P --imgsize=1600,1000 --camera=0,0,0,55,0,215,1600 -D 'part="exploded"' assembly.scad
if openscad -o "$S/b.csg" ctrl_bezel.scad 2>"$S/b.log" && ! grep -q "Assertion" "$S/b.log"; then
  $X openscad -o ../docs/renders/ctrl_bezel.png $P --imgsize=1000,800 --camera=0,0,0,60,0,200,300 -D 'part="bezel_with_ctrl"' ctrl_bezel.scad
fi

echo "== drawings =="
python3 ../scripts/make_drawings.py
CH=$(command -v chromium || command -v chromium-browser || command -v google-chrome || find /opt/pw-browsers -maxdepth 3 -type f -name chrome 2>/dev/null | head -1 || true)
if [ -n "${CH:-}" ]; then
  for f in ../docs/drawings/*.svg; do
    case "$f" in *fan_template_*) continue ;; esac   # шаблоны 1:1 в мм — только PDF
    W=$(grep -o 'width="[0-9]*"' "$f" | head -1 | tr -dc '0-9'); H=$(grep -o 'height="[0-9]*"' "$f" | head -1 | tr -dc '0-9')
    timeout 60 "$CH" --headless=new --no-sandbox --disable-gpu --hide-scrollbars --window-size="$W,$H" --screenshot="${f%.svg}.png" "file://$(readlink -f "$f")" >/dev/null 2>&1 || true
  done
  # шаблоны разметки вырезов ФП-5, 1:1 на A4 → один PDF (печать 100 %)
  {
    echo '<!doctype html><meta charset="utf-8"><style>@page{size:A4;margin:0}html,body{margin:0}'
    echo 'img{display:block;width:210mm;height:297mm;break-after:page}img:last-child{break-after:auto}</style>'
    for f in ../docs/drawings/fan_template_FAN*.svg; do echo "<img src=\"file://$(readlink -f "$f")\">"; done
  } > "$S/fan_template.html"
  timeout 60 "$CH" --headless=new --no-sandbox --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$(readlink -f ../docs/drawings)/fan_template_fp5_A4.pdf" "file://$S/fan_template.html" >/dev/null 2>&1 \
    && echo "  OK    fan_template_fp5_A4.pdf" || echo "  FAIL  fan_template_fp5_A4.pdf"
fi
echo "done"
