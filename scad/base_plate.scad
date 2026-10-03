/*
 * base_plate.scad — алюминиевая плита 3 мм 5U-модуля (покупной лист, сверловка
 * по чертежу docs/drawings/base_plate.svg) + печатные детали:
 *   part="panel_bracket"   — уголок panel↔base_plate (PETG/ASA, M4), 2 шт.
 *   part="dc_jack_bracket" — стойка под панельное гнездо 12 В 5.5×2.5, 1 шт.
 *   part="base_plate"      — сама плита с отверстиями (нужны rack_opening_w, shelf_depth)
 *   part="base_plate_2d"   — 2D-контур для чертежа
 *
 * Координаты модуля: x=0 — ось; y=0 — задняя плоскость панели; z=0 — верх полки.
 */

include <params.scad>
use <lib/shapes.scad>

part = "panel_bracket"; // [panel_bracket, dc_jack_bracket, base_plate, base_plate_2d]

// --- Сверловка плиты (x от оси, y от задней плоскости панели) --------------
// Holder'ы: 4 паза M4 каждый (holder_mount_pitch_x/y вокруг центра устройства)
function holder_holes(tx) = [for (sx = [-1, 1], sy = [-1, 1])
    [tx + sx * holder_mount_pitch_x / 2,
     y_device_front + device_depth / 2 + sy * holder_mount_pitch_y / 2]];
track_cxs = fan_cx_from_center;             // ±98 — оси траков
holder_hole_list = concat(holder_holes(track_cxs[0]), holder_holes(track_cxs[1]));
// Уголки: 2 отверстия M4 в горизонтальной полке каждого
bracket_hole_list = [for (sx = [-1, 1], k = [0, 1])
    [sx * bracket_cx, base_plate_y0 + bracket_t + 12 + k * (bracket_d - bracket_t - 24)]];
// Зоны электроники: две полосы (x = ±(ctrl_zone_x_in … +ctrl_zone_w)), сетка M3
// (списки считаются только при известной ширине плиты — иначе undef-предупреждения)
ctrl_hole_list = known(ctrl_zone_w)
    ? [for (sx = [-1, 1], i = [0 : floor((ctrl_zone_w - 4) / ctrl_hole_grid)],
            j = [0 : floor(ctrl_zone_d / ctrl_hole_grid)])
        [sx * (ctrl_zone_x_in + 2 + i * ctrl_hole_grid), ctrl_zone_y0 + j * ctrl_hole_grid]]
    : [];
// Стойка DC-гнезда: 2 × M3 в правой полосе у её заднего края, гнездо смотрит назад
dc_bracket_pos = known(ctrl_zone_w) ? [ctrl_zone_x_in + ctrl_zone_w / 2, ctrl_zone_y1 - 10] : [0, 0];

module base_plate_2d() {
    rack_checks();
    difference() {
        translate([-base_plate_w / 2, base_plate_y0]) square([base_plate_w, base_plate_d]);
        for (h = holder_hole_list) translate(h) circle(d = m4_clear_d, $fn = 24);
        for (h = bracket_hole_list) translate(h) circle(d = m4_clear_d, $fn = 24);
        for (h = ctrl_hole_list) translate(h) circle(d = m3_clear_d, $fn = 16);
        for (sx = [-1, 1]) translate(dc_bracket_pos + [sx * 10, 0]) circle(d = m3_clear_d, $fn = 16);
    }
}

module base_plate() {
    color([0.82, 0.84, 0.86]) linear_extrude(height = base_plate_t) base_plate_2d();
}

// --- Уголок panel ↔ base_plate ---------------------------------------------
// Вертикальная полка — к панели (2 × M4 через панель, гайки снаружи под
// решёткой НЕ нужны: отверстия вне зоны решётки), горизонтальная — к плите.
// Локально: x — ширина уголка, y — глубина (0 = плоскость панели), z — высота (0 = верх плиты).
module panel_bracket() {
    difference() {
        union() {
            cube([bracket_w, bracket_t, bracket_h]);                  // вертикальная полка
            cube([bracket_w, bracket_d, bracket_t]);                  // горизонтальная полка
            // косынка
            translate([bracket_w / 2 - 2.5, 0, 0]) rotate([90, 0, 90]) linear_extrude(height = 5)
                polygon([[bracket_t, bracket_t], [bracket_d - 4, bracket_t], [bracket_t, bracket_h - 4]]);
        }
        for (z = [bracket_t + 12, bracket_h - 12])
            translate([bracket_w / 2, -0.01, z]) rotate([-90, 0, 0]) cylinder(h = bracket_t + 0.02, d = bracket_hole_d);
        for (y = [bracket_t + 12, bracket_d - 12])
            translate([bracket_w / 2, y, -0.01]) cylinder(h = bracket_t + 0.02, d = bracket_hole_d);
    }
}

// --- Стойка DC-гнезда -------------------------------------------------------
module dc_jack_bracket() {
    h = 30; w = 30; d = 20; t = 4;
    difference() {
        union() { cube([w, t, h]); cube([w, d, t]); }
        translate([w / 2, -0.01, h - 12]) rotate([-90, 0, 0]) cylinder(h = t + 0.02, d = dc_jack_hole_d);
        for (sx = [-1, 1]) translate([w / 2 + sx * 10, d - 7, -0.01]) cylinder(h = t + 0.02, d = m3_clear_d);
    }
}

if (part == "base_plate") base_plate();
else if (part == "base_plate_2d") base_plate_2d();
else if (part == "dc_jack_bracket") dc_jack_bracket();
else panel_bracket();
