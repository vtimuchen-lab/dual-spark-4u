#!/usr/bin/env python3
"""Сборка 5U-модуля одним STL для просмотра (GitHub, любой 3D-просмотрщик).

OpenSCAD 2021 сливает все объекты сборки в одно тело (CGAL) — это долго.
Скрипт экспортирует группы деталей по отдельности (assembly.scad, параметр
`only`) и склеивает треугольники в один ASCII STL (export_all.sh затем
переводит его в двоичный, scripts/stl_to_binary.py). Детали не объединены,
файл только для просмотра — для печати используйте stl/*.stl по деталям.
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCAD = ROOT / "scad" / "assembly.scad"
GROUPS = ["panel", "grilles", "plate", "brackets", "holders", "baffles", "ducts", "msi", "fans", "bezels"]


def main(out: Path, part: str = "module") -> int:
    facets: list[str] = []
    failed = 0
    with tempfile.TemporaryDirectory() as tmp:
        for g in GROUPS:
            stl = Path(tmp) / f"{g}.stl"
            r = subprocess.run(["openscad", "-o", str(stl), "-D", f'only="{g}"', "-D", f'part="{part}"', str(SCAD)],
                               capture_output=True, text=True)
            if r.returncode != 0 or not stl.exists():
                err = r.stderr
                if "top level object is empty" in err and "Assertion" not in err and "ERROR" not in err.replace(
                        "Current top level object is empty", ""):
                    print(f"  -     {g}: пусто (нет деталей группы при текущих параметрах)")
                else:
                    line = next((ln for ln in err.splitlines() if "ERROR" in ln or "Assertion" in ln), err.strip()[-200:])
                    print(f"  FAIL  {g}: {line[:200]}")
                    failed += 1
                continue
            body = [ln for ln in stl.read_text().splitlines()
                    if not ln.startswith("solid") and not ln.startswith("endsolid")]
            n = sum(1 for ln in body if ln.strip().startswith("facet"))
            facets.extend(body)
            print(f"  OK    {g}: {n} треугольников")
    out.write_text("solid dual_spark_5u_module_VIEW_ONLY\n" + "\n".join(facets) +
                   "\nendsolid dual_spark_5u_module_VIEW_ONLY\n")
    print(f"written {out}")
    return 1 if failed else 0


if __name__ == "__main__":
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "stl" / "assembly_module_VIEW_ONLY.stl"
    part = sys.argv[2] if len(sys.argv) > 2 else "module"
    sys.exit(main(out, part))
