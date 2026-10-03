/*
 * edgexpert_holder.scad — подставка (holder) под один MSI EdgeXpert AI,
 * крепится к алюминиевой base_plate 5U-модуля (M4, 4 паза).
 *
 * Адаптация part="holder" из alexliesenfeld/dgx-spark-printables
 * (spark-rack-10/dgx_spark_rack_mount.scad): 5-мм дно, 4 продольных рельса
 * с каналами, низкие боковые направляющие со ступенчатым профилем, два задних
 * стопора на внутренних рельсах, открытый верх. Убраны: 10" панель, rack-ears,
 * отверстия 2×80. Добавлены: передние стойки под фланец воздуховода (heat-set
 * M3), пазы M4, пазы под ремень, гнёзда датчиков, анкеры стяжек, рельсы под
 * ножками MSI (rails_follow_feet), заслонка байпаса (part="baffle").
 *
 * Локальные координаты: x=0 — левая наружная грань, y=0 — передняя грань
 * (задний торец фланца воздуховода), z=0 — ВЕРХ base_plate.
 */

include <params.scad>
use <lib/shapes.scad>

part = "holder"; // [holder, holder_with_device, baffle, holder_with_baffle]

part_checks();

holder_depth = y_holder_rear - y_holder_front;
dev_x = holder_wall + holder_side_clearance;   // x дна устройства
dev_y = gasket_t;                              // y передней грани устройства
floor_w = holder_outer_w - 2 * holder_wall;

// --- Рельсы ----------------------------------------------------------------
// rails_follow_feet: внешние рельсы центрированы под ножками MSI, два внутренних —
// равномерно между ними. Иначе — равномерная сетка rail_w/channel_w как в исходнике.
rail_count = 4;
foot_rail_x_outer = [dev_x + device_foot_inset - rail_w / 2,
                     dev_x + device_width - device_foot_inset - rail_w / 2];
grid_pattern_w = rail_count * rail_w + (rail_count - 1) * channel_w;
grid_side_w    = (floor_w - grid_pattern_w) / 2;
rail_x = rails_follow_feet
    ? [for (i = [0 : rail_count - 1])
        foot_rail_x_outer[0] + i * (foot_rail_x_outer[1] - foot_rail_x_outer[0]) / (rail_count - 1)]
    : [for (i = [0 : rail_count - 1]) holder_wall + grid_side_w + i * (rail_w + channel_w)];
channel_actual = rail_x[1] - rail_x[0] - rail_w;
rail_y0  = dev_y + rail_front_setback;
rail_len = device_depth - rail_front_setback - rail_rear_setback;
stop_idx = [1, 2];
assert(channel_actual >= 12, str("Channels between rails too narrow: ", channel_actual));

module base_plate_holder() {
    difference() {
        translate([holder_wall, 0, 0]) cube([floor_w, holder_depth, holder_floor_t]);
        // Пазы M4 → base_plate (в каналах, доступны при снятом устройстве)
        for (sx = [-1, 1], sy = [-1, 1]) {
            px = holder_outer_w / 2 + sx * holder_mount_pitch_x / 2;
            py = dev_y + device_depth / 2 + sy * holder_mount_pitch_y / 2;
            translate([px, py, -0.01]) linear_extrude(height = holder_floor_t + 0.02)
                rotate(90) slot2d(holder_mount_slot_l, holder_mount_slot_w);
            translate([px, py, holder_floor_t - holder_mount_cbore_h])
                linear_extrude(height = holder_mount_cbore_h + 0.01)
                    rotate(90) slot2d(holder_mount_slot_l + (holder_mount_cbore_d - holder_mount_slot_w),
                                      holder_mount_cbore_d);
        }
        // Анкеры стяжек за устройством
        for (ax = [holder_outer_w * 0.3, holder_outer_w * 0.7], dx = [-6, 6])
            translate([ax + dx, holder_depth - 12, -0.01])
                linear_extrude(height = holder_floor_t + 0.02) square([2.5, 6], center = true);
    }
}

module rails() {
    for (x = rail_x) translate([x, rail_y0, 0]) cube([rail_w, rail_len, rail_top_z]);
}

module side_wall_profile() {
    r = step_r;
    pts = concat(
        [[0, 0], [holder_depth, 0], [holder_depth, guide_top_z - r]],
        [for (i = [1 : 8]) let(a = i * 90 / 8) [holder_depth - r + r * cos(a), guide_top_z - r + r * sin(a)]],
        [[front_post_len + 2 * r, guide_top_z]],
        [for (i = [1 : 8]) let(a = -90 - i * 90 / 8)
            [front_post_len + 2 * r + r * cos(a), guide_top_z + r + r * sin(a)]],
        [[front_post_len + r, post_top_z - r]],
        [for (i = [1 : 8]) let(a = i * 90 / 8) [front_post_len + r * cos(a), post_top_z - r + r * sin(a)]],
        [[0, post_top_z]]);
    polygon(pts);
}

module side_walls() {
    for (x0 = [0, holder_outer_w - holder_wall])
        translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(height = holder_wall) side_wall_profile();
}

module front_posts() {
    for (x0 = [0, holder_outer_w - front_post_w])
        translate([x0, 0, 0]) cube([front_post_w, front_post_len, post_top_z]);
}

module back_stops() {
    for (i = stop_idx)
        translate([rail_x[i] + rail_w / 2, y_back_stop - y_holder_front + back_stop_t, 0])
            rotate([90, 0, 0]) linear_extrude(height = back_stop_t)
                translate([0, back_stop_top_z / 2]) rrect(back_stop_w, back_stop_top_z, back_stop_r);
}

module cutouts() {
    for (bx = duct_bolt_xs, bz = duct_bolt_zs)
        hole_y(bx, bz, m3_insert_hole_d, -0.01, m3_insert_depth + 0.5);
    if (strap_slots)
        for (x0 = [-0.01, holder_outer_w - holder_wall - 0.01])
            for (sy = [dev_y + 45, dev_y + device_depth - 45])
                translate([x0, sy - strap_slot_w / 2, device_base_zl + 3])
                    cube([holder_wall + 0.02, strap_slot_w, strap_slot_h]);
    // кабель датчика T_out — отверстие в дне у бобышки
    translate([holder_outer_w / 2 + 8, holder_depth - back_stop_t - 6, -0.01])
        cylinder(h = holder_floor_t + 0.02, d = 3, $fn = 16);
    // гнездо датчика T_in — внутренняя грань левой стойки
    translate([front_post_w - 0.01, front_post_len / 2, device_base_zl + device_height / 2])
        rotate([0, -90, 0]) cylinder(h = sensor_pocket_h, d = sensor_pocket_d, $fn = 24);
}

module sensor_boss() {
    translate([holder_outer_w / 2, holder_depth - back_stop_t - 6, holder_floor_t])
        difference() {
            cylinder(h = sensor_pocket_h + 2, d = sensor_pocket_d + 4, $fn = 24);
            translate([0, 0, 2]) cylinder(h = sensor_pocket_h + 1, d = sensor_pocket_d, $fn = 24);
        }
}

module holder() {
    difference() {
        union() { base_plate_holder(); rails(); side_walls(); front_posts(); back_stops(); sensor_boss(); }
        cutouts();
    }
}

// --- Заслонка байпаса ------------------------------------------------------
// Гребёнка: поперечная планка в зоне заднего отступа рельсов (под свесом MSI),
// пальцы входят в каналы между рельсами на baffle_finger_len. Высота перекрытия
// = bypass_block × (rail_top_z − holder_floor_t). Вставляется сзади по дну при
// снятом/приподнятом устройстве. Печатать несколько вариантов (0.25/0.5/0.75/1).
baffle_h = bypass_block * (rail_top_z - holder_floor_t);
baffle_y = rail_y0 + rail_len;   // задние торцы рельсов

module baffle() {
    if (bypass_block > 0) {
        bar_w = floor_w - 2 * baffle_clearance;
        translate([holder_wall + baffle_clearance, baffle_y, holder_floor_t])
            cube([bar_w, baffle_t, baffle_h]);
        // пальцы в каналы (между рельсами и в боковые каналы)
        for (i = [0 : rail_count])
            let(x0 = i == 0 ? holder_wall : rail_x[i - 1] + rail_w,
                x1 = i == rail_count ? holder_outer_w - holder_wall : rail_x[i],
                fw = x1 - x0 - 2 * baffle_clearance)
            if (fw > 4)
                translate([x0 + baffle_clearance, baffle_y - baffle_finger_len, holder_floor_t])
                    cube([fw, baffle_finger_len + 0.01, baffle_h]);
    }
}

module holder_with_device() {
    holder();
    translate([dev_x, dev_y, device_base_zl])
        device_mockup(device_width, device_depth, device_height,
                      device_foot_dia, device_foot_inset, device_foot_height,
                      device_bottom_vent_w, device_bottom_vent_d, device_bottom_vent_front_offset,
                      device_intake_margin_x, device_intake_margin_top, device_intake_margin_bot);
}

echo(str("[HOLDER] envelope ", holder_outer_w, " x ", holder_depth, " x ", post_top_z,
         "; rails x=", rail_x, " (w ", rail_w, ", channel ", channel_actual, "), setback ",
         rail_front_setback, ", height ", rail_top_z, "; baffle ", bypass_block, " → h=", baffle_h));

if (part == "holder_with_device") holder_with_device();
else if (part == "baffle") baffle();
else if (part == "holder_with_baffle") { holder(); color([0.9, 0.5, 0.2]) baffle(); }
else holder();
