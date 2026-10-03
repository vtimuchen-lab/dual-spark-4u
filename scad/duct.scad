/*
 * duct.scad — воздуховод 140×140 → передняя решётка MSI EdgeXpert.
 *
 * Тракт по Y:
 *   [входной фланец 150×150, 4 гнезда гаек M4 под болты сэндвича вентилятора]
 *   [пленум: постоянное сечение 135×135 внутр., длина plenum_len]
 *   [сопло: плавное (smoothstep) сужение к проёму outlet_w × outlet_h, длина nozzle_len]
 *   [выходной фланец по габариту holder'а, 4 отверстия M3 → heat-set в стойках holder'а]
 *
 * Стенка 2.4 мм (аэродинамическая оболочка), фланцы 6 мм.
 * Нет ступенек: внутренний контур — единый лофт от пленума до проёма.
 * Опционально: разрез на 2 части по границе пленум/сопло (duct_split),
 * tongue-and-groove + 4 M3; направляющие лопатки (guide_vanes).
 *
 * Локальные координаты: x=0 — левая грань трака, y=0 — плоскость всасывания
 * вентилятора (как в params), z=0 — дно корпуса. Сам воздуховод начинается
 * на y = y_duct_in.
 */

include <params.scad>
use <lib/shapes.scad>

part = "duct"; // [duct, duct_a, duct_b, duct_section]

y_in   = y_duct_in;                       // передняя плоскость входного фланца
y_pl   = y_in + duct_flange_t;            // начало тонкостенного пленума
y_noz  = y_in + plenum_len;               // граница пленум/сопло (здесь разрез при split)
y_outf = y_duct_out - duct_flange_t;      // передняя плоскость выходного фланца
y_out  = y_duct_out;

w = duct_wall;
// Сечения [cx, cz, w, h, r]
s_in_inner  = [track_cx, inlet_cz, inlet_w, inlet_h, duct_inlet_corner_r];
s_in_outer  = [track_cx, inlet_cz, inlet_w + 2 * w, inlet_h + 2 * w, duct_inlet_corner_r + w];
s_out_inner = [track_cx, outlet_cz, outlet_w, outlet_h, duct_outlet_corner_r];
s_out_outer = [track_cx, outlet_cz, outlet_w + 2 * w, outlet_h + 2 * w, duct_outlet_corner_r + w];

in_flange_w = fan_size + 2 * holder_wall;   // 150
in_flange_h = fan_size + 2 * holder_wall;
in_flange_z0 = fan_center_z - in_flange_h / 2;

module inlet_flange() {
    difference() {
        translate([track_cx - in_flange_w / 2, y_in, in_flange_z0])
            cube([in_flange_w, duct_flange_t, in_flange_h]);
        // Отверстия под болты сэндвича + гнёзда гаек M4 с задней стороны
        for (sx = [-1, 1], sz = [-1, 1]) {
            hx = track_cx + sx * fan_hole_pitch / 2;
            hz = fan_center_z + sz * fan_hole_pitch / 2;
            hole_y(hx, hz, m4_clear_d, y_in - 1, duct_flange_t + 2);
            hex_pocket_y(hx, hz, m4_nut_af, m4_nut_h, y_in + duct_flange_t - m4_nut_h);
        }
    }
}

module outlet_flange() {
    difference() {
        translate([0, y_outf, out_flange_z0])
            cube([out_flange_w, duct_flange_t, out_flange_h]);
        for (bx = duct_bolt_xs, bz = duct_bolt_zs)
            hole_y(bx, bz, m3_clear_d, y_outf - 1, duct_flange_t + 2);
        // Гнездо датчика температуры ВХОДА (сквозь фланец сбоку от проёма)
        hole_y(track_cx - outlet_w / 2 - 4, outlet_cz, 3, y_outf - 1, duct_flange_t + 2, 16);
    }
}

// Наружная оболочка: пленум (призма) + сопло (лофт)
module shell_outer() {
    // пленум
    hull() {
        section_slab(y_in + 0.5, s_in_outer, s_in_outer, 0, 32);
        section_slab(y_noz, s_in_outer, s_in_outer, 0, 32);
    }
    // сопло
    loft_xz(y_noz, y_outf + 0.5, s_in_outer, s_out_outer, duct_slices, 32);
}

module shell_inner() {
    hull() {
        section_slab(y_in - 1, s_in_inner, s_in_inner, 0, 32);
        section_slab(y_noz, s_in_inner, s_in_inner, 0, 32);
    }
    loft_xz(y_noz, y_out + 1, s_in_inner, s_out_inner, duct_slices, 32);
    // пробивка проёма сквозь выходной фланец
    hull() {
        section_slab(y_outf - 0.5, s_out_inner, s_out_inner, 0, 32);
        section_slab(y_out + 1, s_out_inner, s_out_inner, 0, 32);
    }
}

module vanes() {
    // Тонкие вертикальные лопатки в сопле, передняя кромка скруглена
    if (guide_vanes > 0)
        for (i = [1 : guide_vanes]) {
            f = i / (guide_vanes + 1) - 0.5;   // -0.25, +0.25 при 2 лопатках
            intersection() {
                shell_inner_solid();
                hull() {
                    translate([track_cx + f * inlet_w, y_noz + 8, inlet_cz])
                        rotate([-90, 0, 0]) cylinder(h = 0.1, d = vane_t * 1.6, $fn = 16);
                    translate([track_cx + f * outlet_w, y_outf, outlet_cz])
                        rotate([-90, 0, 0]) cylinder(h = 0.1, d = vane_t, $fn = 16);
                    // растянуть по высоте
                    translate([track_cx + f * inlet_w - vane_t / 2, y_noz + 8, inlet_cz - inlet_h / 2])
                        cube([vane_t, 0.1, inlet_h]);
                    translate([track_cx + f * outlet_w - vane_t / 2, y_outf, outlet_cz - outlet_h / 2])
                        cube([vane_t, 0.1, outlet_h]);
                }
            }
        }
}

module shell_inner_solid() { shell_inner(); }

module duct_full() {
    union() {
        difference() {
            union() { shell_outer(); inlet_flange(); outlet_flange(); }
            shell_inner();
        }
        vanes();
    }
}

// --- Разрез на две части (если duct_split) ---------------------------------
// Разъём на y_noz: сечение здесь постоянное (пленум) → ступеньки внутри нет.
// Часть A (вход + пленум) несёт паз, часть B (сопло + выходной фланец) — шип,
// плюс кольцевой фланец 8 мм с 4 болтами M3.
split_flange_t = 5;
split_flange_grow = 9;

module split_flange_ring(y0) {
    difference() {
        hull() {
            section_slab(y0, [track_cx, inlet_cz, inlet_w + 2 * w + 2 * split_flange_grow,
                              inlet_h + 2 * w + 2 * split_flange_grow, duct_inlet_corner_r + w + 4],
                         s_in_outer, 0, 32);
            section_slab(y0 + split_flange_t, [track_cx, inlet_cz, inlet_w + 2 * w + 2 * split_flange_grow,
                              inlet_h + 2 * w + 2 * split_flange_grow, duct_inlet_corner_r + w + 4],
                         s_in_outer, 0, 32);
        }
        for (sx = [-1, 1], sz = [-1, 1])
            hole_y(track_cx + sx * (inlet_w / 2 + w + split_flange_grow / 2),
                   inlet_cz + sz * (inlet_h / 2 + w + split_flange_grow / 2),
                   m3_clear_d, y0 - 1, split_flange_t + 2);
    }
}

module tongue(y0) {
    // кольцевой шип duct_tongue × duct_tongue посередине толщины стенки
    difference() {
        hull() {
            section_slab(y0, [track_cx, inlet_cz, inlet_w + w + duct_tongue, inlet_h + w + duct_tongue, duct_inlet_corner_r + w / 2], s_in_outer, 0, 32);
            section_slab(y0 + duct_tongue, [track_cx, inlet_cz, inlet_w + w + duct_tongue, inlet_h + w + duct_tongue, duct_inlet_corner_r + w / 2], s_in_outer, 0, 32);
        }
        hull() {
            section_slab(y0 - 1, [track_cx, inlet_cz, inlet_w + w - duct_tongue, inlet_h + w - duct_tongue, duct_inlet_corner_r + w / 2], s_in_outer, 0, 32);
            section_slab(y0 + duct_tongue + 1, [track_cx, inlet_cz, inlet_w + w - duct_tongue, inlet_h + w - duct_tongue, duct_inlet_corner_r + w / 2], s_in_outer, 0, 32);
        }
    }
}

module duct_a() {
    difference() {
        union() {
            intersection() { duct_full(); translate([-1, y_in - 1, -1]) cube([track_w + 2, y_noz - y_in + 1, 400]); }
            split_flange_ring(y_noz - split_flange_t);
        }
        shell_inner();
        // паз под шип (с зазором 0.2)
        scale([1, 1, 1]) translate([0, -duct_tongue - 0.2, 0]) tongue(y_noz);
        translate([0, -duct_tongue - 0.2, 0]) scale([1.004, 1, 1.004]) tongue(y_noz);
    }
}

module duct_b() {
    union() {
        intersection() { duct_full(); translate([-1, y_noz, -1]) cube([track_w + 2, y_out - y_noz + 2, 400]); }
        split_flange_ring(y_noz);
        tongue(y_noz - duct_tongue);
    }
}

module duct_section() {
    // половина для просмотра внутреннего контура
    difference() { duct_full(); translate([track_cx, 0, -1]) cube([200, 1000, 400]); }
}

echo(str("[DUCT] y_in=", y_in, " plenum→", y_noz, " nozzle→", y_outf, " flange→", y_out,
         "; inlet inner ", inlet_w, "x", inlet_h, " @z", inlet_cz,
         "; outlet ", outlet_w, "x", outlet_h, " @z", outlet_cz,
         "; outlet flange ", out_flange_w, "x", out_flange_h));
echo(str("[DUCT] print envelope approx ", max(out_flange_w, in_flange_w), " x ",
         max(in_flange_h, out_flange_h), " x ", duct_len, " mm (bed ", print_bed_x, "x", print_bed_y, ")"));

if (part == "duct_a") duct_a();
else if (part == "duct_b") duct_b();
else if (part == "duct_section") duct_section();
else duct_full();
