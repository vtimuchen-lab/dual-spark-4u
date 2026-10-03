#!/usr/bin/env python3
"""Размерные схемы (SVG) по параметрам scad/params.scad: вид сверху, сбоку, спереди.

Скрипт читает числовые присваивания из params.scad (name = value;) и повторяет
производные формулы, чтобы чертёж всегда соответствовал модели.
Запуск: python3 scripts/make_drawings.py  → docs/drawings/*.svg
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PARAMS = ROOT / "scad" / "params.scad"
OUT = ROOT / "docs" / "drawings"


def load_params() -> dict:
    p: dict = {}
    rx = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([-0-9.]+|true|false|\"[a-z]+\")\s*;")
    for line in PARAMS.read_text(encoding="utf-8").splitlines():
        m = rx.match(line)
        if not m:
            continue
        k, v = m.group(1), m.group(2)
        if v in ("true", "false"):
            p[k] = v == "true"
        elif v.startswith('"'):
            p[k] = v.strip('"')
        else:
            p[k] = float(v)
    return p


def derive(p: dict) -> dict:
    d = dict(p)
    d["fan_center_z"] = p["fan_floor_clearance"] + p["fan_size"] / 2
    d["device_base_z"] = (d["fan_center_z"] - p["device_height"] / 2
                          if p["align_device_to_fan"] else p["device_base_z_manual"])
    d["holder_outer_w"] = p["device_width"] + 2 * p["holder_side_clearance"] + 2 * p["holder_wall"]
    d["track_w"] = max(d["holder_outer_w"], p["fan_size"] + 2 * p["holder_wall"])
    d["track_cx"] = d["track_w"] / 2
    d["y_fan_front"] = p["bracket_t"]
    d["y_duct_in"] = d["y_fan_front"] + p["fan_thickness"]
    d["duct_len"] = p["plenum_len"] + p["nozzle_len"]
    d["y_duct_out"] = d["y_duct_in"] + d["duct_len"]
    d["y_device_front"] = d["y_duct_out"] + p["gasket_t"]
    d["y_device_rear"] = d["y_device_front"] + p["device_depth"]
    d["y_holder_rear"] = d["y_device_rear"] + p["holder_rear_clearance"] + p["back_stop_t"]
    d["y_track_end"] = d["y_device_rear"] + p["rear_free_zone"]
    d["outlet_w"] = p["device_width"] - 2 * p["device_intake_margin_x"]
    d["outlet_z0"] = d["device_base_z"] - p["outlet_under_device"]
    d["outlet_z1"] = d["device_base_z"] + p["device_height"] - p["device_intake_margin_top"] + p["outlet_over_device"]
    d["post_top_z"] = d["device_base_z"] + p["device_height"] + 8
    d["guide_top_z"] = d["device_base_z"] + p["guide_wall_extra_h"]
    d["pair_w"] = 2 * d["track_w"] + p["track_gap"]
    d["track_x0"] = (p["chassis_inner_width"] - d["pair_w"]) / 2
    d["track_x1"] = d["track_x0"] + d["track_w"] + p["track_gap"]
    d["y_origin"] = p["chassis_front_dead_zone"]
    d["depth_needed"] = d["y_origin"] + d["y_track_end"] + p["chassis_rear_dead_zone"]
    return d


class Svg:
    """Минимальный генератор SVG с мм-координатами (масштаб S px/мм)."""

    def __init__(self, w_mm: float, h_mm: float, title: str, scale: float = 2.0, margin: float = 70):
        self.S = scale
        self.m = margin
        self.W = w_mm * scale + 2 * margin
        self.H = h_mm * scale + 2 * margin + 30
        self.h_mm = h_mm
        self.parts: list[str] = []
        self.parts.append(
            f'<text x="{margin}" y="{margin - 40}" font-size="18" font-family="sans-serif" font-weight="bold">{title}</text>')

    # мм → px; ось Y вверх (как Z на виде сбоку/спереди) → переворот
    def X(self, x): return self.m + x * self.S
    def Y(self, y): return self.m + (self.h_mm - y) * self.S

    def rect(self, x, y, w, h, stroke="#222", fill="none", dash=None, sw=1.2, label=None, lx=None, ly=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.parts.append(
            f'<rect x="{self.X(x):.1f}" y="{self.Y(y + h):.1f}" width="{w * self.S:.1f}" height="{h * self.S:.1f}" '
            f'stroke="{stroke}" fill="{fill}" stroke-width="{sw}"{d}/>')
        if label:
            self.text(lx if lx is not None else x + w / 2, ly if ly is not None else y + h / 2, label, anchor="middle")

    def poly(self, pts, stroke="#222", fill="none", sw=1.2, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        s = " ".join(f"{self.X(x):.1f},{self.Y(y):.1f}" for x, y in pts)
        self.parts.append(f'<polygon points="{s}" stroke="{stroke}" fill="{fill}" stroke-width="{sw}"{d}/>')

    def line(self, x1, y1, x2, y2, stroke="#222", sw=1, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.parts.append(
            f'<line x1="{self.X(x1):.1f}" y1="{self.Y(y1):.1f}" x2="{self.X(x2):.1f}" y2="{self.Y(y2):.1f}" '
            f'stroke="{stroke}" stroke-width="{sw}"{d}/>')

    def circle(self, x, y, r, stroke="#222", fill="none", sw=1.2):
        self.parts.append(
            f'<circle cx="{self.X(x):.1f}" cy="{self.Y(y):.1f}" r="{r * self.S:.1f}" stroke="{stroke}" fill="{fill}" stroke-width="{sw}"/>')

    def text(self, x, y, s, size=11, anchor="start", color="#111", rotate=None):
        tr = f' transform="rotate({rotate} {self.X(x):.1f} {self.Y(y):.1f})"' if rotate else ""
        self.parts.append(
            f'<text x="{self.X(x):.1f}" y="{self.Y(y):.1f}" font-size="{size}" font-family="sans-serif" '
            f'text-anchor="{anchor}" fill="{color}"{tr}>{s}</text>')

    def dim_h(self, x1, x2, y, label, off=0, color="#b00"):
        """горизонтальный размер между x1..x2 на высоте y (мм)"""
        self.line(x1, y, x2, y, stroke=color, sw=0.8)
        for x in (x1, x2):
            self.line(x, y - 2 / self.S * 2, x, y + 2 / self.S * 2, stroke=color, sw=0.8)
        self.text((x1 + x2) / 2, y + 2 + off, label, size=10, anchor="middle", color=color)

    def dim_v(self, y1, y2, x, label, color="#b00"):
        self.line(x, y1, x, y2, stroke=color, sw=0.8)
        for y in (y1, y2):
            self.line(x - 2, y, x + 2, y, stroke=color, sw=0.8)
        self.text(x + 2, (y1 + y2) / 2, label, size=10, anchor="start", color=color, rotate=-90)

    def save(self, path: Path):
        body = "\n".join(self.parts)
        path.write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.W:.0f}" height="{self.H:.0f}" '
            f'viewBox="0 0 {self.W:.0f} {self.H:.0f}" style="background:#fff">\n'
            f'<rect width="100%" height="100%" fill="#fff"/>\n{body}\n</svg>\n', encoding="utf-8")


def tm(v, p, key):
    """метка TO_MEASURE для параметров корпуса"""
    return f"{v:g} (TO_MEASURE)" if key.startswith("chassis") else f"{v:g}"


def draw_top(d: dict):
    cw, cd = d["chassis_inner_width"], d["chassis_inner_depth"]
    s = Svg(cw, cd, "ВИД СВЕРХУ — два трака в 4U (X: ширина, Y: глубина, перед внизу). Размеры в мм", scale=1.6)
    # ось Y на чертеже: 0 внизу = передняя стенка
    s.rect(0, 0, cw, cd, stroke="#000", sw=1.6)
    s.rect(0, cd - d["chassis_front_dead_zone"], cw, d["chassis_front_dead_zone"], fill="#fde", stroke="#c66", dash="4,3")
    s.text(2, cd - d["chassis_front_dead_zone"] / 2, "передняя мёртвая зона (дверца/фильтр) TO_MEASURE", size=9)
    s.rect(0, 0, cw, d["chassis_rear_dead_zone"], fill="#fde", stroke="#c66", dash="4,3")
    s.text(2, d["chassis_rear_dead_zone"] / 2, "задняя панель TO_MEASURE", size=9)

    def Y(y_local):  # локальный y трака (0 = всасывание) → чертёжный (0 = зад корпуса)
        return cd - d["y_origin"] - y_local

    for x0, name in ((d["track_x0"], "ТРАК 1"), (d["track_x1"], "ТРАК 2")):
        cx = x0 + d["track_cx"]
        fw = d["fan_size"] + 2 * d["holder_wall"]
        # кронштейн + вентилятор
        s.rect(cx - fw / 2, Y(d["bracket_t"]), fw, d["bracket_t"], fill="#ccc")
        s.rect(cx - d["fan_size"] / 2, Y(d["y_duct_in"]), d["fan_size"], d["fan_thickness"], fill="#9cf", label="FAN 140×25")
        # воздуховод: фланец входа, пленум, сопло (трапеция), фланец выхода
        s.rect(cx - fw / 2, Y(d["y_duct_in"] + d["duct_flange_t"]), fw, d["duct_flange_t"], fill="#ddd")
        s.rect(cx - fw / 2, Y(d["y_duct_in"] + d["plenum_len"]), fw, d["plenum_len"] - d["duct_flange_t"], fill="#eef", label="plenum")
        yn0, yn1 = d["y_duct_in"] + d["plenum_len"], d["y_duct_out"] - d["duct_flange_t"]
        ow = d["outlet_w"] + 2 * d["duct_wall"]
        s.poly([(cx - fw / 2, Y(yn0)), (cx + fw / 2, Y(yn0)), (cx + ow / 2, Y(yn1)), (cx - ow / 2, Y(yn1))], fill="#eef")
        s.text(cx, Y((yn0 + yn1) / 2), "nozzle", size=10, anchor="middle")
        s.rect(x0, Y(d["y_duct_out"]), d["holder_outer_w"], d["duct_flange_t"], fill="#ddd")
        # holder
        s.rect(x0, Y(d["y_holder_rear"]), d["holder_outer_w"], d["y_holder_rear"] - d["y_duct_out"], fill="none", stroke="#555", dash="3,2")
        # устройство
        dx = x0 + d["track_cx"] - d["device_width"] / 2
        s.rect(dx, Y(d["y_device_rear"]), d["device_width"], d["device_depth"], fill="#444", stroke="#000")
        s.text(cx, Y(d["y_device_front"] + d["device_depth"] / 2), f"MSI EdgeXpert {name[-1]}", size=11, anchor="middle", color="#fff")
        s.text(cx, Y(d["y_device_front"] + d["device_depth"] / 2) - 12, "151×151×52", size=9, anchor="middle", color="#fff")
        # зона выхлопа
        s.rect(dx, Y(d["y_track_end"]), d["device_width"], d["rear_free_zone"], fill="#fca", stroke="#e73", dash="3,2", label="выхлоп →")
        # стрелки потока
        s.text(cx, Y(-8), "▲ холодный воздух", size=9, anchor="middle", color="#06c")

    # размеры
    s.dim_h(0, cw, -12, f"внутренняя ширина корпуса {cw:g} TO_MEASURE")
    s.dim_h(d["track_x0"], d["track_x0"] + d["track_w"], -24, f"трак {d['track_w']:g}")
    s.dim_h(d["track_x0"] + d["track_w"], d["track_x1"], -24, f"{d['track_gap']:g}")
    s.dim_h(d["track_x1"], d["track_x1"] + d["track_w"], -24, f"трак {d['track_w']:g}")
    s.dim_h(0, d["track_x0"], -36, f"{d['track_x0']:g}")
    xr = cw + 8
    s.dim_v(Y(0), cd, xr, f"{d['y_origin']:g}")
    s.dim_v(Y(d["y_duct_in"]), Y(0), xr + 14, f"кроншт.+FAN {d['y_duct_in']:g}")
    s.dim_v(Y(d["y_duct_out"]), Y(d["y_duct_in"]), xr, f"duct {d['duct_len']:g}")
    s.dim_v(Y(d["y_device_rear"]), Y(d["y_duct_out"]), xr + 14, f"gasket {d['gasket_t']:g} + MSI {d['device_depth']:g}")
    s.dim_v(Y(d["y_track_end"]), Y(d["y_device_rear"]), xr, f"выхлоп {d['rear_free_zone']:g}")
    s.dim_v(0, Y(d["y_track_end"]), xr + 14, f"{Y(d['y_track_end']):g}")
    s.dim_v(0, cd, xr + 30, f"глубина корпуса {cd:g} TO_MEASURE; нужно ≥ {d['depth_needed']:g}")
    s.save(OUT / "top_view.svg")


def draw_side(d: dict):
    cd, ch = d["chassis_inner_depth"], d["chassis_inner_height"]
    s = Svg(cd, ch, "ВИД СБОКУ — один трак (Y: глубина слева направо, Z: высота). Размеры в мм", scale=1.8)
    s.rect(0, 0, cd, ch, stroke="#000", sw=1.6)
    s.rect(0, 0, d["chassis_front_dead_zone"], ch, fill="#fde", stroke="#c66", dash="4,3")
    s.rect(cd - d["chassis_rear_dead_zone"], 0, d["chassis_rear_dead_zone"], ch, fill="#fde", stroke="#c66", dash="4,3")
    o = d["y_origin"]
    fz0 = d["fan_center_z"] - d["fan_size"] / 2
    s.rect(o, 0, d["bracket_t"], fz0 + d["fan_size"] + d["holder_wall"], fill="#ccc")
    s.rect(o + d["y_fan_front"], fz0, d["fan_thickness"], d["fan_size"], fill="#9cf", label="FAN")
    # воздуховод: профиль верхней и нижней стенки (smoothstep)
    yi, yo = o + d["y_duct_in"], o + d["y_duct_out"]
    yn0 = yi + d["plenum_len"]
    yn1 = yo - d["duct_flange_t"]
    top0, bot0 = d["fan_center_z"] + d["fan_size"] / 2, d["fan_center_z"] - d["fan_size"] / 2
    top1, bot1 = d["outlet_z1"] + d["duct_wall"], d["outlet_z0"] - d["duct_wall"]
    n = 24
    pts_top = [(yi, top0), (yn0, top0)]
    pts_bot = [(yi, bot0), (yn0, bot0)]
    for i in range(1, n + 1):
        t = i / n
        u = t * t * (3 - 2 * t)
        y = yn0 + (yn1 - yn0) * t
        pts_top.append((y, top0 + (top1 - top0) * u))
        pts_bot.append((y, bot0 + (bot1 - bot0) * u))
    s.poly(pts_top + [(yo, top1), (yo, bot1)] + list(reversed(pts_bot)), fill="#eef")
    s.text(yi + 10, d["fan_center_z"], "plenum", size=10)
    s.text(yn0 + 8, d["fan_center_z"], "nozzle", size=10)
    s.rect(yo - d["duct_flange_t"], max(0, d["outlet_z0"] - d["duct_flange_t"] - 4), d["duct_flange_t"],
           d["post_top_z"] - max(0, d["outlet_z0"] - d["duct_flange_t"] - 4), fill="#ddd")
    # holder
    hy0, hy1 = yo, o + d["y_holder_rear"]
    s.rect(hy0, 0, hy1 - hy0, d["holder_floor_t"], fill="#bbb")
    s.rect(hy0, 0, d["front_post_len"], d["post_top_z"], fill="#bbb")
    s.rect(hy0 + d["front_post_len"], 0, hy1 - hy0 - d["front_post_len"], d["guide_top_z"], fill="#ccc", dash="2,2")
    ry0 = o + d["y_device_front"] + d["rail_front_setback"]
    rl = d["device_depth"] - d["rail_front_setback"] - d["rail_rear_setback"]
    s.rect(ry0, 0, rl, d["device_base_z"], fill="#999", label="рельсы 4×20 / каналы 20")
    # устройство
    dy = o + d["y_device_front"]
    s.rect(dy, d["device_base_z"], d["device_depth"], d["device_height"], fill="#444", label="MSI EdgeXpert", lx=None)
    s.text(dy + d["device_depth"] / 2, d["device_base_z"] + d["device_height"] / 2, "MSI EdgeXpert", anchor="middle", color="#fff")
    s.rect(dy + d["device_depth"], d["device_base_z"], d["rear_free_zone"], d["device_height"], fill="#fca", stroke="#e73", dash="3,2", label="выхлоп →")
    # размеры
    xr = cd + 6
    s.dim_v(0, d["fan_center_z"], xr, f"ось вентилятора z={d['fan_center_z']:g}")
    s.dim_v(0, d["device_base_z"], xr + 14, f"дно MSI z={d['device_base_z']:g}")
    s.dim_v(d["device_base_z"], d["device_base_z"] + d["device_height"], xr + 14, f"MSI {d['device_height']:g}")
    s.dim_v(0, fz0 + d["fan_size"], xr + 28, f"верх FAN {fz0 + d['fan_size']:g}")
    s.dim_v(0, ch, xr + 42, f"внутр. высота {ch:g} TO_MEASURE")
    s.dim_h(0, o, -10, f"{o:g} TO_MEASURE")
    s.dim_h(o, yi, -22, f"{d['y_duct_in']:g}")
    s.dim_h(yi, yo, -10, f"duct {d['duct_len']:g} = plenum {d['plenum_len']:g} + nozzle {d['nozzle_len']:g}")
    s.dim_h(yo, dy, -22, f"{d['gasket_t']:g}")
    s.dim_h(dy, dy + d["device_depth"], -10, f"MSI {d['device_depth']:g}")
    s.dim_h(dy + d["device_depth"], o + d["y_track_end"], -22, f"{d['rear_free_zone']:g}")
    s.dim_h(0, cd, -36, f"глубина {cd:g} TO_MEASURE (нужно ≥ {d['depth_needed']:g})")
    s.save(OUT / "side_view.svg")


def draw_front(d: dict):
    cw, ch = d["chassis_inner_width"], d["chassis_inner_height"]
    s = Svg(cw, ch, "ВИД СПЕРЕДИ — плоскость вентиляторов; MSI и holder показаны пунктиром за ними. Размеры в мм", scale=1.8)
    s.rect(0, 0, cw, ch, stroke="#000", sw=1.6)
    for x0 in (d["track_x0"], d["track_x1"]):
        cx = x0 + d["track_cx"]
        fw = d["fan_size"] + 2 * d["holder_wall"]
        fz0 = d["fan_center_z"] - d["fan_size"] / 2
        s.rect(cx - fw / 2, fz0 - d["holder_wall"], fw, fw, fill="#ddd")
        s.rect(cx - d["fan_size"] / 2, fz0, d["fan_size"], d["fan_size"], fill="#9cf")
        s.circle(cx, d["fan_center_z"], d["fan_open_dia"] / 2, stroke="#036")
        s.circle(cx, d["fan_center_z"], d["fan_hub_dia"] / 2, stroke="#036", fill="#9ab")
        for sx in (-1, 1):
            for sz in (-1, 1):
                s.circle(cx + sx * d["fan_hole_pitch"] / 2, d["fan_center_z"] + sz * d["fan_hole_pitch"] / 2, 2.25, stroke="#036")
        # holder + MSI за вентилятором
        s.rect(x0, 0, d["holder_outer_w"], d["post_top_z"], stroke="#555", dash="3,2")
        s.rect(cx - d["device_width"] / 2, d["device_base_z"], d["device_width"], d["device_height"], stroke="#e73", dash="4,2", fill="none")
        s.rect(cx - d["outlet_w"] / 2, d["outlet_z0"], d["outlet_w"], d["outlet_z1"] - d["outlet_z0"], stroke="#06c", dash="2,2", fill="none")
        s.text(cx, d["outlet_z0"] - 6, f"выход duct {d['outlet_w']:g}×{d['outlet_z1'] - d['outlet_z0']:g}", size=9, anchor="middle", color="#06c")
        s.text(cx, d["device_base_z"] + d["device_height"] + 3, "MSI 151×52", size=9, anchor="middle", color="#e73")
    s.dim_h(0, cw, -10, f"внутренняя ширина {cw:g} TO_MEASURE")
    s.dim_h(d["track_x0"], d["track_x0"] + d["track_w"], -22, f"{d['track_w']:g}")
    s.dim_h(d["track_x0"] + d["track_w"], d["track_x1"], -22, f"{d['track_gap']:g}")
    s.dim_h(d["track_x1"], d["track_x1"] + d["track_w"], -22, f"{d['track_w']:g}")
    cx0 = d["track_x0"] + d["track_cx"]
    s.dim_h(cx0 - d["fan_hole_pitch"] / 2, cx0 + d["fan_hole_pitch"] / 2, d["fan_center_z"] + d["fan_size"] / 2 + 8, f"{d['fan_hole_pitch']:g}")
    xr = cw + 6
    s.dim_v(0, d["fan_center_z"], xr, f"z={d['fan_center_z']:g}")
    s.dim_v(0, ch, xr + 16, f"{ch:g} TO_MEASURE")
    s.save(OUT / "front_view.svg")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    d = derive(load_params())
    draw_top(d)
    draw_side(d)
    draw_front(d)
    print("drawings written to", OUT)
    print(f"track {d['track_w']:g} x {d['y_track_end']:g}; pair {d['pair_w']:g}; depth needed {d['depth_needed']:g}")


if __name__ == "__main__":
    main()
