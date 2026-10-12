#!/usr/bin/env python3
"""Перевод ASCII STL (OpenSCAD 2021.01 пишет только ASCII) в двоичный STL на месте.

Двоичный STL в 4–5 раз меньше: быстрее открывается в слайсере и в 3D-просмотре
GitHub (в том числе с телефона). Геометрия не меняется: те же треугольники и
нормали. Уже двоичные файлы пропускаются.

  python3 scripts/stl_to_binary.py stl/*.stl stl/kit/*.stl
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path


def is_binary(data: bytes) -> bool:
    if len(data) < 84:
        return False
    n = struct.unpack_from("<I", data, 80)[0]
    return len(data) == 84 + 50 * n


def convert(path: Path) -> None:
    data = path.read_bytes()
    if is_binary(data):
        print(f"  -     {path.name}: уже двоичный")
        return
    tris: list[tuple[float, ...]] = []
    normal: list[float] = []
    verts: list[float] = []
    for line in data.decode("ascii", errors="replace").splitlines():
        w = line.split()
        if not w:
            continue
        if w[0] == "facet":
            normal = [float(v) for v in w[2:5]]
            verts = []
        elif w[0] == "vertex":
            verts.extend(float(v) for v in w[1:4])
        elif w[0] == "endfacet":
            if len(verts) != 9:
                raise ValueError(f"{path}: грань не из 3 вершин")
            tris.append((*normal, *verts))
    header = f"{path.stem} (binary, from OpenSCAD ASCII)".encode("ascii", errors="replace")[:80].ljust(80, b" ")
    out = bytearray(header + struct.pack("<I", len(tris)))
    for t in tris:
        out += struct.pack("<12fH", *t, 0)
    path.write_bytes(bytes(out))
    print(f"  OK    {path.name}: {len(tris)} треугольников, {len(data) // 1024} → {len(out) // 1024} КБ")


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        convert(Path(arg))
