/*
 * edgexpert_holder.scad — подставка (holder) под один MSI EdgeXpert AI на base_plate.
 *
 * Основа — part="holder" из alexliesenfeld/dgx-spark-printables
 * (spark-rack-10/dgx_spark_rack_mount.scad): 5-мм дно, низкие боковые
 * направляющие со ступенчатым профилем, открытый верх. По замерам (v3):
 *   - MSI поднят так, что центр полосы сот = ось вентилятора (низ корпуса 57.8
 *     над плитой); вместо 4 сплошных рельсов — 4 ОПОРЫ ПОД НОЖКИ с гнёздами:
 *     нижняя решётка (у левого края, середина глубины) полностью открыта;
 *   - задние упоры — рёбра на боковых стенках, заходят за углы корпуса на 3 мм
 *     и поднимаются на 4 мм выше низа корпуса (порты не задевают);
 *   - пазы в боковых стенках под заслонку подднищевой зоны (part="baffle");
 *   - стойка T_out: ребро за вилками кабелей + консоль к центру выхлопа.
 * Убрано из исходника: 10" панель, rack-ears, отверстия 2×80.
 *
 * Координаты: x=0 — левая наружная грань, y=0 — передняя грань (задний торец
 * выходного фланца воздуховода), z=0 — верх base_plate.
 */

include <params.scad>
use <lib/shapes.scad>

part = "holder"; // [holder, holder_with_device, baffle, holder_with_baffle]

part_checks();

floor_w = holder_outer_w - 2 * holder_wall;
y_stop_l   = y_back_stop - y_holder_front;          // передняя грань задних упоров
y_tpost_l  = y_t_out_post - y_holder_front;          // центр ребра T_out
y_tout_l   = y_t_out - y_holder_front;               // точка замера T_out

module floor_plate() {
    difference() {
        translate([holder_wall, 0, 0]) cube([floor_w, holder_depth, holder_floor_t]);
        for (h = holder_mount_holes) {
            translate([h[0], h[1], -0.01]) linear_extrude(height = holder_floor_t + 0.02)
                rotate(90) slot2d(holder_mount_slot_l, holder_mount_slot_w);
            translate([h[0], h[1], holder_floor_t - holder_mount_cbore_h])
                linear_extrude(height = holder_mount_cbore_h + 0.01)
                    rotate(90) slot2d(holder_mount_slot_l + (holder_mount_cbore_d - holder_mount_slot_w),
                                      holder_mount_cbore_d);
        }
        // анкеры стяжек кабелей за устройством (по бокам от стойки T_out)
        for (ax = [holder_outer_w * 0.25, holder_outer_w * 0.75], dx = [-6, 6])
            translate([ax + dx, holder_depth - 10, -0.01])
                linear_extrude(height = holder_floor_t + 0.02) square([2.5, 6], center = true);
    }
}

// Опора под ножку: квадрат pedestal_size со скруглением, гнездо Ø(ножка + 2×зазор)
module pedestals() {
    for (fx = foot_xs, fy = foot_ys)
        difference() {
            translate([fx, fy, 0]) linear_extrude(height = pedestal_top_zl)
                rrect(pedestal_size, pedestal_size, pedestal_r);
            translate([fx, fy, foot_seat_zl]) cylinder(h = foot_pocket_depth + 0.01,
                d = device_foot_dia + 2 * foot_pocket_clear, $fn = 48);
        }
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

// Задние упоры: рёбра от боковых стенок, заходят за угол корпуса на back_stop_overlap
module back_stops() {
    zt = device_base_zl + back_stop_h_above_body;
    translate([holder_wall - 0.01, y_stop_l, 0])
        cube([dev_x + back_stop_overlap - holder_wall, back_stop_t, zt]);
    translate([dev_x + device_width - back_stop_overlap, y_stop_l, 0])
        cube([holder_outer_w - holder_wall + 0.01 - (dev_x + device_width - back_stop_overlap), back_stop_t, zt]);
}

// Стойка T_out: ребро вдоль потока + консоль вперёд + кольцо датчика (ось — вдоль Y)
module t_out_post() {
    cx = holder_outer_w / 2;
    ring_d = sensor_pocket_d + 4;
    difference() {
        union() {
            translate([cx - t_out_fin_t / 2, y_tpost_l - t_out_fin_len / 2, 0])
                cube([t_out_fin_t, t_out_fin_len, t_out_zl + t_out_arm_h / 2]);
            translate([cx - t_out_fin_t / 2, y_tout_l, t_out_zl - t_out_arm_h / 2])
                cube([t_out_fin_t, y_tpost_l - y_tout_l, t_out_arm_h]);
            // косынка 45° под консолью — печать без поддержек
            arm_len = y_tpost_l - y_tout_l;
            translate([cx - t_out_fin_t / 2, 0, 0]) rotate([90, 0, 90])
                linear_extrude(height = t_out_fin_t)
                    polygon([[y_tpost_l, t_out_zl - t_out_arm_h / 2 - arm_len + 4],
                             [y_tpost_l, t_out_zl - t_out_arm_h / 2],
                             [y_tout_l + 4, t_out_zl - t_out_arm_h / 2]]);
            translate([cx, y_tout_l - sensor_pocket_h / 2, t_out_zl]) rotate([-90, 0, 0])
                cylinder(h = sensor_pocket_h, d = ring_d, $fn = 32);
        }
        translate([cx, y_tout_l - sensor_pocket_h / 2 - 0.01, t_out_zl]) rotate([-90, 0, 0])
            cylinder(h = sensor_pocket_h + 0.02, d = sensor_pocket_d, $fn = 32);
    }
}

module cutouts() {
    // heat-set M3 под болты выходного фланца воздуховода
    for (bx = duct_bolt_xs, bz = duct_bolt_zs)
        hole_y(bx, bz, m3_insert_hole_d, -0.01, m3_insert_depth + 0.5);
    // пазы под ремень-липучку (через боковые стенки, над низом корпуса)
    if (strap_slots)
        for (x0 = [-0.01, holder_outer_w - holder_wall - 0.01])
            for (sy = [dev_y + 45, dev_y + device_depth - 45])
                translate([x0, sy - strap_slot_w / 2, device_base_zl + 3])
                    cube([holder_wall + 0.02, strap_slot_w, strap_slot_h]);
    // пазы под заслонку (внутренние грани боковых стенок, открыты сверху)
    for (x0 = [holder_wall - baffle_groove_depth, holder_outer_w - holder_wall - 0.01])
        translate([x0, baffle_y_local - baffle_clearance, holder_floor_t])
            cube([baffle_groove_depth + 0.01, baffle_t + 2 * baffle_clearance, post_top_z]);
}

module holder() {
    difference() {
        union() { floor_plate(); pedestals(); side_walls(); front_posts(); back_stops(); t_out_post(); }
        cutouts();
    }
}

// Заслонка подднищевой зоны: пластина в пазах боковых стенок за задними опорами.
module baffle() {
    if (bypass_block > 0)
        translate([holder_wall - baffle_groove_depth + baffle_clearance, baffle_y_local, holder_floor_t])
            cube([floor_w + 2 * (baffle_groove_depth - baffle_clearance), baffle_t, baffle_h]);
}

module holder_with_device() {
    holder();
    translate([dev_x, dev_y, device_base_zl]) msi();
}

echo(str("[HOLDER] envelope ", holder_outer_w, " x ", holder_depth, " x ", post_top_z,
         "; pedestals at x=", foot_xs, " y=", foot_ys, " top ", pedestal_top_zl,
         " (seat ", foot_seat_zl, "); MSI body ", device_base_zl, "..", device_top_zl,
         "; T_out at y=", y_tout_l, " z=", t_out_zl, "; baffle ", bypass_block, " → h=", baffle_h));

if (part == "holder_with_device") holder_with_device();
else if (part == "baffle") baffle();
else if (part == "holder_with_baffle") { holder(); color([0.9, 0.5, 0.2]) baffle(); }
else holder();
