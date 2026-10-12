/*
 * assembly.scad — 5U-модуль: панель ЦМО ФП-5 + 2 × (решётка ARCTIC, Arctic P14 Pro PST,
 * воздуховод, holder, MSI EdgeXpert) + base_plate (+ 2 уголка, если use_panel_brackets) + WAGO/DC-гнездо
 * (+ рамки термоконтроллеров на лицевой стороне, когда габариты контроллера измерены).
 *
 * part:
 *   module     — полная сборка
 *   exploded   — сборка, правый трак раздвинут по Y
 *   track      — один трак без панели и плиты (локальные координаты)
 *   printables — печатные детали одного трака на плоскости
 *
 * Координаты модуля: x=0 — ось; y=0 — задняя плоскость панели; z=0 — верх полки.
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
show_bezels = true;   // рисуются только при известных ctrl_w/h/d
// Выбор группы деталей для поштучного экспорта (scripts/export_assembly_view.py):
// all | panel | grilles | plate | brackets | holders | baffles | ducts | msi | fans | bezels
only = "all";
function show(g) = only == "all" || only == g;

geo_report();

module track(explode = 0) {
    if (show_fans && show("fans"))
        translate([track_cx, y_fan_front - explode, fan_center_zl])
            fan_mockup(fan_size, fan_thickness, fan_hub_dia, fan_hole_pitch);
    if (show_ducts && show("ducts")) color([0.75, 0.78, 0.82, 0.85]) duct_full();
    if (show("holders")) color([0.55, 0.58, 0.62]) translate([0, y_holder_front + explode, 0]) holder();
    if (show_baffles && show("baffles")) color([0.9, 0.5, 0.2]) translate([0, y_holder_front + explode, 0]) baffle();
    if (show_devices && show("msi"))
        translate([device_x0, y_device_front + 2 * explode, device_base_zl]) msi();
    %translate([device_x0 + (device_width - rear_exhaust_w) / 2, y_device_rear,
                device_top_zl - rear_exhaust_top - rear_exhaust_h])
        color([1, 0.4, 0.2, 0.15]) cube([rear_exhaust_w, rear_free_zone, rear_exhaust_h]);
}

module grille_mockup(cx) {
    color([0.2, 0.2, 0.2])
    translate([cx, -panel_t - grille_depth, fan_center_z]) rotate([-90, 0, 0]) {
        difference() { cylinder(h = grille_depth, d = fan_size, $fn = 96);
                       translate([0, 0, -1]) cylinder(h = grille_depth + 2, d = fan_size - 4, $fn = 96); }
        for (a = [0 : 30 : 150]) rotate([0, 0, a]) translate([-fan_size / 2, -1, 0]) cube([fan_size, 2, grille_stack_t]);
        for (d = [40, 80, 120]) difference() { cylinder(h = grille_stack_t, d = d, $fn = 64);
                                               translate([0, 0, -1]) cylinder(h = 3, d = d - 3, $fn = 64); }
    }
}

module bezels() {
    for (cx = fan_cx_from_center)
        translate([cx - bezel_w / 2, -panel_t, bezel_z0_panel - shelf_top_z])
            mirror([0, 1, 0]) { color([0.55, 0.58, 0.62]) bezel(); ctrl_mockup(); probe_mockup(); }
}

// Не деталь: разметка места на плите — слева WAGO 221-413 («+», «−»), справа
// DC-гнездо 12 В. Тонкая площадка с подписью, чтобы на рендерах не выглядела блоком.
module electronics_zone() {
    for (sx = [-1, 1]) {
        x0 = sx > 0 ? ctrl_zone_x_in : -(ctrl_zone_x_in + ctrl_zone_w);
        %color([0.2, 0.8, 0.3, 0.35])
            translate([x0, ctrl_zone_y0, base_plate_t]) cube([ctrl_zone_w, ctrl_zone_d, 1]);
        color([0.1, 0.45, 0.15])
            translate([x0 + ctrl_zone_w / 2, ctrl_zone_y0 + ctrl_zone_d / 2, base_plate_t + 1])
                rotate([0, 0, 90]) linear_extrude(height = 0.6)
                    text(sx < 0 ? "WAGO 221-413" : "DC 12V", size = 9, font = "Liberation Sans:style=Bold",
                         halign = "center", valign = "center");
    }
}

module module_assembly(explode = 0) {
    fit_report();
    if (show_panel && show("panel")) panel();
    if (show_grilles && show("grilles")) for (cx = fan_cx_from_center) grille_mockup(cx);
    if (show_bezels && ctrl_known && show("bezels")) bezels();
    if (show("plate")) base_plate();
    if (use_panel_brackets && show("brackets"))
        for (sx = [-1, 1])
            translate([sx * bracket_cx - bracket_w / 2, base_plate_front_gap, base_plate_t])
                color([0.55, 0.58, 0.62]) panel_bracket();
    if (known(dc_jack_d) && show("brackets"))
        translate([dc_bracket_pos[0] + 15, dc_bracket_pos[1] + 7, base_plate_t]) rotate([0, 0, 180])
            color([0.55, 0.58, 0.62]) dc_jack_bracket();
    if (only == "all") electronics_zone();
    for (cx = fan_cx_from_center)
        translate([cx - track_cx, 0, hz0]) track(cx > 0 ? explode : 0);
    %color([0.5, 0.5, 0.5, 0.2]) translate([-rack_opening_w / 2, 0, -3]) cube([rack_opening_w, shelf_depth, 3]);
}

module printables() {
    holder();
    translate([0, holder_depth + 30, 0]) color([0.9, 0.5, 0.2]) baffle();
    translate([holder_outer_w + 30, -y_duct_in, 0]) duct_full();
    if (use_panel_brackets) translate([holder_outer_w + 30, y_track_end + 40, 0]) panel_bracket();
}

if (part == "track") track(0);
else if (part == "exploded") module_assembly(explode_gap);
else if (part == "printables") printables();
else module_assembly(0);
