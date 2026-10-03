/*
 * assembly.scad — сборка: существующий 4U-корпус (макет, TO_MEASURE) +
 * два трака [кронштейн + 140-мм вентилятор + воздуховод + holder + MSI EdgeXpert].
 *
 * part:
 *   assembly  — оба трака в корпусе
 *   track     — один трак (локальные координаты)
 *   exploded  — один трак, детали раздвинуты по Y (explode_gap)
 *   printables— все печатные детали одного трака, разложенные на плоскости
 */

include <params.scad>
use <lib/shapes.scad>
use <edgexpert_holder.scad>
use <fan_bracket.scad>
use <duct.scad>

part = "assembly"; // [assembly, track, exploded, printables]
explode_gap = 60;
show_chassis = true;
show_devices = true;
show_fans = true;
show_ducts = true;
show_controller_zone = true;

fit_report();

module track(explode = 0) {
    // Кронштейн
    color([0.55, 0.58, 0.62]) translate([0, -2 * explode, 0]) bracket();
    // Вентилятор
    if (show_fans)
        translate([track_cx, y_fan_front - explode, fan_center_z])
            fan_mockup(fan_size, fan_thickness, fan_hub_dia, fan_hole_pitch);
    // Воздуховод
    if (show_ducts) color([0.75, 0.78, 0.82, 0.85]) duct_full();
    // Holder (его локальный y=0 = y_holder_front)
    color([0.55, 0.58, 0.62]) translate([0, y_holder_front + explode, 0]) holder();
    // Устройство
    if (show_devices)
        translate([device_x0, y_device_front + 2 * explode, device_base_z])
            device_mockup(device_width, device_depth, device_height,
                          device_foot_dia, device_foot_inset, device_foot_height,
                          device_bottom_vent_w, device_bottom_vent_d, device_bottom_vent_front_offset,
                          device_intake_margin_x, device_intake_margin_top, device_intake_margin_bot);
    // Зона свободного выхлопа (полупрозрачная)
    %translate([device_x0, y_device_rear, device_base_z])
        color([1, 0.4, 0.2, 0.15]) cube([device_width, rear_free_zone, device_height]);
}

module chassis_mockup() {
    // дно
    color([0.6, 0.6, 0.62, 0.5]) translate([0, 0, -chassis_floor_t])
        cube([chassis_inner_width, chassis_inner_depth, chassis_floor_t]);
    // стенки (тонкие, прозрачные)
    %color([0.6, 0.6, 0.62, 0.25]) {
        translate([-1, 0, 0]) cube([1, chassis_inner_depth, chassis_inner_height]);
        translate([chassis_inner_width, 0, 0]) cube([1, chassis_inner_depth, chassis_inner_height]);
        translate([0, chassis_inner_depth, 0]) cube([chassis_inner_width, 1, chassis_inner_height]);
        translate([0, -1, 0]) cube([chassis_inner_width, 1, chassis_inner_height]);
    }
    // мёртвые зоны передней панели / задней панели
    %color([1, 0, 0, 0.12]) translate([0, 0, 0]) cube([chassis_inner_width, chassis_front_dead_zone, chassis_inner_height]);
    %color([1, 0, 0, 0.12]) translate([0, chassis_inner_depth - chassis_rear_dead_zone, 0])
        cube([chassis_inner_width, chassis_rear_dead_zone, chassis_inner_height]);
}

module controller_zone() {
    // Рекомендуемое место PWM-контроллера/распределителя: в холодной зоне у
    // передних углов, вне выхлопа. Размер условный 80×50.
    %color([0.2, 0.8, 0.3, 0.3])
        translate([2, y_track_origin + 5, 0]) cube([min(track_x0 - 4, 80), 60, 25]);
}

module assembly() {
    if (show_chassis) chassis_mockup();
    translate([track_x0, y_track_origin, 0]) track();
    translate([track_x1, y_track_origin, 0]) track();
    if (show_controller_zone) controller_zone();
}

module printables() {
    // раскладка печатных деталей одного трака для обзора (не для слайсера)
    translate([0, 0, 0]) holder();
    translate([holder_outer_w + 30, -y_holder_front, 0]) rotate([0, 0, 0]) duct_full();
    translate([holder_outer_w + 30, 0, 0]) translate([0, y_track_end - y_holder_front + 40, 0]) bracket();
}

if (part == "track") track(0);
else if (part == "exploded") track(explode_gap);
else if (part == "printables") printables();
else assembly();
