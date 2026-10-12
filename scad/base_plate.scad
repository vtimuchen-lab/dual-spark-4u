/*
 * base_plate.scad — алюминиевая плита 3 мм 5U-модуля (покупной лист, сверловка
 * по чертежу docs/drawings/base_plate.svg) + печатные детали:
 *   part="panel_bracket"   — уголок panel↔base_plate (PETG/ASA, M4), 2 шт. — ОПЦИЯ:
 *                            по умолчанию не печатается (use_panel_brackets = false)
 *   part="dc_jack_bracket" — стойка под ПАНЕЛЬНОЕ гнездо 12 В 5.5×2.5 — только при
 *                            dc_jack_inline = false (сейчас гнездо кабельное, стойка не нужна)
 *   part="base_plate"      — сама плита с отверстиями (нужны rack_opening_w, shelf_depth)
 *   part="base_plate_2d"   — 2D-контур для чертежа
 *
 * Координаты модуля: x=0 — ось; y=0 — задняя плоскость панели; z=0 — верх полки.
 */

include <params.scad>
use <lib/shapes.scad>

part = "panel_bracket"; // [panel_bracket, dc_jack_bracket, base_plate, base_plate_2d]

// Сверловка плиты — списки plate_*_holes считаются в params.scad (общие с чертежом).

module base_plate_2d() {
    rack_checks();
    difference() {
        translate([-base_plate_w / 2, base_plate_y0]) square([base_plate_w, base_plate_d]);
        for (h = plate_holder_holes) translate(h) circle(d = m4_clear_d, $fn = 24);
        for (h = plate_bracket_holes) translate(h) circle(d = m4_clear_d, $fn = 24);
        for (h = plate_ctrl_holes) translate(h) circle(d = m3_clear_d, $fn = 16);
        for (h = plate_dc_holes) translate(h) circle(d = m3_clear_d, $fn = 16);
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
    assert(!dc_jack_inline, "NOT_NEEDED: гнездо DC кабельное (dc_jack_inline = true) — стойка не нужна");
    assert(known(dc_jack_d), "TO_MEASURE: dc_jack_d (п.15) — посадочный диаметр панельного DC-гнезда");
    h = 30; w = 30; d = 20; t = 4;
    difference() {
        union() { cube([w, t, h]); cube([w, d, t]); }
        translate([w / 2, -0.01, h - 12]) rotate([-90, 0, 0]) cylinder(h = t + 0.02, d = dc_jack_d);
        for (sx = [-1, 1]) translate([w / 2 + sx * 10, d - 7, -0.01]) cylinder(h = t + 0.02, d = m3_clear_d);
    }
}

if (part == "base_plate") base_plate();
else if (part == "base_plate_2d") base_plate_2d();
else if (part == "dc_jack_bracket") dc_jack_bracket();
else panel_bracket();
