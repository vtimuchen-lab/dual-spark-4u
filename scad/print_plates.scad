/*
 * print_plates.scad — комплект на ОДИН тракт для теста, стол 330 × 320.
 *
 * Holder (181 × 217) и воздуховод (самый узкий габарит 150) вместе на стол не
 * встают: 181 + 150 = 331 > 330. Поэтому комплект — два стола:
 *   part="kit_1" — воздуховод стоя на выходном фланце + стойка вентилятора плашмя
 *   part="kit_2" — holder + заслонки 0.5 и 1.0
 * Уголки panel↔base_plate в тестовый комплект не входят (нужны только для шкафа).
 */

include <params.scad>
use <lib/shapes.scad>
use <edgexpert_holder.scad>
use <duct.scad>
use <fan_bracket.scad>

part = "kit_1"; // [kit_1, kit_2]

gap = 8;

// Воздуховод стоя на выходном фланце: x 0..181, y 0..150, высота 200
module duct_standing() { rotate([-90, 0, 0]) translate([0, -y_duct_out, 0]) duct_full(); }

// Стойка вентилятора плашмя: рамка на столе, лапки вверх. x 0..150, y 0..150, высота 30
fan_frame_w = fan_size + 2 * holder_wall;
module fan_stand_flat() {
    translate([-(track_cx - fan_frame_w / 2), fan_frame_w, 0]) rotate([90, 0, 0]) bracket();
}

// Заслонка плашмя
baffle_len = (holder_outer_w - 2 * holder_wall) + 2 * (baffle_groove_depth - baffle_clearance);
function baffle_h_of(b) = b * (device_base_zl - holder_floor_t - 1);
module baffle_flat(b) { cube([baffle_len, baffle_h_of(b), baffle_t]); }

module check_fit(w, d, h) {
    assert(w <= print_bed_x && d <= print_bed_y && h <= print_bed_z,
           str(part, ": ", w, " x ", d, " x ", h, " does not fit bed ", print_bed_x, " x ", print_bed_y, " x ", print_bed_z));
    echo(str("[KIT] ", part, ": ", w, " x ", d, " x ", h, " on bed ", print_bed_x, " x ", print_bed_y));
}

if (part == "kit_1") {
    check_fit(out_flange_w, in_flange_w + gap + fan_frame_w, duct_len);
    duct_standing();
    translate([0, in_flange_w + gap, 0]) fan_stand_flat();
} else {
    check_fit(holder_outer_w, holder_depth + gap + baffle_h_of(0.5) + gap + baffle_h_of(1.0), post_top_z);
    holder();
    translate([0, holder_depth + gap, 0]) baffle_flat(0.5);
    translate([0, holder_depth + gap + baffle_h_of(0.5) + gap, 0]) baffle_flat(1.0);
}
