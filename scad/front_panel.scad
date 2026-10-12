/*
 * front_panel.scad — фронтальная панель ЦМО ФП-5 (покупная, сталь RAL 7035)
 * с разметкой:
 *   - два выреза Ø fan_open_dia на x = ±track_pitch/2, ось = shelf_top_z + 78;
 *   - по 4 паза M4 на межцентровом 124.5…126 вокруг каждого выреза;
 *   - 4 отверстия Ø4.5 под уголки panel↔base_plate;
 *   - над каждым вентилятором — 2 × Ø3.4 под лапки рамки контроллера и Ø12 под
 *     втулку кабелей, ТОЛЬКО если габариты контроллера измерены (ctrl_*);
 *   - отверстия ушей — справочно, если заданы ear_hole_* (не режутся).
 * Деталь не печатается; 2D-разметка — docs/drawings/panel_fp5.svg.
 *
 * Координаты модуля: x=0 — ось панели; y=0 — задняя плоскость панели (лист в
 * y ∈ [−panel_t, 0], отбортовка — в +Y); z=0 — верх полки, низ панели на −shelf_top_z.
 */

include <params.scad>
use <lib/shapes.scad>

part = "panel"; // [panel, panel_2d]

// 2D-вырезы в координатах панели: x от оси, z от нижнего края
module panel_cutouts_2d() {
    for (cx = fan_cx_from_center) {
        translate([cx, fan_center_z_panel]) {
            circle(d = fan_open_dia, $fn = 120);
            for (sx = [-1, 1], sz = [-1, 1])
                fan_hole_slot2d(sx, sz, fan_hole_pitch_min, fan_hole_pitch_max, fan_hole_dia);
        }
        if (ctrl_known) {
            for (sx = [-1, 1]) translate([cx + sx * bezel_lug_dx, bezel_cz_panel]) circle(d = m3_clear_d, $fn = 24);
            translate([cx + sign(cx) * cable_hole_side * cable_hole_dx, bezel_cz_panel]) circle(d = cable_hole_d, $fn = 48);
        }
    }
    // уголки panel↔base_plate
    for (sx = [-1, 1], zl = bracket_hole_zl)
        translate([sx * bracket_cx, shelf_top_z + base_plate_t + zl]) circle(d = bracket_hole_d, $fn = 24);
}

module panel_outline_2d() { translate([-panel_w / 2, 0]) square([panel_w, panel_h]); }

module panel_2d() {
    rack_checks();
    if (ctrl_known) ctrl_checks();
    difference() { panel_outline_2d(); panel_cutouts_2d(); }
}

module panel() {
    rack_checks();
    if (ctrl_known) ctrl_checks();
    color(panel_color) translate([0, 0, -shelf_top_z]) {
        rotate([90, 0, 0]) linear_extrude(height = panel_t)
            difference() { panel_outline_2d(); panel_cutouts_2d(); }
        // отбортовка по периметру (назад на panel_fold); боковая — в пределах проёма стоек
        for (sx = [-1, 1])
            translate([sx * (rack_opening_w / 2 - 1) - 0.6, 0, 0]) cube([1.2, panel_fold, panel_h]);
        for (z0 = [0, panel_h - 1.2])
            translate([-rack_opening_w / 2 + 1, 0, z0]) cube([rack_opening_w - 2, panel_fold, 1.2]);
    }
}

echo(str("[PANEL] cutouts Ø", fan_open_dia, " at x=±", track_pitch / 2, ", z=", fan_center_z_panel,
         " from bottom edge (allowed ", fan_center_z_panel_min, "..", fan_center_z_panel_max,
         "); M4 slots ", fan_hole_pitch_min, "…", fan_hole_pitch_max,
         "; bracket holes x=±", bracket_cx, " z=", [for (zl = bracket_hole_zl) shelf_top_z + base_plate_t + zl],
         ctrl_known ? str("; bezel lugs z=", bezel_cz_panel) : "; bezel holes: after controller is measured"));

if (part == "panel_2d") panel_2d();
else panel();
