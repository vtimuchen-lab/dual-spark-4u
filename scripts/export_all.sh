#!/usr/bin/env bash
# Экспорт печатных деталей (двоичный STL), рендеров (PNG), чертежей (SVG/PNG) и
# шаблонов разметки ФП-5 1:1 (PDF A4) 5U-модуля.
# Требуется OpenSCAD ≥ 2021.01; для PNG без дисплея — xvfb-run; python3 для чертежей.
#
# Правило: деталь экспортируется, когда заполнены все TO_MEASURE, от которых
# она зависит (её .scad собирается без ERROR: Assertion). Деталь с незаполненными
# зависимостями (TO_MEASURE) или ненужная (NOT_NEEDED) пропускается — SKIP с
# причиной. Любая другая ошибка — FAIL, и скрипт в конце выходит с кодом 1.
set -euo pipefail
shopt -s nullglob
cd "$(dirname "$0")/../scad"
mkdir -p ../stl/kit ../docs/renders ../docs/drawings

S=$(mktemp -d)
trap 'rm -rf "$S"' EXIT
fail=0

# причина пропуска или ошибки из лога OpenSCAD
reason() { grep -oE 'TO_MEASURE[^"]*|NOT_NEEDED[^"]*' "$1" | head -1 || true; }
errline() { grep -m1 -E 'ERROR|Assertion' "$1" | cut -c1-200 || true; }

# export_part <out.stl> <file.scad> [-D ...]
export_part() {
  local out="$1"; shift
  local scad="$1"; shift
  local name; name=$(basename "$out")
  if ! openscad -o "$S/check.csg" "$@" "$scad" 2>"$S/err.log" || grep -q "Assertion" "$S/err.log"; then
    local why; why=$(reason "$S/err.log")
    if [ -n "$why" ]; then
      echo "  SKIP  $name: $why"
    else
      echo "  FAIL  $name: $(errline "$S/err.log")"; fail=1
    fi
    return 0
  fi
  if openscad -o "$out" "$@" "$scad" 2>"$S/stl.log"; then
    echo "  OK    $name"
  else
    echo "  FAIL  $name: $(errline "$S/stl.log")"; fail=1
  fi
}

# export_2d <out.dxf> <file.scad> [-D ...]
export_2d() {
  local out="$1"; shift
  if openscad -o "$out" "$@" 2>"$S/2d.log" && ! grep -q "Assertion" "$S/2d.log"; then
    echo "  OK    $(basename "$out")"
  else
    echo "  FAIL  $(basename "$out"): $(errline "$S/2d.log")"; fail=1
  fi
}

X=""; command -v xvfb-run >/dev/null && X="xvfb-run -a"
P="--preview --viewall --autocenter --projection=p --colorscheme=Tomorrow"
# render <out.png> <openscad args...>
render() {
  local out="$1"; shift
  if ! $X openscad -o "$out" "$@" >/dev/null 2>"$S/png.log"; then
    echo "  FAIL  $(basename "$out"): $(errline "$S/png.log")"; fail=1
  fi
}

echo "== STL =="
rm -f ../stl/*.stl ../stl/kit/*.stl
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
python3 ../scripts/export_assembly_view.py ../stl/assembly_module_VIEW_ONLY.stl module || fail=1
python3 ../scripts/export_assembly_view.py ../stl/assembly_exploded_VIEW_ONLY.stl exploded || fail=1

echo "== Тестовый комплект на один тракт, стол print_bed_x × print_bed_y из params.scad (stl/kit) =="
export_part ../stl/kit/kit_1_duct_fanstand.stl print_plates.scad -D 'part="kit_1"'
export_part ../stl/kit/kit_2_holder_baffles.stl print_plates.scad -D 'part="kit_2"'

echo "== STL → двоичный (меньше в 4–5 раз, геометрия та же, порядок граней постоянный) =="
python3 ../scripts/stl_to_binary.py ../stl/*.stl ../stl/kit/*.stl || fail=1

echo "== 2D для резки/сверловки (DXF) =="
export_2d ../docs/drawings/panel_fp5.dxf -D 'part="panel_2d"' front_panel.scad
# без плиты (use_base_plate = false) — разметка полки shelf_drill.dxf, с плитой — base_plate.dxf
PLATE=base_plate; grep -qE '^use_base_plate *= *false' params.scad && PLATE=shelf_drill
rm -f ../docs/drawings/base_plate.dxf ../docs/drawings/shelf_drill.dxf
export_2d ../docs/drawings/$PLATE.dxf -D 'part="base_plate_2d"' base_plate.scad

echo "== PNG =="
rm -f ../docs/renders/*.png
render ../docs/renders/holder.png $P --imgsize=1400,1000 --camera=0,0,0,55,0,35,600 -D 'part="holder_with_baffle"' edgexpert_holder.scad
render ../docs/renders/holder_with_msi.png $P --imgsize=1400,1000 --camera=0,0,0,60,0,215,600 -D 'part="holder_with_device"' edgexpert_holder.scad
render ../docs/renders/duct.png $P --imgsize=1400,1000 --camera=0,0,0,60,0,215,600 duct.scad
render ../docs/renders/duct_section.png --preview --viewall --autocenter --projection=o --colorscheme=Tomorrow --imgsize=1400,900 --camera=0,0,0,90,0,90,600 -D 'part="duct_section"' duct.scad
render ../docs/renders/panel_bracket.png $P --imgsize=1000,800 --camera=0,0,0,55,0,35,300 -D 'part="panel_bracket"' base_plate.scad
render ../docs/renders/track.png $P --imgsize=1600,1000 --camera=0,0,0,55,0,215,1000 -D 'part="track"' assembly.scad
render ../docs/renders/module.png $P --imgsize=1600,1100 --camera=0,0,0,60,0,205,1600 assembly.scad
render ../docs/renders/module_front.png $P --imgsize=1600,1000 --camera=0,0,0,75,0,335,1400 assembly.scad
render ../docs/renders/module_top.png --preview --viewall --autocenter --projection=o --colorscheme=Tomorrow --imgsize=1600,1100 --camera=0,0,0,0,0,0,1400 assembly.scad
render ../docs/renders/exploded.png $P --imgsize=1600,1000 --camera=0,0,0,55,0,215,1600 -D 'part="exploded"' assembly.scad
if openscad -o "$S/b.csg" ctrl_bezel.scad 2>"$S/b.log" && ! grep -q "Assertion" "$S/b.log"; then
  render ../docs/renders/ctrl_bezel.png $P --imgsize=1000,800 --camera=0,0,0,60,0,200,300 -D 'part="bezel_with_ctrl"' ctrl_bezel.scad
fi

echo "== drawings =="
python3 ../scripts/make_drawings.py || fail=1
CH=$(command -v chromium || command -v chromium-browser || command -v google-chrome || find /opt/pw-browsers -maxdepth 3 -type f -name chrome 2>/dev/null | head -1 || true)
if [ -n "${CH:-}" ]; then
  for f in ../docs/drawings/*.svg; do
    case "$f" in *fan_template_*) continue ;; esac   # шаблоны 1:1 в мм — только PDF
    W=$(grep -o 'width="[0-9]*"' "$f" | head -1 | tr -dc '0-9'); H=$(grep -o 'height="[0-9]*"' "$f" | head -1 | tr -dc '0-9')
    timeout 60 "$CH" --headless=new --no-sandbox --disable-gpu --hide-scrollbars --window-size="$W,$H" \
      --screenshot="${f%.svg}.png" "file://$(readlink -f "$f")" >/dev/null 2>&1 \
      || { echo "  FAIL  $(basename "${f%.svg}.png")"; fail=1; }
  done
  # шаблоны разметки вырезов ФП-5, 1:1 на A4 → один PDF (печать 100 %)
  {
    echo '<!doctype html><meta charset="utf-8"><style>@page{size:A4;margin:0}html,body{margin:0}'
    echo 'img{display:block;width:210mm;height:297mm;break-after:page}img:last-child{break-after:auto}</style>'
    for f in ../docs/drawings/fan_template_FAN*.svg; do echo "<img src=\"file://$(readlink -f "$f")\">"; done
  } > "$S/fan_template.html"
  PDF="$(readlink -f ../docs/drawings)/fan_template_fp5_A4.pdf"
  if timeout 60 "$CH" --headless=new --no-sandbox --disable-gpu --no-pdf-header-footer \
       --print-to-pdf="$PDF" "file://$S/fan_template.html" >/dev/null 2>&1; then
    # постоянная дата той же длины (смещения xref не меняются): PDF меняется только вместе с чертежом
    python3 -c 'import re,sys; p=sys.argv[1]; d=open(p,"rb").read(); open(p,"wb").write(re.sub(rb"D:\d{14}", b"D:20260101000000", d))' "$PDF"
    echo "  OK    fan_template_fp5_A4.pdf"
  else
    echo "  FAIL  fan_template_fp5_A4.pdf"; fail=1
  fi
else
  echo "  SKIP  PNG чертежей и PDF шаблона: Chromium не найден — файлы в docs/drawings не обновлены"
fi

if [ "$fail" -ne 0 ]; then
  echo "done с ошибками (FAIL выше)"; exit 1
fi
echo "done"
