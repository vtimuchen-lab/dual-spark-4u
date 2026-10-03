#!/usr/bin/env bash
# Экспорт всех печатных деталей (STL) и обзорных рендеров (PNG).
# Требуется OpenSCAD ≥ 2021.01; для PNG без дисплея — xvfb-run.
set -euo pipefail
cd "$(dirname "$0")/../scad"
mkdir -p ../stl ../docs/renders

echo "== STL =="
openscad -o ../stl/edgexpert_holder.stl edgexpert_holder.scad
openscad -o ../stl/fan_bracket.stl fan_bracket.scad
openscad -o ../stl/duct.stl duct.scad
openscad -o ../stl/duct_part_a_plenum.stl -D 'duct_split=true' -D 'part="duct_a"' duct.scad
openscad -o ../stl/duct_part_b_nozzle.stl -D 'duct_split=true' -D 'part="duct_b"' duct.scad

echo "== PNG =="
X=""; command -v xvfb-run >/dev/null && X="xvfb-run -a"
P="--preview --viewall --autocenter --projection=p --colorscheme=Tomorrow"
$X openscad -o ../docs/renders/holder_preview.png $P --imgsize=1400,1000 --camera=0,0,0,55,0,35,500 edgexpert_holder.scad
$X openscad -o ../docs/renders/duct_preview.png $P --imgsize=1400,1000 --camera=0,0,0,60,0,215,500 duct.scad
$X openscad -o ../docs/renders/duct_section_preview.png $P --imgsize=1400,1000 --camera=0,0,0,60,0,210,500 -D 'part="duct_section"' duct.scad
$X openscad -o ../docs/renders/track_preview.png $P --imgsize=1600,1000 --camera=0,0,0,55,0,215,900 -D 'part="track"' assembly.scad
$X openscad -o ../docs/renders/exploded_preview.png $P --imgsize=1600,1000 --camera=0,0,0,55,0,215,1200 -D 'part="exploded"' assembly.scad
$X openscad -o ../docs/renders/assembly_preview.png $P --imgsize=1600,1100 --camera=0,0,0,50,0,200,1400 assembly.scad
$X openscad -o ../docs/renders/assembly_top.png --preview --viewall --autocenter --projection=o --colorscheme=Tomorrow --imgsize=1600,1100 --camera=0,0,0,0,0,0,1400 assembly.scad

echo "== drawings =="
python3 ../scripts/make_drawings.py
echo "done"
