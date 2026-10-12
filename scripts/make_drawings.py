#!/usr/bin/env python3
"""Чертежи 5U-модуля из scad/params.scad.

Исходные параметры читаются из params.scad, производные — из OpenSCAD
(scad/derived.scad → export_derived()), поэтому чертёж всегда совпадает с моделью.

  docs/drawings/panel_fp5.svg        — разметка ФП-5 (вид снаружи), размеры от краёв
  docs/drawings/panel_fp5_holes.csv  — координаты центров (от левого и нижнего края)
  docs/drawings/base_plate.svg       — сверловка base_plate (вид сверху)
  docs/drawings/base_plate_holes.csv — координаты центров (от левого и переднего края)
  docs/drawings/side_view.svg        — продольная цепочка трака
  docs/drawings/top_view.svg         — модуль сверху
  docs/drawings/fan_template_FAN*.svg — шаблоны разметки вырезов ФП-5 1:1 на A4
"""
from __future__ import annotations

import ast
import csv
import re
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCAD = ROOT / "scad"
OUT = ROOT / "docs" / "drawings"


# ---------------------------------------------------------------------------
def load_params() -> dict:
    p: dict = {}
    rx = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([-0-9.]+|true|false|undef|\"[^\"]*\")\s*;")
    for line in (SCAD / "params.scad").read_text(encoding="utf-8").splitlines():
        m = rx.match(line)
        if not m:
            continue
        k, v = m.group(1), m.group(2)
        p[k] = None if v == "undef" else (v == "true") if v in ("true", "false") else v.strip('"') if v.startswith('"') else float(v)
    return p


def parse_value(s: str):
    s = s.strip()
    if s == "undef":
        return None
    if s in ("true", "false"):
        return s == "true"
    try:
        return ast.literal_eval(s)
    except (ValueError, SyntaxError):
        return s


def load_derived() -> dict:
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "d.echo"
        subprocess.run(["openscad", "-o", str(out), str(SCAD / "derived.scad")],
                       check=True, capture_output=True)
        d = {}
        for line in out.read_text(encoding="utf-8").splitlines():
            m = re.match(r'ECHO: "DERIVED\|([^|]+)\|(.*)"$', line)
            if m:
                d[m.group(1)] = parse_value(m.group(2))
    return d


def fmt(v, nd=1):
    if v is None:
        return "TO_MEASURE"
    r = round(v, nd)
    return f"{r:g}"


# ---------------------------------------------------------------------------
class Svg:
    def __init__(self, w_mm, h_mm, title, scale=2.0, margin=80, extra_top=30, extra_bottom=70):
        self.S, self.m = scale, margin
        self.W = w_mm * scale + 2 * margin
        self.H = h_mm * scale + 2 * margin + extra_top + extra_bottom
        self.h_mm = h_mm
        self.y_off = margin + extra_top
        self.parts = [f'<text x="{margin}" y="{margin - 30}" font-size="18" font-family="sans-serif" font-weight="bold">{title}</text>']

    def X(self, x): return self.m + x * self.S
    def Y(self, y): return self.y_off + (self.h_mm - y) * self.S

    def rect(self, x, y, w, h, stroke="#222", fill="none", dash=None, sw=1.2):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.parts.append(f'<rect x="{self.X(x):.1f}" y="{self.Y(y + h):.1f}" width="{w * self.S:.1f}" height="{h * self.S:.1f}" stroke="{stroke}" fill="{fill}" stroke-width="{sw}"{d}/>')

    def poly(self, pts, stroke="#222", fill="none", sw=1.2, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        s = " ".join(f"{self.X(x):.1f},{self.Y(y):.1f}" for x, y in pts)
        self.parts.append(f'<polygon points="{s}" stroke="{stroke}" fill="{fill}" stroke-width="{sw}"{d}/>')

    def line(self, x1, y1, x2, y2, stroke="#222", sw=1, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.parts.append(f'<line x1="{self.X(x1):.1f}" y1="{self.Y(y1):.1f}" x2="{self.X(x2):.1f}" y2="{self.Y(y2):.1f}" stroke="{stroke}" stroke-width="{sw}"{d}/>')

    def circle(self, x, y, r, stroke="#222", fill="none", sw=1.2, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.parts.append(f'<circle cx="{self.X(x):.1f}" cy="{self.Y(y):.1f}" r="{r * self.S:.1f}" stroke="{stroke}" fill="{fill}" stroke-width="{sw}"{d}/>')

    def cross(self, x, y, r, sw=0.5):
        self.line(x - r, y, x + r, y, sw=sw); self.line(x, y - r, x, y + r, sw=sw)

    def text(self, x, y, s, size=11, anchor="start", color="#111", rotate=None, bold=False):
        tr = f' transform="rotate({rotate} {self.X(x):.1f} {self.Y(y):.1f})"' if rotate else ""
        fw = ' font-weight="bold"' if bold else ""
        self.parts.append(f'<text x="{self.X(x):.1f}" y="{self.Y(y):.1f}" font-size="{size}" font-family="sans-serif" text-anchor="{anchor}" fill="{color}"{tr}{fw}>{s}</text>')

    def dim_h(self, x1, x2, y, label, color="#b00", above=True):
        self.line(x1, y, x2, y, stroke=color, sw=0.8)
        for x in (x1, x2):
            self.line(x, y - 2, x, y + 2, stroke=color, sw=0.8)
        self.text((x1 + x2) / 2, y + (2 if above else -6), label, size=10, anchor="middle", color=color)

    def dim_v(self, y1, y2, x, label, color="#b00"):
        self.line(x, y1, x, y2, stroke=color, sw=0.8)
        for y in (y1, y2):
            self.line(x - 2, y, x + 2, y, stroke=color, sw=0.8)
        self.text(x + 2, (y1 + y2) / 2, label, size=10, anchor="middle", color=color, rotate=-90)

    def save(self, path: Path):
        path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.W:.0f}" height="{self.H:.0f}" viewBox="0 0 {self.W:.0f} {self.H:.0f}">\n<rect width="100%" height="100%" fill="#fff"/>\n' + "\n".join(self.parts) + "\n</svg>\n", encoding="utf-8")


# ---------------------------------------------------------------------------
def draw_panel(p, d):
    pw, ph = p["panel_w"], p["panel_h"]
    axis = d["fan_center_z_panel"]
    s = Svg(pw, ph, "РАЗМЕТКА ФП-5 (вид снаружи). X от левого края, Z от нижнего края, мм",
            scale=2.2, margin=120, extra_bottom=240)
    s.rect(0, 0, pw, ph, stroke="#000", sw=1.8)
    k = p["panel_edge_keepout"]
    s.rect(k, k, pw - 2 * k, ph - 2 * k, stroke="#c66", dash="4,3", sw=0.8)
    s.text(k + 2, k + 3, f"keep-out {k:g} мм (отбортовка {p['panel_fold']:g} внутрь)", size=9, color="#c66")
    ro = p["rack_opening_w"]
    s.line(pw / 2 - ro / 2, 0, pw / 2 - ro / 2, ph, stroke="#999", sw=0.6, dash="2,4")
    s.line(pw / 2 + ro / 2, 0, pw / 2 + ro / 2, ph, stroke="#999", sw=0.6, dash="2,4")
    s.text(pw / 2 + ro / 2 + 1, ph - 6, "проём стоек", size=8, color="#888")
    holes = []
    pmin, pmax = p["fan_hole_pitch_min"], p["fan_hole_pitch_max"]
    pnom = (pmin + pmax) / 2
    for i, cx_rel in enumerate((-d["track_pitch"] / 2, d["track_pitch"] / 2), start=1):
        cx = pw / 2 + cx_rel
        s.circle(cx, axis, p["fan_open_dia"] / 2, stroke="#000", sw=1.4)
        s.cross(cx, axis, 6)
        s.rect(cx - d["in_flange_w"] / 2, axis - d["in_flange_w"] / 2, d["in_flange_w"], d["in_flange_w"], stroke="#06c", dash="3,2", sw=0.8)
        holes.append((f"FAN{i} вырез", cx, axis, f"Ø{p['fan_open_dia']:g}"))
        for sx in (-1, 1):
            for sz in (-1, 1):
                for pt in (pmin, pmax):
                    s.circle(cx + sx * pt / 2, axis + sz * pt / 2, p["fan_hole_dia"] / 2, stroke="#000", sw=0.9)
                hx, hz = cx + sx * pnom / 2, axis + sz * pnom / 2
                holes.append((f"FAN{i} паз M4", hx, hz, f"паз Ø{p['fan_hole_dia']:g}, межцентр. {pmin:g}…{pmax:g}"))
        s.text(cx, axis + 4, f"Ø{p['fan_open_dia']:g}", size=12, anchor="middle", bold=True)
        s.text(cx, axis - 12, f"4 паза M4: Ø{p['fan_hole_dia']:g}, межцентровое {pmin:g}…{pmax:g}", size=9, anchor="middle")
        s.text(cx, axis - 24, f"фланец воздуховода {d['in_flange_w']:g}×{d['in_flange_w']:g} (сзади)", size=9, anchor="middle", color="#06c")
        # полоса под рамку контроллера
        z0 = d["bezel_z0_panel"]
        s.rect(cx - 35, z0, 70, ph - z0, stroke="#070", dash="4,2", sw=0.9)
        if d["ctrl_known"]:
            for sx in (-1, 1):
                hx = cx + sx * d["bezel_lug_dx"]
                s.circle(hx, d["bezel_cz_panel"], p["m3_clear_d"] / 2, stroke="#000", sw=1.1)
                holes.append((f"FAN{i} лапка рамки", hx, d["bezel_cz_panel"], f"Ø{p['m3_clear_d']:g}"))
            chx = cx + (1 if cx_rel > 0 else -1) * p["cable_hole_side"] * d["cable_hole_dx"]
            s.circle(chx, d["bezel_cz_panel"], p["cable_hole_d"] / 2, stroke="#000", sw=1.2)
            holes.append((f"FAN{i} втулка кабелей", chx, d["bezel_cz_panel"], f"Ø{p['cable_hole_d']:g}"))
        else:
            s.text(cx, z0 + (ph - z0) / 2 + 3, f"полоса под рамку {d['strip_above_fan']:g} мм", size=8, anchor="middle", color="#070")
            s.text(cx, z0 + (ph - z0) / 2 - 8, "отверстия — после замера контроллера", size=8, anchor="middle", color="#070")
    # печатные уголки (опция; по умолчанию крепление через штатные отверстия)
    if d["use_panel_brackets"]:
        for sx in (-1, 1):
            for zl in (p["bracket_t"] + 12, p["bracket_h"] - 12):
                x = pw / 2 + sx * d["bracket_cx"]; z = p["shelf_top_z"] + p["base_plate_t"] + zl
                s.circle(x, z, p["bracket_hole_d"] / 2, stroke="#000", sw=1.1); s.cross(x, z, 4)
                holes.append(("уголок M4", x, z, f"Ø{p['bracket_hole_d']:g}"))
    # уши (справочно)
    if p["ear_hole_low"] is not None and p["ear_hole_high"] is not None:
        for sx in (-1, 1):
            for z in (p["ear_hole_low"], p["ear_hole_high"]):
                s.circle(pw / 2 + sx * p["rack_ear_hole_spacing"] / 2, z, 3.5, stroke="#888", dash="2,2")
    # линия полки
    s.line(0, p["shelf_top_z"], pw, p["shelf_top_z"], stroke="#a60", sw=0.8, dash="6,3")
    s.text(pw - 2, p["shelf_top_z"] + 2, f"верх полки {p['shelf_top_z']:g}", size=9, anchor="end", color="#a60")
    s.line(pw / 2, 0, pw / 2, ph, stroke="#06c", sw=0.5, dash="8,4")
    cx1, cx2 = pw / 2 - d["track_pitch"] / 2, pw / 2 + d["track_pitch"] / 2
    s.dim_h(0, cx1, -10, f"{cx1:g}"); s.dim_h(cx1, cx2, -10, f"{d['track_pitch']:g}"); s.dim_h(cx2, pw, -10, f"{pw - cx2:g}")
    if d["use_panel_brackets"]:
        s.dim_h(0, pw / 2 - d["bracket_cx"], -22, f"{pw / 2 - d['bracket_cx']:g} (уголок)")
    s.dim_h(0, pw, -34, f"{pw:g} [SOURCE]")
    xr = pw + 6
    s.dim_v(0, axis, xr, f"ось {axis:g}")
    s.dim_v(0, d["bezel_z0_panel"], xr + 16, f"{d['bezel_z0_panel']:g}")
    s.dim_v(0, ph, xr + 32, f"{ph:g} [SOURCE]")
    s.text(2, -50, f"Ось вырезов = shelf_top_z {p['shelf_top_z']:g} + плита {p['base_plate_t']:g} + {p['fan_axis_above_plate']:g} = {axis:g} (допуск {d['fan_center_z_panel_min']:g}…{d['fan_center_z_panel_max']:g}).", size=10)
    s.text(2, -63, f"Полоса над вентилятором под рамку контроллера: {d['strip_above_fan']:g} мм → плата контроллера по высоте ≤ {d['ctrl_h_max']:g} мм.", size=10, color="#070", bold=True)
    s.text(2, -76, f"Лист + фильтр panel_t = {p['panel_t']:g}; лист отдельно = {fmt(p['panel_sheet_t'])}. Уши без изменений: нижнее/верхнее отверстие {fmt(p['ear_hole_low'])}/{fmt(p['ear_hole_high'])}, шт. {fmt(p['ear_hole_count'], 0)}.", size=10)
    s.text(2, -89, "Координаты всех центров — panel_fp5_holes.csv; контур для резки — panel_fp5.dxf (scripts/export_all.sh).", size=10)
    s.save(OUT / "panel_fp5.svg")
    with open(OUT / "panel_fp5_holes.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(["элемент", "X от левого края, мм", "Z от нижнего края, мм", "размер"])
        for name, x, z, size in holes:
            w.writerow([name, f"{x:.2f}", f"{z:.2f}", size])


def draw_base_plate(p, d):
    bw, bd = d["base_plate_w"], d["base_plate_d"]
    y0 = d["base_plate_y0"]
    s = Svg(bw, bd, f"BASE_PLATE {bw:g} × {bd:g} × {p['base_plate_t']:g} Al — сверловка (вид сверху, перед внизу)",
            scale=1.8, margin=110, extra_bottom=110)
    def X(xm): return bw / 2 + xm
    def Y(ym): return ym - y0
    s.rect(0, 0, bw, bd, stroke="#000", sw=1.8)
    s.line(bw / 2, 0, bw / 2, bd, stroke="#06c", sw=0.6, dash="8,4")
    holes = []
    for cx_rel in (-d["track_pitch"] / 2, d["track_pitch"] / 2):
        hx0 = X(cx_rel - d["track_cx"])
        s.rect(hx0, Y(d["y_duct_out"]), d["holder_outer_w"], d["holder_depth"], stroke="#888", dash="3,2", sw=0.8)
        s.rect(X(cx_rel) - d["in_flange_w"] / 2, Y(0), d["in_flange_w"], d["y_duct_out"] - y0, stroke="#aaa", dash="2,2", sw=0.6)
        s.text(X(cx_rel), Y(d["y_duct_out"] + 100), "holder (контур)", size=9, anchor="middle", color="#888")
        s.text(X(cx_rel), Y(d["y_duct_out"] / 2), "воздуховод (контур)", size=9, anchor="middle", color="#aaa")
    for (xm, ym) in d["plate_holder_holes"]:
        s.circle(X(xm), Y(ym), p["m4_clear_d"] / 2, stroke="#000", sw=1.2); s.cross(X(xm), Y(ym), 4)
        holes.append(("holder M4", X(xm), Y(ym), f"Ø{p['m4_clear_d']:g}"))
    for (xm, ym) in d["plate_bracket_holes"]:
        s.circle(X(xm), Y(ym), p["m4_clear_d"] / 2, stroke="#000", sw=1.2); s.cross(X(xm), Y(ym), 4)
        holes.append(("уголок M4", X(xm), Y(ym), f"Ø{p['m4_clear_d']:g}"))
    for (xm, ym) in d["plate_ctrl_holes"]:
        s.circle(X(xm), Y(ym), p["m3_clear_d"] / 2, stroke="#000", sw=1.0); s.cross(X(xm), Y(ym), 3)
        holes.append(("полоса M3 (WAGO / стяжки)", X(xm), Y(ym), f"Ø{p['m3_clear_d']:g}"))
    for (xm, ym) in d["plate_dc_holes"]:
        s.circle(X(xm), Y(ym), p["m3_clear_d"] / 2, stroke="#000", sw=1.0)
        holes.append(("площадка стяжки DC-гнезда M3" if p.get("dc_jack_inline") else "стойка DC M3", X(xm), Y(ym), f"Ø{p['m3_clear_d']:g}"))
    for sx in (-1, 1):
        if d["use_panel_brackets"]:
            bx = X(sx * d["bracket_cx"])
            s.rect(bx - p["bracket_w"] / 2, 0, p["bracket_w"], p["bracket_d"], stroke="#555", dash="3,2", sw=0.8)
        xin = X(sx * d["ctrl_zone_x_in"]); xa = min(xin, xin + sx * d["ctrl_zone_w"])
        s.rect(xa, Y(d["ctrl_zone_y0"]), d["ctrl_zone_w"], d["ctrl_zone_d"], stroke="#2a2", dash="3,2", sw=0.8)
        s.text(xa + d["ctrl_zone_w"] / 2, Y(d["ctrl_zone_y1"]) + 3, "резерв" if sx < 0 else "DC + WAGO", size=9, anchor="middle", color="#2a2")
    # размеры по одному отверстию каждого типа
    hx, hy = d["plate_holder_holes"][0]
    s.dim_h(0, X(hx), -10, f"{X(hx):g}")
    s.dim_v(0, Y(hy), -6, f"{Y(hy):g}")
    s.dim_h(0, bw, -24, f"{bw:g} = проём {p['rack_opening_w']:g} − 2×{p['base_plate_side_gap']:g}")
    s.dim_v(0, bd, bw + 6, f"{bd:g} (полка {p['shelf_depth']:g} − {y0:g})")
    s.text(2, -40, f"Передний край плиты — на {y0:g} мм за задней плоскостью панели. M4: Ø{p['m4_clear_d']:g} ({len(d['plate_holder_holes']) + len(d['plate_bracket_holes'])} шт.), M3: Ø{p['m3_clear_d']:g} ({len(d['plate_ctrl_holes']) + len(d['plate_dc_holes'])} шт.).", size=10)
    s.text(2, -53, "X — от левого края, Y — от переднего края. Координаты всех центров — base_plate_holes.csv; контур — base_plate.dxf.", size=10)
    s.save(OUT / "base_plate.svg")
    with open(OUT / "base_plate_holes.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(["элемент", "X от левого края, мм", "Y от переднего края, мм", "размер"])
        for name, x, y, size in holes:
            w.writerow([name, f"{x:.2f}", f"{y:.2f}", size])


def draw_side(p, d):
    L = d["y_track_end"] + 20
    H = p["panel_h"] - p["shelf_top_z"] + 10
    s = Svg(L + 30, H, "ВИД СБОКУ — один трак (Y: глубина от задней плоскости панели, Z: над полкой). Размеры в мм", scale=1.9, extra_bottom=90)
    ox = 30
    def X(y): return ox + y
    pt, zp = p["panel_t"], p["base_plate_t"]
    s.rect(X(0), 0, d["base_plate_d"], zp, fill="#ccc")
    s.rect(X(-pt), -p["shelf_top_z"] if p["shelf_top_z"] < 0 else 0, pt, p["panel_h"] - p["shelf_top_z"], fill="#bbb")
    s.rect(X(-pt - p["grille_depth"]), d["fan_center_z"] - p["fan_size"] / 2, p["grille_depth"], p["fan_size"], fill="#777")
    fz0 = d["fan_center_z"] - p["fan_size"] / 2
    s.rect(X(0), fz0, p["fan_thickness"], p["fan_size"], fill="#9cf")
    s.text(X(p["fan_thickness"] / 2), d["fan_center_z"], "FAN", size=9, anchor="middle")
    if d["ctrl_known"]:
        s.rect(X(-pt - d["bezel_d"]), d["bezel_z0_panel"] - p["shelf_top_z"], d["bezel_d"], d["bezel_h"], fill="#cfc", stroke="#070")
    else:
        s.rect(X(-pt - 20), d["bezel_z0_panel"] - p["shelf_top_z"], 20, d["strip_above_fan"], stroke="#070", dash="3,2")
        s.text(X(-pt - 22), d["bezel_z0_panel"] - p["shelf_top_z"] + 10, f"рамка ≤ {d['strip_above_fan']:g}", size=8, anchor="end", color="#070")
    yi, yo = X(d["y_duct_in"]), X(d["y_duct_out"])
    yn0, yn1 = yi + p["plenum_len"], yo - p["duct_flange_t"]
    top0, bot0 = zp + d["fan_center_zl"] + d["inlet_h"] / 2 + p["duct_wall"], zp + d["fan_center_zl"] - d["inlet_h"] / 2 - p["duct_wall"]
    top1, bot1 = zp + d["outlet_z1"] + p["duct_wall"], zp + d["outlet_z0"] - p["duct_wall"]
    n = 30
    pts_top, pts_bot = [(yi, top0), (yn0, top0)], [(yi, bot0), (yn0, bot0)]
    for i in range(1, n + 1):
        t = i / n; u = t * t * (3 - 2 * t); y = yn0 + (yn1 - yn0) * t
        pts_top.append((y, top0 + (top1 - top0) * u)); pts_bot.append((y, bot0 + (bot1 - bot0) * u))
    s.poly(pts_top + [(yo, top1), (yo, bot1)] + list(reversed(pts_bot)), fill="#eef")
    s.text(yi + 8, d["fan_center_z"], "plenum", size=9); s.text(yn0 + 30, d["fan_center_z"] + 20, "nozzle", size=9)
    s.rect(yo - p["duct_flange_t"], zp, p["duct_flange_t"], d["out_flange_z1"], fill="#ddd")
    # holder
    hy0 = yo
    s.rect(hy0, zp, d["holder_depth"], p["holder_floor_t"], fill="#bbb")
    s.rect(hy0, zp, p["front_post_len"], d["post_top_z"], fill="#bbb")
    s.rect(hy0 + p["front_post_len"], zp, d["holder_depth"] - p["front_post_len"], d["guide_top_z"], fill="none", stroke="#999", dash="2,2")
    for fy in d["foot_ys"]:
        s.rect(hy0 + fy - p["pedestal_size"] / 2, zp, p["pedestal_size"], d["pedestal_top_zl"], fill="#999")
    s.text(hy0 + d["foot_ys"][0], zp + d["pedestal_top_zl"] / 2, "опора", size=8, anchor="middle", rotate=-90)
    s.rect(hy0 + d["baffle_y_local"], zp + p["holder_floor_t"], p["baffle_t"], d["baffle_h"], fill="#f93", stroke="#c60")
    s.text(hy0 + d["baffle_y_local"] + 6, zp + p["holder_floor_t"] + d["baffle_h"] + 3, f"заслонка {p['bypass_block']:g}", size=8, color="#c60")
    # MSI
    dy = X(d["y_device_front"]); db = zp + d["device_base_zl"]
    s.rect(dy, db, p["device_depth"], p["device_height"], fill="#444")
    s.rect(dy - 0.8, db + p["honeycomb_z0"], 0.8, p["honeycomb_h"], fill="#39f", stroke="#39f")
    exz = db + p["device_height"] - p["rear_exhaust_top"] - p["rear_exhaust_h"]
    s.rect(dy + p["device_depth"], exz, 0.8, p["rear_exhaust_h"], fill="#f63", stroke="#f63")
    for fy in (p["device_foot_inset_y"], p["device_depth"] - p["device_foot_inset_y"]):
        s.rect(dy + fy - p["device_foot_dia"] / 2, db - p["device_foot_height"], p["device_foot_dia"], p["device_foot_height"], fill="#222")
    s.rect(dy + p["bottom_vent_y0"], db - 0.8, p["bottom_vent_d"], 0.8, fill="#39f", stroke="#39f")
    s.text(dy + p["device_depth"] / 2, db + p["device_height"] - 12, "MSI EdgeXpert", anchor="middle", color="#fff")
    s.rect(dy + p["device_depth"], exz, p["rear_free_zone"], p["rear_exhaust_h"], fill="#fca", stroke="#e73", dash="3,2")
    s.text(dy + p["device_depth"] + p["rear_free_zone"] / 2, exz + p["rear_exhaust_h"] / 2 - 3, "выхлоп →", anchor="middle", size=9)
    tx = X(d["y_t_out"]); tz = zp + d["t_out_zl"]
    s.circle(tx, tz, 4, stroke="#c00", fill="#fdd"); s.text(tx + 6, tz + 6, "T_out", size=8, color="#c00")
    s.line(X(d["y_t_out_post"]), zp, X(d["y_t_out_post"]), tz, stroke="#666", sw=2)
    s.line(tx, tz, X(d["y_t_out_post"]), tz, stroke="#666", sw=2)
    # подача под днище
    s.line(yo, zp + d["outlet_z0"], yo + 30, zp + d["outlet_z0"] - 10, stroke="#39f", sw=1.2)
    s.text(yo + 32, zp + d["outlet_z0"] - 14, "подача под днище" if p["under_feed"] else "", size=8, color="#39f")
    xr = X(L) + 4
    s.dim_v(0, d["fan_center_z"], xr, f"ось вент. = ось сот {d['fan_center_z']:g}")
    s.dim_v(0, db, xr + 14, f"низ MSI {db:g}")
    s.dim_v(db, db + p["device_height"], xr + 14, f"MSI {p['device_height']:g}")
    s.dim_v(0, fz0 + p["fan_size"], xr + 28, f"верх вент. {fz0 + p['fan_size']:g}")
    s.dim_v(0, p["panel_h"] - p["shelf_top_z"], xr + 42, f"верх панели {p['panel_h'] - p['shelf_top_z']:g}")
    s.dim_h(X(0), yi, -10, f"{p['fan_thickness']:g}")
    s.dim_h(yi, yo, -22, f"воздуховод {d['duct_len']:g} = пленум {p['plenum_len']:g} + сопло {p['nozzle_len']:g} (R мин {d['duct_bend_r_min']:.0f})")
    s.dim_h(yo, dy, -10, f"{p['gasket_t']:g}")
    s.dim_h(dy, dy + p["device_depth"], -10, f"MSI {p['device_depth']:g}")
    s.dim_h(dy + p["device_depth"], X(d["y_track_end"]), -22, f"выхлоп {p['rear_free_zone']:g}")
    s.dim_h(X(0), X(d["y_track_end"]), -36, f"модуль {d['y_track_end']:g} от задней плоскости панели; полка {p['shelf_depth']:g}; шкаф {p['rack_depth']:g}")
    s.text(X(0), -52, f"Пакет болта: решётка {p['grille_stack_t']:g} + панель {p['panel_t']:g} + вентилятор {p['fan_thickness']:g} + фланец {p['duct_flange_t']:g} = {d['sandwich_stack']:g} → M4×{d['sandwich_bolt_l']:g} (выступ {d['sandwich_protrusion']:.1f}).", size=10)
    s.save(OUT / "side_view.svg")


def draw_top(p, d):
    pw = p["panel_w"]
    L = d["y_track_end"] + 10
    s = Svg(pw, L + 90, "ВИД СВЕРХУ — модуль (панель внизу, ниже — стекло двери). Размеры в мм", scale=1.5, margin=100, extra_top=90, extra_bottom=40)
    def Y(y): return y + 85
    s.rect(0, Y(-p["panel_t"]), pw, p["panel_t"], fill="#bbb")
    s.text(4, Y(-p["panel_t"]) - 12, "ФП-5", size=9)
    bw = d["base_plate_w"]
    s.rect(pw / 2 - bw / 2, Y(d["base_plate_y0"]), bw, d["base_plate_d"], fill="#eee", stroke="#000")
    s.line(pw / 2, Y(-20), pw / 2, Y(L), stroke="#06c", sw=0.5, dash="8,4")
    for cx_rel, name in zip((-d["track_pitch"] / 2, d["track_pitch"] / 2), ("1", "2")):
        cx = pw / 2 + cx_rel
        s.rect(cx - p["fan_size"] / 2, Y(0), p["fan_size"], p["fan_thickness"], fill="#9cf")
        s.text(cx, Y(p["fan_thickness"] / 2), "P14 Pro 140×27", size=9, anchor="middle")
        s.rect(cx - d["in_flange_w"] / 2, Y(d["y_duct_in"]), d["in_flange_w"], p["plenum_len"], fill="#eef")
        ow = d["outlet_w"] + 2 * p["duct_wall"]
        yn0, yn1 = d["y_duct_in"] + p["plenum_len"], d["y_duct_out"] - p["duct_flange_t"]
        s.poly([(cx - d["in_flange_w"] / 2, Y(yn0)), (cx + d["in_flange_w"] / 2, Y(yn0)), (cx + ow / 2, Y(yn1)), (cx - ow / 2, Y(yn1))], fill="#eef")
        s.text(cx, Y((yn0 + yn1) / 2), "сопло", size=9, anchor="middle")
        s.rect(cx - d["holder_outer_w"] / 2, Y(d["y_duct_out"]), d["holder_outer_w"], d["holder_depth"], stroke="#555", dash="3,2")
        s.rect(cx - p["device_width"] / 2, Y(d["y_device_front"]), p["device_width"], p["device_depth"], fill="#444")
        s.text(cx, Y(d["y_device_front"] + p["device_depth"] / 2), f"MSI EdgeXpert {name}", size=10, anchor="middle", color="#fff")
        s.rect(cx - p["rear_exhaust_w"] / 2, Y(d["y_device_rear"]), p["rear_exhaust_w"], p["rear_free_zone"], fill="#fca", stroke="#e73", dash="3,2")
        s.text(cx, Y(d["y_device_rear"] + p["rear_free_zone"] / 2), "выхлоп →", size=9, anchor="middle")
        if d["ctrl_known"]:
            s.rect(cx - d["bezel_w"] / 2, Y(-p["panel_t"] - d["bezel_d"]), d["bezel_w"], d["bezel_d"], fill="#cfc", stroke="#070")
    s.line(0, Y(-p["door_gap"]), pw, Y(-p["door_gap"]), stroke="#6af", sw=1.5)
    s.text(pw / 2, Y(-p["door_gap"]) + 3, f"стекло двери: {p['door_gap']:g} от передней грани стоек", size=9, anchor="middle", color="#36c")
    for sx in (-1, 1) if d["use_panel_brackets"] else ():
        bx = pw / 2 + sx * d["bracket_cx"]
        s.rect(bx - p["bracket_w"] / 2, Y(d["base_plate_y0"]), p["bracket_w"], p["bracket_d"], fill="#ccc", stroke="#555")
    cx1, cx2 = pw / 2 - d["track_pitch"] / 2, pw / 2 + d["track_pitch"] / 2
    s.dim_h(cx1, cx2, Y(L) + 6, f"{d['track_pitch']:g}")
    s.dim_h(cx1 - d["track_w"] / 2, cx1 + d["track_w"] / 2, Y(L) + 18, f"трак {d['track_w']:g}")
    s.dim_h(pw / 2 - bw / 2, pw / 2 + bw / 2, Y(L) + 30, f"base_plate {bw:g}")
    s.dim_h(0, pw, Y(L) + 42, f"панель {pw:g}")
    xr = pw + 6
    s.dim_v(Y(0), Y(d["y_duct_in"]), xr, f"{p['fan_thickness']:g}")
    s.dim_v(Y(d["y_duct_in"]), Y(d["y_duct_out"]), xr, f"возд. {d['duct_len']:g}")
    s.dim_v(Y(d["y_duct_out"]), Y(d["y_device_rear"]), xr, f"{p['gasket_t']:g}+MSI {p['device_depth']:g}")
    s.dim_v(Y(d["y_device_rear"]), Y(d["y_track_end"]), xr, f"выхлоп {p['rear_free_zone']:g}")
    s.dim_v(Y(0), Y(d["y_track_end"]), xr + 16, f"{d['y_track_end']:g}")
    s.save(OUT / "top_view.svg")


# ---------------------------------------------------------------------------
def draw_fan_templates(p, d):
    """Шаблоны разметки вырезов ФП-5 в масштабе 1:1 на A4, по одному на вентилятор.

    Вид снаружи. Привязка: нижний и верхний край панели (полная высота 221.5
    помещается на A4) и ось панели. Печатать 100 %, проверить по линейке 100 мм.
    """
    pw, ph = p["panel_w"], p["panel_h"]
    axis = d["fan_center_z_panel"]
    pmin, pmax = p["fan_hole_pitch_min"], p["fan_hole_pitch_max"]
    r_open, r_hole = p["fan_open_dia"] / 2, p["fan_hole_dia"] / 2
    PW, PH, yb = 210.0, 297.0, 255.0          # лист A4; нижний край панели на листе
    ink, red, blue, grey = "#000", "#c00", "#06c", "#777"
    for i, cx_rel in enumerate((-d["track_pitch"] / 2, d["track_pitch"] / 2), start=1):
        side = -1 if cx_rel < 0 else 1
        x_axis = 195.0 if side < 0 else 15.0  # ось панели на листе
        def X(x): return x_axis + x           # x — от оси панели (вид снаружи)
        def Y(z): return yb - z               # z — от нижнего края панели
        cx = cx_rel
        el = []
        def line(x1, y1, x2, y2, c=ink, w=0.25, dash=None):
            ds = f' stroke-dasharray="{dash}"' if dash else ""
            el.append(f'<line x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}" stroke="{c}" stroke-width="{w}"{ds}/>')
        def circ(x, y, r, c=ink, w=0.3, fill="none"):
            el.append(f'<circle cx="{x:.3f}" cy="{y:.3f}" r="{r:.3f}" stroke="{c}" stroke-width="{w}" fill="{fill}"/>')
        def text(x, y, t, size=3.2, c=ink, anchor="start", bold=False, rot=None):
            fw = ' font-weight="bold"' if bold else ""
            tr = f' transform="rotate({rot} {x:.2f} {y:.2f})"' if rot else ""
            el.append(f'<text x="{x:.2f}" y="{y:.2f}" font-size="{size}" font-family="sans-serif" fill="{c}" text-anchor="{anchor}"{fw}{tr}>{t}</text>')
        def cross(x, y, r, c=ink, w=0.2):
            line(x - r, y, x + r, y, c, w); line(x, y - r, x, y + r, c, w)
        x_lo, x_hi = (8.0, x_axis) if side < 0 else (x_axis, 202.0)
        # края панели и ось
        for z, name in ((0, "НИЖНИЙ"), (ph, "ВЕРХНИЙ")):
            line(x_lo, Y(z), x_hi, Y(z), w=0.6)
            text((x_lo + x_hi) / 2, Y(z) + (4.2 if z == 0 else -1.6), f"{name} КРАЙ ФП-5 — совместить с краем панели", 3, anchor="middle", bold=True)
        line(X(0), Y(ph) - 6, X(0), Y(0) + 6, blue, 0.35, "6,1.5,1,1.5")
        text(X(0) + (-1.5 if side < 0 else 1.5), Y(ph) - 7.5, f"ОСЬ ПАНЕЛИ ({pw / 2:g} от каждого края)", 3,
             blue, "end" if side < 0 else "start", True)
        # осевые вентилятора
        line(X(cx), Y(0), X(cx), Y(ph), grey, 0.15, "4,1,1,1")
        line(x_lo, Y(axis), x_hi, Y(axis), grey, 0.15, "4,1,1,1")
        # вырез
        circ(X(cx), Y(axis), r_open, ink, 0.45)
        cross(X(cx), Y(axis), 8, ink, 0.3); circ(X(cx), Y(axis), 0.5, ink, 0.2, ink)
        text(X(cx), Y(axis) - 22, f"FAN{i}", 7, anchor="middle", bold=True)
        text(X(cx), Y(axis) - 15, f"вырез Ø{p['fan_open_dia']:g} — линия реза", 3.4, anchor="middle")
        text(X(cx), Y(axis) + 13, "центр: керн / пилот коронки", 3, grey, "middle")
        # пазы M4: обе точки (124.5 и 126) + контур паза
        for sx in (-1, 1):
            for sz in (-1, 1):
                pts = [(X(cx + sx * pt / 2), Y(axis + sz * pt / 2)) for pt in (pmin, pmax)]
                (x1, y1), (x2, y2) = pts
                el.append(f'<line x1="{x1:.3f}" y1="{y1:.3f}" x2="{x2:.3f}" y2="{y2:.3f}" stroke="{ink}" '
                          f'stroke-width="{2 * r_hole:.3f}" stroke-linecap="round" stroke-opacity="0.12"/>')
                for (x, y) in pts:
                    circ(x, y, r_hole, ink, 0.2); cross(x, y, 3.2, ink, 0.15)
        # рамка контроллера — только после замера
        if d["ctrl_known"]:
            for sx in (-1, 1):
                x = X(cx + sx * d["bezel_lug_dx"]); circ(x, Y(d["bezel_cz_panel"]), p["m3_clear_d"] / 2); cross(x, Y(d["bezel_cz_panel"]), 3)
            chx = X(cx + (1 if cx > 0 else -1) * p["cable_hole_side"] * d["cable_hole_dx"])
            circ(chx, Y(d["bezel_cz_panel"]), p["cable_hole_d"] / 2); cross(chx, Y(d["bezel_cz_panel"]), 4)
        else:
            text(X(cx), Y(ph) + 8, f"над вырезом — полоса {d['strip_above_fan']:g} мм под рамку контроллера (отверстия — после замера)", 2.6, grey, "middle")
        # размеры
        xd = X(cx) + side * (r_open + 8)
        line(xd, Y(0), xd, Y(axis), red, 0.25)
        for z in (0, axis):
            line(xd - 1.5, Y(z), xd + 1.5, Y(z), red, 0.25)
        text(xd + side * -1.2, Y(axis / 2), f"{axis:g}", 3.4, red, "middle", True, -90)
        yd = Y(0) - 6
        line(X(0), yd, X(cx), yd, red, 0.25)
        for x in (X(0), X(cx)):
            line(x, yd - 1.5, x, yd + 1.5, red, 0.25)
        text((X(0) + X(cx)) / 2, yd - 1.2, f"{abs(cx):g}", 3.4, red, "middle", True)
        text(X(cx) + side * 2, Y(0) - 11.5, f"до {'левого' if side < 0 else 'правого'} края панели {pw / 2 - abs(cx):g}", 2.8, red,
             "end" if side < 0 else "start")
        # шапка
        name = "левый" if side < 0 else "правый"
        text(8, 10, f"ФП-5 · разметка FAN{i} ({name}) · вид снаружи · МАСШТАБ 1:1", 4.2, bold=True)
        text(8, 15.5, f"Печать A4 «Фактический размер» / 100 %, без подгонки. Проверка: линейка 100 мм внизу, между краями {ph:g}.", 3)
        text(8, 20.5, f"Ось выреза {axis:g} от нижнего края, {abs(cx):g} от оси панели; межосевое вентиляторов {d['track_pitch']:g}.", 3)
        # подвал: проверка масштаба и указания
        y0 = yb + 13
        line(15, y0, 115, y0, ink, 0.4)
        for k in range(11):
            line(15 + 10 * k, y0 - (2.5 if k % 5 == 0 else 1.5), 15 + 10 * k, y0, ink, 0.25)
        text(65, y0 + 4, "100 мм — проверка масштаба", 3, anchor="middle")
        text(8, y0 + 10, f"Пазы M4: две точки на межцентровом {pmin:g} и {pmax:g} (±{pmin / 2:g} и ±{pmax / 2:g} от центра выреза по X и Z).", 2.9)
        text(8, y0 + 14.5, f"Сверло Ø{p['fan_hole_dia']:g} в обе точки + надфиль; для 4 болтов M4×{d['sandwich_bolt_l']:g} сэндвича решётка–панель–вентилятор–фланец.", 2.9)
        text(8, y0 + 19, "Керн через бумагу по перекрестьям, потом снять шаблон. Данные — scad/params.scad (make_drawings.py).", 2.9, grey)
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{PW:g}mm" height="{PH:g}mm" viewBox="0 0 {PW:g} {PH:g}">\n'
               f'<rect width="{PW:g}" height="{PH:g}" fill="#fff"/>\n' + "\n".join(el) + "\n</svg>\n")
        (OUT / f"fan_template_FAN{i}.svg").write_text(svg, encoding="utf-8")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    p = load_params()
    d = load_derived()
    draw_panel(p, d); draw_base_plate(p, d); draw_side(p, d); draw_top(p, d); draw_fan_templates(p, d)
    print("drawings written to", OUT)
    print(f"panel axis {d['fan_center_z_panel']:g}; strip above fan {d['strip_above_fan']:g}; plate {d['base_plate_w']:g}x{d['base_plate_d']:g}; bolt M4x{d['sandwich_bolt_l']:g}")


if __name__ == "__main__":
    main()
