/*
 * assembly.scad — 5U-модуль: панель ЦМО ФП-5 + 2 × (решётка, Arctic P14 Pro PST,
 * воздуховод, holder, MSI EdgeXpert) + base_plate + 2 уголка + зона электроники.
 *
 * part:
 *   module     — полная сборка (требует все TO_MEASURE: rack_checks)
 *   exploded   — сборка с раздвинутыми по Y деталями одного трака
 *   track      — один трак без панели/плиты (локальные координаты, без TO_MEASURE)
 *   printables — печатные детали одного трака, разложенные на плоскости
 *
 * Координаты модуля: x=0 — ось; y=0 — задняя плоскость панели; z=0 — верх полки.
 * Детали трака имеют локальный z от верха плиты → translate по hz0.
 */

include <params.scad>
use <lib/shapes.scad>
use <edgexpert_holder.scad>
use <duct.scad>
use <front_panel.scad>
use <base_plate.scad>
use <ctrl_bezel.scad>

part = "module"; // [module, exploded, track, printables]
explode_gap = 60;
show_devices = true;
show_fans = true;
show_ducts = true;
show_panel = true;
show_grilles = true;
show_baffles = true;
show_bezels = true;

geo_report();

// Один трак в локальных координатах (x=0 — левая грань holder'а, z=0 — верх плиты)
module track(explode = 0) {
    if (show_fans)
        translate([track_cx, y_fan_front - explode, fan_center_zl])
            fan_mockup(fan_size, fan_thickness, fan_hub_dia, fan_hole_pitch);
    if (show_ducts) color([0.75, 0.78, 0.82, 0.85]) duct_full();
    color([0.55, 0.58, 0.62]) translate([0, y_holder_front + explode, 0]) holder();
    if (show_baffles) color([0.9, 0.5, 0.2]) translate([0, y_holder_front + explode, 0]) baffle();
    if (show_devices)
        translate([device_x0, y_device_front + 2 * explode, device_base_zl])
            device_mockup(device_width, device_depth, device_height,
                          device_foot_dia, device_foot_inset, device_foot_height,
                          device_bottom_vent_w, device_bottom_vent_d, device_bottom_vent_front_offset,
                          device_intake_margin_x, device_intake_margin_top, device_intake_margin_bot);
    %translate([device_x0, y_device_rear, device_base_zl])
        color([1, 0.4, 0.2, 0.15]) cube([device_width, rear_free_zone, device_height]);
}

module grille_mockup(cx) {
    // проволочная решётка ARCTIC 140 перед панелью (условно — кольцо + спицы)
    color([0.2, 0.2, 0.2])
    translate([cx, -panel_t - grille_t, fan_center_z]) rotate([-90, 0, 0]) {
        difference() { cylinder(h = grille_t, d = fan_size, $fn = 96); translate([0, 0, -1]) cylinder(h = grille_t + 2, d = fan_size - 4, $fn = 96); }
        for (a = [0 : 30 : 150]) rotate([0, 0, a]) translate([-fan_size / 2, -1, 0]) cube([fan_size, 2, grille_t]);
        for (d = [40, 80, 120]) difference() { cylinder(h = grille_t, d = d, $fn = 64); translate([0, 0, -1]) cylinder(h = grille_t + 2, d = d - 3, $fn = 64); }
    }
}

module bezels() {
    // рамки контроллеров на лицевой стороне панели, над каждым вентилятором
    for (cx = fan_cx_from_center)
        translate([cx - bezel_w / 2, -panel_t, fan_center_z + fan_size / 2 + bezel_fan_clearance])
            mirror([0, 1, 0]) { color([0.55, 0.58, 0.62]) bezel(); ctrl_mockup(); }
}

module electronics_zone() {
    // по одной полосе на сторону: слева WAGO 221-413, справа DC-гнездо (контроллеры — на панели)
    for (sx = [-1, 1])
        %color([0.2, 0.8, 0.3, 0.35])
            translate([sx > 0 ? ctrl_zone_x_in : -(ctrl_zone_x_in + ctrl_zone_w), ctrl_zone_y0, base_plate_t])
                cube([ctrl_zone_w, ctrl_zone_d, 25]);
}

module module_assembly(explode = 0) {
    fit_report();
    if (show_panel) panel();
    if (show_grilles) for (cx = fan_cx_from_center) grille_mockup(cx);
    if (show_bezels) bezels();
    base_plate();
    for (sx = [-1, 1])
        translate([sx * bracket_cx - bracket_w / 2, base_plate_front_gap, base_plate_t])
            color([0.55, 0.58, 0.62]) panel_bracket();
    // стойка DC-гнезда: гнездо смотрит назад (штекер из горячей зоны шкафа)
    translate([ctrl_zone_x_in + ctrl_zone_w / 2 + 15, ctrl_zone_y1 - 10 + 7, base_plate_t]) rotate([0, 0, 180])
        color([0.55, 0.58, 0.62]) dc_jack_bracket();
    electronics_zone();
    for (cx = fan_cx_from_center)
        translate([cx - track_cx, 0, hz0]) track(cx > 0 ? explode : 0);
    // полка (условно) и ось шкафа
    %color([0.5, 0.5, 0.5, 0.2]) translate([-rack_opening_w / 2, -panel_t, -3]) cube([rack_opening_w, shelf_depth, 3]);
}

module printables() {
    holder();
    translate([0, holder_outer_w + 40, 0]) color([0.9, 0.5, 0.2]) baffle();
    translate([holder_outer_w + 30, -y_duct_in, 0]) duct_full();
    translate([holder_outer_w + 30, y_track_end + 40, 0]) panel_bracket();
    translate([holder_outer_w + 100, y_track_end + 40, 0]) dc_jack_bracket();
    translate([holder_outer_w + 160, y_track_end + 40, 0]) bezel();
}

if (part == "track") track(0);
else if (part == "exploded") module_assembly(explode_gap);
else if (part == "printables") printables();
else module_assembly(0);
