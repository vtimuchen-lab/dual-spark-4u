/*
 * front_panel.scad — фронтальная панель ЦМО ФП-5 (покупная, сталь RAL 7035)
 * с разметкой: два выреза Ø fan_open_dia + по 4 паза M4 на квадрате 124.5,
 * над каждым вентилятором — 2 × Ø3.4 под лапки рамки контроллера (ctrl_bezel)
 * и Ø12 под втулку кабелей рядом с рамкой.
 * Деталь НЕ печатается — модель нужна для сборки и для чертежа
 * docs/drawings/panel_fp5.svg (генерируется scripts/make_drawings.py).
 *
 * Координаты модуля: x=0 — ось панели; y=0 — задняя плоскость панели
 * (лист занимает y ∈ [−panel_t, 0], отбортовка — y ∈ [0, panel_fold] по
 * периметру); z=0 — верх полки. Нижний край панели на z = −shelf_top_z.
 *
 * Требует TO_MEASURE: shelf_top_z, panel_t (rack_checks()).
 */

include <params.scad>
use <lib/shapes.scad>

part = "panel"; // [panel, panel_2d]

module panel_cutouts_2d() {
    // в координатах панели: x от оси, z от нижнего края
    for (cx = fan_cx_from_center) {
        translate([cx, fan_center_z_panel]) circle(d = fan_open_dia, $fn = 120);
        for (sx = [-1, 1], sz = [-1, 1])
            translate([cx + sx * fan_hole_pitch / 2, fan_center_z_panel + sz * fan_hole_pitch / 2])
                // паз ±fan_hole_tol по диагонали (допуск межцентрового 124.5/125)
                rotate(45 * sx * sz) slot2d(fan_hole_dia + 2 * fan_hole_tol, fan_hole_dia);
        // рамка контроллера над вентилятором: лапки (винт M3 сзади) и втулка кабелей
        for (sx = [-1, 1])
            translate([cx + sx * bezel_lug_dx, bezel_cz_panel]) circle(d = m3_clear_d, $fn = 24);
        translate([cx + sign(cx) * cable_hole_side * cable_hole_dx, bezel_cz_panel])
            circle(d = cable_hole_d, $fn = 48);
    }
}

module panel_outline_2d() { translate([-panel_w / 2, 0]) square([panel_w, panel_h]); }

module panel_2d() {
    rack_checks();
    difference() { panel_outline_2d(); panel_cutouts_2d(); }
}

module panel() {
    rack_checks();
    color(panel_color) translate([0, 0, -shelf_top_z]) {
        // лист
        rotate([90, 0, 0]) linear_extrude(height = panel_t)
            difference() { panel_outline_2d(); panel_cutouts_2d(); }
        // отбортовка (периметр, назад на panel_fold)
        for (sx = [-1, 1])
            translate([sx * (panel_w / 2 - panel_t / 2) - panel_t / 2, 0, 0])
                cube([panel_t, panel_fold, panel_h]);
        for (z0 = [0, panel_h - panel_t])
            translate([-panel_w / 2, 0, z0]) cube([panel_w, panel_fold, panel_t]);
    }
}

echo(str("[PANEL] ", panel_w, " x ", panel_h, "; cutouts Ø", fan_open_dia, " at x=±", track_pitch / 2,
         ", z=", fan_center_z_panel, " from bottom edge (allowed ", fan_center_z_panel_min, "..",
         fan_center_z_panel_max, "); holes 4x M4 slots ±", fan_hole_tol, " on ", fan_hole_pitch));
echo(str("[PANEL] bezel lugs Ø", m3_clear_d, " at x=±", track_pitch / 2, "±", bezel_lug_dx, ", z=", bezel_cz_panel,
         "; cable holes Ø", cable_hole_d, " at x=±(", track_pitch / 2 + cable_hole_side * cable_hole_dx, "), z=", bezel_cz_panel));

if (part == "panel_2d") panel_2d();
else panel();
