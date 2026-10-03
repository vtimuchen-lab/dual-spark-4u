/*
 * edgexpert_holder.scad — подставка (holder) под один MSI EdgeXpert AI
 * для крепления на металлическое дно 4U-корпуса.
 *
 * Адаптация части part="holder" из
 *   alexliesenfeld/dgx-spark-printables : spark-rack-10/dgx_spark_rack_mount.scad
 * Что взято: 5-мм дно, 4 продольных опорных рельса 20 мм с каналами 20 мм,
 * низкие боковые направляющие со ступенчатым профилем, два задних стопора
 * на внутренних рельсах, открытый верх.
 * Что убрано: передняя 254×88 панель, rack-ears, отверстия 10", отверстия 2×80 мм.
 * Что добавлено: передние стойки под фланец воздуховода (heat-set M3),
 * пазы M4 для крепления к дну корпуса, пазы под ремень, гнёзда датчиков,
 * анкеры стяжек, параметрическая высота под 140-мм вентилятор.
 *
 * Локальные координаты holder'а: x=0 — левая наружная грань,
 * y=0 — передняя грань (плоскость заднего торца фланца воздуховода),
 * z=0 — дно корпуса.
 */

include <params.scad>
use <lib/shapes.scad>

part = "holder"; // [holder, holder_with_device]

holder_depth = y_holder_rear - y_holder_front;         // полная глубина
dev_x = holder_wall + holder_side_clearance;           // x дна устройства
dev_y = gasket_t;                                      // y передней грани устройства
floor_w = holder_outer_w - 2 * holder_wall;            // ширина дна между стенками

// Рельсы: столько, сколько влезает в ширину дна с шагом rail_w + channel_w
rail_count = floor((floor_w + channel_w) / (rail_w + channel_w));
pattern_w  = rail_count * rail_w + (rail_count - 1) * channel_w;
side_ch_w  = (floor_w - pattern_w) / 2;
rail_x = [for (i = [0 : rail_count - 1])
            holder_wall + side_ch_w + i * (rail_w + channel_w)];
rail_y0 = dev_y + rail_front_setback;
rail_len = device_depth - rail_front_setback - rail_rear_setback;
stop_idx = [floor(rail_count / 2) - 1, floor(rail_count / 2)];

module base_plate() {
    difference() {
        translate([holder_wall, 0, 0])
            cube([floor_w, holder_depth, holder_floor_t]);
        // Пазы M4 → дно корпуса (в каналах между рельсами, доступны при снятом устройстве)
        for (sx = [-1, 1], sy = [-1, 1]) {
            px = holder_outer_w / 2 + sx * holder_mount_pitch_x / 2;
            py = dev_y + device_depth / 2 + sy * holder_mount_pitch_y / 2;
            translate([px, py, -0.01])
                linear_extrude(height = holder_floor_t + 0.02)
                    rotate(90) slot2d(holder_mount_slot_l, holder_mount_slot_w);
            translate([px, py, holder_floor_t - holder_mount_cbore_h])
                linear_extrude(height = holder_mount_cbore_h + 0.01)
                    rotate(90) slot2d(holder_mount_slot_l + (holder_mount_cbore_d - holder_mount_slot_w),
                                      holder_mount_cbore_d);
        }
        // Анкеры стяжек за устройством (по две пары)
        for (ax = [holder_outer_w * 0.3, holder_outer_w * 0.7])
            for (ay = [y_holder_rear - y_holder_front - 12])
                for (dx = [-6, 6])
                    translate([ax + dx, ay, -0.01])
                        linear_extrude(height = holder_floor_t + 0.02)
                            square([2.5, 6], center = true);
    }
}

module rails() {
    for (i = [0 : rail_count - 1])
        translate([rail_x[i], rail_y0, 0])
            cube([rail_w, rail_len, rail_top_z]);
}

// Профиль боковой стенки в плоскости YZ: высокая передняя стойка → ступень → низкая направляющая
module side_wall_profile() {
    r = step_r;
    pts = concat(
        [[0, 0], [holder_depth, 0], [holder_depth, guide_top_z - r]],
        [for (i = [1 : 8]) let(a = i * 90 / 8)
            [holder_depth - r + r * cos(a), guide_top_z - r + r * sin(a)]],
        [[front_post_len + 2 * r, guide_top_z]],
        [for (i = [1 : 8]) let(a = -90 - i * 90 / 8)
            [front_post_len + 2 * r + r * cos(a), guide_top_z + r + r * sin(a)]],
        [[front_post_len + r, post_top_z - r]],
        [for (i = [1 : 8]) let(a = i * 90 / 8)
            [front_post_len + r * cos(a), post_top_z - r + r * sin(a)]],
        [[0, post_top_z]]
    );
    polygon(pts);
}

module side_walls() {
    for (x0 = [0, holder_outer_w - holder_wall])
        translate([x0, 0, 0])
            rotate([90, 0, 90])
                linear_extrude(height = holder_wall)
                    side_wall_profile();
}

// Передние стойки: утолщение стенки внутрь до front_post_w на глубину front_post_len
module front_posts() {
    for (x0 = [0, holder_outer_w - front_post_w])
        translate([x0, 0, 0])
            cube([front_post_w, front_post_len, post_top_z]);
}

module back_stops() {
    for (i = stop_idx)
        translate([rail_x[i] + (rail_w - back_stop_w) / 2 + back_stop_w / 2,
                   y_back_stop - y_holder_front + back_stop_t, 0])
            rotate([90, 0, 0])
                linear_extrude(height = back_stop_t)
                    translate([0, back_stop_top_z / 2])
                        rrect(back_stop_w, back_stop_top_z, back_stop_r);
}

module cutouts() {
    // Heat-set M3 под болты фланца воздуховода (с передней грани стоек)
    for (bx = duct_bolt_xs, bz = duct_bolt_zs)
        hole_y(bx, bz, m3_insert_hole_d, -0.01, m3_insert_depth + 0.5);
    // Пазы под ремень-липучку 20 мм в низких направляющих
    if (strap_slots)
        for (x0 = [-0.01, holder_outer_w - holder_wall - 0.01])
            for (sy = [dev_y + 45, dev_y + device_depth - 45])
                translate([x0, sy - strap_slot_w / 2, device_base_z + 3])
                    cube([holder_wall + 0.02, strap_slot_w, strap_slot_h]);
    // Гнездо датчика температуры ВЫХЛОПА — в заднем стопоре/дне за устройством
    translate([holder_outer_w / 2, y_holder_rear - y_holder_front - back_stop_t / 2 - 4, -0.01])
        cylinder(h = holder_floor_t + 0.02, d = 3, $fn = 16);  // отверстие под кабель датчика
    // Гнездо датчика температуры ВХОДА — в левой передней стойке, с внутренней стороны
    translate([front_post_w - 0.01, front_post_len / 2, device_base_z + device_height / 2])
        rotate([0, -90, 0]) cylinder(h = sensor_pocket_h, d = sensor_pocket_d, $fn = 24);
}

module sensor_boss() {
    // бобышка под датчик выхлопа на дне за устройством
    translate([holder_outer_w / 2, y_holder_rear - y_holder_front - back_stop_t - 6, holder_floor_t])
        difference() {
            cylinder(h = sensor_pocket_h + 2, d = sensor_pocket_d + 4, $fn = 24);
            translate([0, 0, 2]) cylinder(h = sensor_pocket_h + 1, d = sensor_pocket_d, $fn = 24);
        }
}

module holder() {
    difference() {
        union() {
            base_plate();
            rails();
            side_walls();
            front_posts();
            back_stops();
            sensor_boss();
        }
        cutouts();
    }
}

module holder_with_device() {
    holder();
    translate([dev_x, dev_y, device_base_z])
        device_mockup(device_width, device_depth, device_height,
                      device_foot_dia, device_foot_inset, device_foot_height,
                      device_bottom_vent_w, device_bottom_vent_d, device_bottom_vent_front_offset,
                      device_intake_margin_x, device_intake_margin_top, device_intake_margin_bot);
}

echo(str("[HOLDER] envelope ", holder_outer_w, " x ", holder_depth, " x ", post_top_z,
         " mm; rails ", rail_count, " x ", rail_w, " mm, channels ", channel_w,
         " mm, side channels ", side_ch_w, " mm; rail height ", rail_top_z, " mm"));
echo(str("[HOLDER] device sits at x=", dev_x, " y=", dev_y, " z=", device_base_z,
         "; guide walls top z=", guide_top_z, "; posts top z=", post_top_z));

if (part == "holder_with_device") holder_with_device();
else holder();
