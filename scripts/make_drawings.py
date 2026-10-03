#!/usr/bin/env python3
"""Чертежи (SVG) 5U-модуля по параметрам scad/params.scad.

  docs/drawings/panel_fp5.svg   — разметка вырезов ФП-5 (горизонталь — размеры от краёв панели;
                                  вертикаль — от нижнего края по формуле shelf_top_z + 78; пока
                                  shelf_top_z = TO_MEASURE, вырезы показаны в середине допустимого
                                  диапазона и помечены)
  docs/drawings/base_plate.svg  — сверловка base_plate (размеры от оси и от переднего края;
                                  ширина плиты = rack_opening_w − 6 = TO_MEASURE)
  docs/drawings/side_view.svg   — продольная цепочка трака (полностью определена)
  docs/drawings/top_view.svg    — вид сверху на модуль (ширина плиты TO_MEASURE)

Скрипт читает числовые присваивания из params.scad и повторяет производные формулы.
Значения undef → None → на чертеже подпись TO_MEASURE и условная геометрия с пометкой.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PARAMS = ROOT / "scad" / "params.scad"
OUT = ROOT / "docs" / "drawings"
# Условные значения ТОЛЬКО для масштаба картинки; на чертеже помечены как TO_MEASURE
NOMINAL = {"rack_opening_w": 450.85, "shelf_depth": 400.0, "panel_t": 1.2}


def load_params() -> dict:
    p: dict = {}
    rx = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([-0-9.]+|true|false|undef|\"[^\"]*\")\s*;")
    for line in PARAMS.read_text(encoding="utf-8").splitlines():
        m = rx.match(line)
        if not m:
            continue
        k, v = m.group(1), m.group(2)
        if v == "undef":
            p[k] = None
        elif v in ("true", "false"):
            p[k] = v == "true"
        elif v.startswith('"'):
            p[k] = v.strip('"')
        else:
            p[k] = float(v)
    return p


def derive(p: dict) -> dict:
    d = dict(p)
    d["fan_center_z"] = p["base_plate_t"] + p["fan_axis_above_plate"]            # 78 над полкой
    d["fan_center_zl"] = p["fan_axis_above_plate"]                               # 75 над плитой
    d["device_base_zl"] = d["fan_center_zl"] - p["device_height"] / 2
    d["holder_outer_w"] = p["device_width"] + 2 * p["holder_side_clearance"] + 2 * p["holder_wall"]
    d["track_w"] = max(d["holder_outer_w"], p["fan_size"] + 2 * p["holder_wall"])
    d["track_gap"] = 15.0
    d["track_pitch"] = d["track_w"] + d["track_gap"]
    d["pair_w"] = 2 * d["track_w"] + d["track_gap"]
    d["y_duct_in"] = p["fan_thickness"]
    d["duct_len"] = p["plenum_len"] + p["nozzle_len"]
    d["y_duct_out"] = d["y_duct_in"] + d["duct_len"]
    d["y_device_front"] = d["y_duct_out"] + p["gasket_t"]
    d["y_device_rear"] = d["y_device_front"] + p["device_depth"]
    d["y_holder_rear"] = d["y_device_rear"] + p["holder_rear_clearance"] + p["back_stop_t"]
    d["y_track_end"] = d["y_device_rear"] + p["rear_free_zone"]
    d["outlet_w"] = p["device_width"] - 2 * p["device_intake_margin_x"]
    d["outlet_z0"] = d["device_base_zl"] - p["outlet_under_device"]
    d["outlet_z1"] = d["device_base_zl"] + p["device_height"] - p["device_intake_margin_top"] + p["outlet_over_device"]
    d["post_top_z"] = d["device_base_zl"] + p["device_height"] + 8
    d["guide_top_z"] = d["device_base_zl"] + p["guide_wall_extra_h"]
    d["in_flange_w"] = p["fan_size"] + 2 * p["holder_wall"]
    d["fan_cx"] = [-d["track_pitch"] / 2, d["track_pitch"] / 2]
    d["axis_min"] = p["panel_edge_keepout"] + d["in_flange_w"] / 2
    d["axis_max"] = p["panel_h"] - p["panel_edge_keepout"] - d["in_flange_w"] / 2
    d["shelf_top_z_min"] = d["axis_min"] - d["fan_center_z"]
    d["shelf_top_z_max"] = d["axis_max"] - d["fan_center_z"]
    d["bracket_cx"] = d["track_pitch"] / 2 + d["in_flange_w"] / 2 + 5 + p["bracket_w"] / 2
    d["rail_setback"] = max(0, p["device_foot_inset"] - p["device_foot_dia"] / 2 - p["rail_setback_margin"]) if p["rails_follow_feet"] else 20
    d["ctrl_zone_x_in"] = d["track_pitch"] / 2 + d["in_flange_w"] / 2 + p["ctrl_zone_margin"]
    d["ctrl_zone_y0"] = p["base_plate_front_gap"] + p["bracket_d"] + 7
    d["ctrl_zone_y1"] = d["y_duct_out"] - 6
    d["ctrl_zone_d"] = d["ctrl_zone_y1"] - d["ctrl_zone_y0"]
    bw_nom = (p["rack_opening_w"] if p["rack_opening_w"] is not None else NOMINAL["rack_opening_w"]) - 2 * p["base_plate_side_gap"]
    d["ctrl_zone_w"] = bw_nom / 2 - p["ctrl_zone_margin"] - d["ctrl_zone_x_in"]
    return d


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
        body = "\n".join(self.parts)
        path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.W:.0f}" height="{self.H:.0f}" viewBox="0 0 {self.W:.0f} {self.H:.0f}">\n<rect width="100%" height="100%" fill="#fff"/>\n{body}\n</svg>\n', encoding="utf-8")


def fmt(v):
    return "TO_MEASURE" if v is None else f"{v:g}"


# ---------------------------------------------------------------------------
def draw_panel(d):
    pw, ph = d["panel_w"], d["panel_h"]
    known = d["shelf_top_z"] is not None
    axis = d["shelf_top_z"] + d["fan_center_z"] if known else (d["axis_min"] + d["axis_max"]) / 2
    title = "РАЗМЕТКА ФП-5 (вид спереди, снаружи). Размеры в мм от краёв панели" + ("" if known else " — ВЕРТИКАЛЬ УСЛОВНА (shelf_top_z = TO_MEASURE)")
    s = Svg(pw, ph, title, scale=2.2, extra_bottom=150)
    s.rect(0, 0, pw, ph, stroke="#000", sw=1.8)
    # зона отбортовки / keep-out
    k = d["panel_edge_keepout"]
    s.rect(k, k, pw - 2 * k, ph - 2 * k, stroke="#c66", dash="4,3", sw=0.8)
    s.text(k + 2, ph - k - 8, f"keep-out {k:g} мм от краёв (отбортовка {d['panel_fold']:g} внутрь)", size=9, color="#c66")
    for cx_rel in d["fan_cx"]:
        cx = pw / 2 + cx_rel
        s.circle(cx, axis, d["fan_open_dia"] / 2, stroke="#000", sw=1.4)
        s.circle(cx, axis, d["fan_size"] / 2, stroke="#888", dash="3,3", sw=0.8)       # контур вентилятора/решётки
        s.rect(cx - d["in_flange_w"] / 2, axis - d["in_flange_w"] / 2, d["in_flange_w"], d["in_flange_w"], stroke="#06c", dash="3,2", sw=0.8)
        for sx in (-1, 1):
            for sz in (-1, 1):
                hx, hz = cx + sx * d["fan_hole_pitch"] / 2, axis + sz * d["fan_hole_pitch"] / 2
                s.circle(hx, hz, d["fan_hole_dia"] / 2, stroke="#000", sw=1.2)
                s.line(hx - 4, hz, hx + 4, hz, stroke="#000", sw=0.5); s.line(hx, hz - 4, hx, hz + 4, stroke="#000", sw=0.5)
        s.line(cx, axis - 80, cx, axis + 80, stroke="#06c", sw=0.5, dash="6,3")
        s.text(cx, axis + 4, f"Ø{d['fan_open_dia']:g}", size=11, anchor="middle", bold=True)
        s.text(cx, axis - 12, f"4 × паз M4 {d['fan_hole_dia']:g}×{d['fan_hole_dia'] + 2 * d['fan_hole_tol']:g} на □{d['fan_hole_pitch']:g}", size=9, anchor="middle")
        s.text(cx, axis - 24, f"фланец duct {d['in_flange_w']:g}×{d['in_flange_w']:g} (сзади)", size=9, anchor="middle", color="#06c")
    s.line(pw / 2, 0, pw / 2, ph, stroke="#06c", sw=0.5, dash="8,4")
    cx1, cx2 = pw / 2 + d["fan_cx"][0], pw / 2 + d["fan_cx"][1]
    # горизонтальные размеры
    s.dim_h(0, cx1, -10, f"{cx1:g}")
    s.dim_h(cx1, cx2, -10, f"{d['track_pitch']:g}")
    s.dim_h(cx2, pw, -10, f"{pw - cx2:g}")
    s.dim_h(0, pw, -24, f"{pw:g} [SOURCE]")
    s.dim_h(cx1 - d["fan_hole_pitch"] / 2, cx1 + d["fan_hole_pitch"] / 2, axis + d["fan_size"] / 2 + 6, f"{d['fan_hole_pitch']:g} ±{d['fan_hole_tol']:g}")
    # вертикальные
    xr = pw + 6
    s.dim_v(0, axis, xr, (f"{axis:g}" if known else f"ось = shelf_top_z + {d['fan_center_z']:g} = TO_MEASURE"))
    s.dim_v(0, ph, xr + 18, f"{ph:g} [SOURCE]")
    s.dim_v(axis - d["fan_hole_pitch"] / 2, axis + d["fan_hole_pitch"] / 2, cx2 + d["fan_size"] / 2 + 6, f"{d['fan_hole_pitch']:g}")
    # допуск по вертикали
    s.text(2, -34, f"Допустимая ось выреза: {d['axis_min']:g}…{d['axis_max']:g} мм от нижнего края (фланец 150 ≥ {k:g} мм от краёв) ⇒ shelf_top_z ∈ [{d['shelf_top_z_min']:g}; {d['shelf_top_z_max']:g}]", size=10, color="#b00")
    if not known:
        s.text(2, -46, f"Вырезы нарисованы на оси {axis:g} — середина допуска, ТОЛЬКО для иллюстрации. Не резать до замера shelf_top_z.", size=10, color="#b00", bold=True)
    s.text(2, -58, "Толщина листа panel_t = " + fmt(d["panel_t"]) + "; крепёжные уши ФП-5 без изменений (шаг panel_hole_pitch_v = " + fmt(d["panel_hole_pitch_v"]) + ")", size=10)
    s.save(OUT / "panel_fp5.svg")


def draw_base_plate(d):
    known_w = d["rack_opening_w"] is not None
    bw = (d["rack_opening_w"] if known_w else NOMINAL["rack_opening_w"]) - 2 * d["base_plate_side_gap"]
    known_d = d["shelf_depth"] is not None
    bd = max(d["base_plate_depth_min"], min((d["shelf_depth"] if known_d else NOMINAL["shelf_depth"]), d["y_track_end"] + 10))
    title = "СВЕРЛОВКА BASE_PLATE (вид сверху, перед внизу). Размеры в мм от оси X=0 и от переднего края" + ("" if known_w and known_d else " — ГАБАРИТ УСЛОВЕН (TO_MEASURE)")
    s = Svg(bw, bd, title, scale=1.8, extra_bottom=80)
    y0 = d["base_plate_front_gap"]
    def Y(y): return y - y0   # чертёжный y от переднего края плиты
    s.rect(0, 0, bw, bd, stroke="#000", sw=1.8, dash=None if known_w else "6,4")
    s.line(bw / 2, 0, bw / 2, bd, stroke="#06c", sw=0.6, dash="8,4")
    s.text(bw / 2 + 2, bd - 8, "ось модуля X=0", size=9, color="#06c")
    # контуры holder'ов и каналов
    for cx_rel in d["fan_cx"]:
        cx = bw / 2 + cx_rel
        s.rect(cx - d["holder_outer_w"] / 2, Y(d["y_duct_out"]), d["holder_outer_w"], d["y_holder_rear"] - d["y_duct_out"], stroke="#888", dash="3,2", sw=0.8)
        s.rect(cx - d["in_flange_w"] / 2, Y(0), d["in_flange_w"], d["y_duct_out"], stroke="#aaa", dash="2,2", sw=0.6)
        s.text(cx, Y(d["y_device_front"] + 60), "holder (контур)", size=9, anchor="middle", color="#888")
        dev_cy = d["y_device_front"] + d["device_depth"] / 2
        for sx in (-1, 1):
            for sy in (-1, 1):
                hx, hy = cx + sx * d["holder_mount_pitch_x"] / 2, dev_cy + sy * d["holder_mount_pitch_y"] / 2
                s.circle(hx, Y(hy), d["m4_clear_d"] / 2, stroke="#000", sw=1.2)
                s.line(hx - 4, Y(hy), hx + 4, Y(hy), sw=0.5); s.line(hx, Y(hy) - 4, hx, Y(hy) + 4, sw=0.5)
        s.text(cx, Y(dev_cy) - 4, f"4 × Ø{d['m4_clear_d']:g} на {d['holder_mount_pitch_x']:g} × {d['holder_mount_pitch_y']:g}", size=9, anchor="middle")
        s.dim_h(cx - d["holder_mount_pitch_x"] / 2, cx + d["holder_mount_pitch_x"] / 2, Y(dev_cy + d["holder_mount_pitch_y"] / 2) + 8, f"{d['holder_mount_pitch_x']:g}")
        s.dim_v(Y(dev_cy - d["holder_mount_pitch_y"] / 2), Y(dev_cy + d["holder_mount_pitch_y"] / 2), cx + d["holder_mount_pitch_x"] / 2 + 8, f"{d['holder_mount_pitch_y']:g}")
    # уголки
    for sx in (-1, 1):
        bx = bw / 2 + sx * d["bracket_cx"]
        s.rect(bx - d["bracket_w"] / 2, Y(y0), d["bracket_w"], d["bracket_d"], stroke="#555", dash="3,2", sw=0.8)
        for k in (0, 1):
            hy = y0 + d["bracket_t"] + 12 + k * (d["bracket_d"] - d["bracket_t"] - 24)
            s.circle(bx, Y(hy), d["m4_clear_d"] / 2, stroke="#000", sw=1.2)
        s.text(bx, Y(y0 + d["bracket_d"] + 4), "уголок 2×M4", size=9, anchor="middle", color="#555")
    # зоны электроники — две полосы
    g = d["ctrl_hole_grid"]
    for sx in (-1, 1):
        x_in = bw / 2 + sx * d["ctrl_zone_x_in"]
        x0 = min(x_in, x_in + sx * d["ctrl_zone_w"])
        s.rect(x0, Y(d["ctrl_zone_y0"]), d["ctrl_zone_w"], d["ctrl_zone_d"], stroke="#2a2", dash="3,2", sw=0.8)
        i = 0
        while 2 + i * g <= d["ctrl_zone_w"] - 2:
            j = 0
            while j * g <= d["ctrl_zone_d"]:
                s.circle(x_in + sx * (2 + i * g), Y(d["ctrl_zone_y0"] + j * g), 0.8, stroke="#2a2", sw=0.5)
                j += 1
            i += 1
        s.text(x0 + 1, Y(d["ctrl_zone_y1"]) + 3, f"M3 сетка {g:g}", size=8, color="#2a2")
    s.text(bw / 2, Y(d["ctrl_zone_y0"]) - 10, f"полосы электроники: x = ±({d['ctrl_zone_x_in']:g}…{d['ctrl_zone_x_in'] + d['ctrl_zone_w']:g}*), y = {Y(d['ctrl_zone_y0']):g}…{Y(d['ctrl_zone_y1']):g}  (* при условной ширине)", size=9, anchor="middle", color="#2a2")
    dcx, dcy = bw / 2 + d["ctrl_zone_x_in"] + d["ctrl_zone_w"] / 2, d["ctrl_zone_y1"] - 10
    for sx in (-1, 1):
        s.circle(dcx + sx * 10, Y(dcy), d["m3_clear_d"] / 2, stroke="#000", sw=1)
    s.text(dcx, Y(dcy) - 8, "DC-гнездо 2×M3", size=8, anchor="middle")
    # размеры
    cx1, cx2 = bw / 2 + d["fan_cx"][0], bw / 2 + d["fan_cx"][1]
    s.dim_h(bw / 2, cx2, -10, f"{d['track_pitch'] / 2:g} (ось трака от X=0)")
    s.dim_h(cx1, bw / 2, -10, f"{d['track_pitch'] / 2:g}")
    s.dim_h(bw / 2, bw / 2 + d["bracket_cx"], -22, f"{d['bracket_cx']:g} (уголок)")
    s.dim_h(0, bw, -36, f"ширина = rack_opening_w − {2 * d['base_plate_side_gap']:g} = {fmt(d['rack_opening_w'] - 2 * d['base_plate_side_gap'] if known_w else None)}")
    xr = bw + 6
    dev_cy = d["y_device_front"] + d["device_depth"] / 2
    s.dim_v(0, Y(dev_cy), xr, f"{Y(dev_cy):g} (центр MSI)")
    s.dim_v(0, Y(y0 + d['bracket_t'] + 12), xr + 16, f"{Y(y0 + d['bracket_t'] + 12):g}")
    s.dim_v(0, bd, xr + 32, f"глубина ≥ {d['base_plate_depth_min']:g}; = {fmt(bd if known_d else None)}")
    s.text(2, -50, f"Передний край плиты на {y0:g} мм за задней плоскостью панели. Толщина {d['base_plate_t']:g} мм, алюминий. Отверстия Ø{d['m4_clear_d']:g} (M4) и Ø{d['m3_clear_d']:g} (M3).", size=10)
    if not (known_w and known_d):
        s.text(2, -62, "Габарит плиты условный — только расположение отверстий относительно оси и переднего края окончательно.", size=10, color="#b00", bold=True)
    s.save(OUT / "base_plate.svg")


def draw_side(d):
    L = d["y_track_end"] + 20
    H = 160
    s = Svg(L + 20, H, "ВИД СБОКУ — один трак (Y: глубина, Z: высота над полкой). Размеры в мм", scale=1.9, extra_bottom=80)
    ox = 20  # сдвиг, чтобы показать панель и решётку в y<0
    pt = d["panel_t"] if d["panel_t"] is not None else NOMINAL["panel_t"]
    def X(y): return ox + y
    s.rect(X(0), 0, L, d["base_plate_t"], fill="#ccc")                                    # полка/плита условно
    s.rect(X(-pt), -d.get("shelf_top_z") if d.get("shelf_top_z") else -20, pt, d["panel_h"], fill="#bbb")
    s.text(X(-pt) - 2, 80, "ФП-5", size=9, anchor="end", rotate=-90)
    s.rect(X(-pt - d["grille_t"]), d["fan_center_z"] - d["fan_size"] / 2, d["grille_t"], d["fan_size"], fill="#777")
    fz0 = d["fan_center_z"] - d["fan_size"] / 2
    s.rect(X(0), fz0, d["fan_thickness"], d["fan_size"], fill="#9cf")
    s.text(X(d["fan_thickness"] / 2), d["fan_center_z"], "FAN", size=9, anchor="middle")
    zoff = d["base_plate_t"]
    yi, yo = X(d["y_duct_in"]), X(d["y_duct_out"])
    yn0, yn1 = yi + d["plenum_len"], yo - d["duct_flange_t"]
    top0, bot0 = d["fan_center_z"] + d["fan_size"] / 2, d["fan_center_z"] - d["fan_size"] / 2
    top1, bot1 = d["outlet_z1"] + zoff + d["duct_wall"], d["outlet_z0"] + zoff - d["duct_wall"]
    n = 24
    pts_top, pts_bot = [(yi, top0), (yn0, top0)], [(yi, bot0), (yn0, bot0)]
    for i in range(1, n + 1):
        t = i / n; u = t * t * (3 - 2 * t); y = yn0 + (yn1 - yn0) * t
        pts_top.append((y, top0 + (top1 - top0) * u)); pts_bot.append((y, bot0 + (bot1 - bot0) * u))
    s.poly(pts_top + [(yo, top1), (yo, bot1)] + list(reversed(pts_bot)), fill="#eef")
    s.text(yi + 8, d["fan_center_z"], "plenum", size=9); s.text(yn0 + 6, d["fan_center_z"], "nozzle", size=9)
    s.rect(yo - d["duct_flange_t"], zoff + max(0, d["outlet_z0"] - d["duct_flange_t"] - 4), d["duct_flange_t"], d["post_top_z"] - max(0, d["outlet_z0"] - d["duct_flange_t"] - 4), fill="#ddd")
    hy0, hy1 = yo, X(d["y_holder_rear"])
    s.rect(hy0, zoff, hy1 - hy0, d["holder_floor_t"], fill="#bbb")
    s.rect(hy0, zoff, d["front_post_len"], d["post_top_z"], fill="#bbb")
    s.rect(hy0 + d["front_post_len"], zoff, hy1 - hy0 - d["front_post_len"], d["guide_top_z"], fill="#ccc", dash="2,2")
    ry0 = X(d["y_device_front"] + d["rail_setback"]); rl = d["device_depth"] - 2 * d["rail_setback"]
    s.rect(ry0, zoff, rl, d["device_base_zl"], fill="#999")
    s.text(ry0 + rl / 2, zoff + d["device_base_zl"] / 2, f"рельсы 4×{d['rail_w']:g}, h={d['device_base_zl']:g}", size=9, anchor="middle")
    bh = d["bypass_block"] * (d["device_base_zl"] - d["holder_floor_t"])
    s.rect(ry0 + rl, zoff + d["holder_floor_t"], d["baffle_t"], bh, fill="#f93", stroke="#c60")
    s.text(ry0 + rl + 6, zoff + d["holder_floor_t"] + bh + 3, f"заслонка байпаса {d['bypass_block']:g}", size=8, color="#c60")
    dy = X(d["y_device_front"])
    s.rect(dy, zoff + d["device_base_zl"], d["device_depth"], d["device_height"], fill="#444")
    s.text(dy + d["device_depth"] / 2, zoff + d["device_base_zl"] + d["device_height"] / 2, "MSI EdgeXpert", anchor="middle", color="#fff")
    s.rect(dy + d["device_depth"], zoff + d["device_base_zl"], d["rear_free_zone"], d["device_height"], fill="#fca", stroke="#e73", dash="3,2")
    s.text(dy + d["device_depth"] + d["rear_free_zone"] / 2, zoff + d["device_base_zl"] + d["device_height"] / 2, "выхлоп →", anchor="middle", size=9)
    xr = X(L) + 4
    s.dim_v(0, d["fan_center_z"], xr, f"ось {d['fan_center_z']:g} (= плита {d['base_plate_t']:g} + {d['fan_axis_above_plate']:g})")
    s.dim_v(0, zoff + d["device_base_zl"], xr + 14, f"дно MSI {zoff + d['device_base_zl']:g}")
    s.dim_v(zoff + d["device_base_zl"], zoff + d["device_base_zl"] + d["device_height"], xr + 14, f"MSI {d['device_height']:g}")
    s.dim_v(0, fz0 + d["fan_size"], xr + 28, f"верх FAN {fz0 + d['fan_size']:g}")
    s.dim_h(X(-pt - d["grille_t"]), X(0), -10, f"решётка {d['grille_t']:g} + панель {fmt(d['panel_t'])}", above=False)
    s.dim_h(X(0), yi, -10, f"{d['fan_thickness']:g}")
    s.dim_h(yi, yo, -22, f"duct {d['duct_len']:g} = plenum {d['plenum_len']:g} + nozzle {d['nozzle_len']:g}")
    s.dim_h(yo, dy, -10, f"{d['gasket_t']:g}")
    s.dim_h(dy, dy + d["device_depth"], -22, f"MSI {d['device_depth']:g}")
    s.dim_h(dy + d["device_depth"], X(d["y_track_end"]), -10, f"выхлоп {d['rear_free_zone']:g}")
    s.dim_h(X(0), X(d["y_track_end"]), -36, f"длина модуля от задней плоскости панели {d['y_track_end']:g}; полка ≥ {d['base_plate_depth_min']:g} (TO_MEASURE); шкаф {d['rack_depth']:g}")
    s.save(OUT / "side_view.svg")


def draw_top(d):
    known_w = d["rack_opening_w"] is not None
    bw = (d["rack_opening_w"] if known_w else NOMINAL["rack_opening_w"]) - 2 * d["base_plate_side_gap"]
    L = d["y_track_end"] + 10
    s = Svg(d["panel_w"], L + 20, "ВИД СВЕРХУ — модуль (X: ширина, Y: глубина, панель внизу). Размеры в мм" + ("" if known_w else " — ширина плиты УСЛОВНА"), scale=1.5, extra_top=90, extra_bottom=40)
    pw = d["panel_w"]
    def Y(y): return y + 15
    s.rect(0, Y(-15), pw, 15, fill="#bbb")  # панель условно (толщина не в масштабе)
    s.text(4, Y(-9), "ФП-5 482.6", size=9)
    s.rect(pw / 2 - bw / 2, Y(d["base_plate_front_gap"]), bw, L - d["base_plate_front_gap"], fill="#eee", stroke="#000", dash=None if known_w else "6,4")
    s.line(pw / 2, Y(-15), pw / 2, Y(L), stroke="#06c", sw=0.5, dash="8,4")
    for cx_rel, name in zip(d["fan_cx"], ("1", "2")):
        cx = pw / 2 + cx_rel
        s.rect(cx - d["fan_size"] / 2, Y(0), d["fan_size"], d["fan_thickness"], fill="#9cf")
        s.text(cx, Y(d["fan_thickness"] / 2), "P14 Pro 140×27", size=9, anchor="middle")
        s.rect(cx - d["in_flange_w"] / 2, Y(d["y_duct_in"]), d["in_flange_w"], d["plenum_len"], fill="#eef")
        ow = d["outlet_w"] + 2 * d["duct_wall"]
        yn0, yn1 = d["y_duct_in"] + d["plenum_len"], d["y_duct_out"] - d["duct_flange_t"]
        s.poly([(cx - d["in_flange_w"] / 2, Y(yn0)), (cx + d["in_flange_w"] / 2, Y(yn0)), (cx + ow / 2, Y(yn1)), (cx - ow / 2, Y(yn1))], fill="#eef")
        s.text(cx, Y((d["y_duct_in"] + yn1) / 2), "duct", size=9, anchor="middle")
        s.rect(cx - d["holder_outer_w"] / 2, Y(d["y_duct_out"]), d["holder_outer_w"], d["y_holder_rear"] - d["y_duct_out"], stroke="#555", dash="3,2")
        s.rect(cx - d["device_width"] / 2, Y(d["y_device_front"]), d["device_width"], d["device_depth"], fill="#444")
        s.text(cx, Y(d["y_device_front"] + d["device_depth"] / 2), f"MSI EdgeXpert {name}", size=10, anchor="middle", color="#fff")
        s.rect(cx - d["device_width"] / 2, Y(d["y_device_rear"]), d["device_width"], d["rear_free_zone"], fill="#fca", stroke="#e73", dash="3,2")
        s.text(cx, Y(d["y_device_rear"] + d["rear_free_zone"] / 2), "выхлоп →", size=9, anchor="middle")
    for sx in (-1, 1):
        bx = pw / 2 + sx * d["bracket_cx"]
        s.rect(bx - d["bracket_w"] / 2, Y(d["base_plate_front_gap"]), d["bracket_w"], d["bracket_d"], fill="#ccc", stroke="#555")
    for sx, lbl in ((-1, "PWM 1 + WAGO"), (1, "PWM 2 + DC")):
        x_in = pw / 2 + sx * d["ctrl_zone_x_in"]
        x0 = min(x_in, x_in + sx * d["ctrl_zone_w"])
        s.rect(x0, Y(d["ctrl_zone_y0"]), d["ctrl_zone_w"], d["ctrl_zone_d"], fill="#cfc", stroke="#2a2", dash="3,2")
        s.text(x0 + d["ctrl_zone_w"] / 2, Y(d["ctrl_zone_y0"] + d["ctrl_zone_d"] / 2), lbl, size=7, anchor="middle", color="#070", rotate=-90)
    cx1, cx2 = pw / 2 + d["fan_cx"][0], pw / 2 + d["fan_cx"][1]
    s.dim_h(cx1, cx2, Y(L) + 6, f"{d['track_pitch']:g}")
    s.dim_h(cx1 - d["track_w"] / 2, cx1 + d["track_w"] / 2, Y(L) + 18, f"трак {d['track_w']:g}")
    s.dim_h(pw / 2 - bw / 2, pw / 2 + bw / 2, Y(L) + 30, f"base_plate = rack_opening_w − 6 = {fmt(bw if known_w else None)}")
    s.dim_h(0, pw, Y(L) + 42, f"панель {pw:g}")
    xr = pw + 6
    s.dim_v(Y(0), Y(d["y_duct_in"]), xr, f"{d['fan_thickness']:g}")
    s.dim_v(Y(d["y_duct_in"]), Y(d["y_duct_out"]), xr, f"duct {d['duct_len']:g}")
    s.dim_v(Y(d["y_duct_out"]), Y(d["y_device_rear"]), xr, f"{d['gasket_t']:g} + MSI {d['device_depth']:g}")
    s.dim_v(Y(d["y_device_rear"]), Y(d["y_track_end"]), xr, f"выхлоп {d['rear_free_zone']:g}")
    s.dim_v(Y(0), Y(d["y_track_end"]), xr + 16, f"{d['y_track_end']:g}")
    s.save(OUT / "top_view.svg")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for old in ("front_view.svg", "front_view.png"):
        (OUT / old).unlink(missing_ok=True)
    d = derive(load_params())
    draw_panel(d); draw_base_plate(d); draw_side(d); draw_top(d)
    print("drawings written to", OUT)
    print(f"track {d['track_w']:g} x {d['y_track_end']:g}; pitch {d['track_pitch']:g}; pair {d['pair_w']:g}; "
          f"panel axis allowed {d['axis_min']:g}..{d['axis_max']:g} → shelf_top_z in [{d['shelf_top_z_min']:g}, {d['shelf_top_z_max']:g}]")


if __name__ == "__main__":
    main()
