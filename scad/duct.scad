/*
 * duct.scad — воздуховод 140×140 → сотовая полоса MSI EdgeXpert (v3, по замерам).
 *
 * Тракт по Y:
 *   [входной фланец 150×150: 4 паза M4 124.5…126 + гнёзда гаек — болты сэндвича
 *    решётка → панель → вентилятор → фланец]
 *   [пленум 135.2×135.2, R20, длина plenum_len = 50]
 *   [сопло smoothstep 135.2×135.2 → outlet_w × outlet_h, длина nozzle_len = 150;
 *    сужение ≈5:1 к полосе сот 138.2×22.4 у НИЗА передней грани MSI;
 *    минимальный радиус кривизны стенки проверяется (≥ R20)]
 *   [выходной фланец 181 × до base_plate, 4 отверстия M3 → heat-set в стойках
 *    holder'а; при under_feed вырез опускается под дно MSI — подача холодного
 *    воздуха под днище; иначе снизу уплотнение EPDM 5×5]
 *   [порт T_in: Ø4 в левой стенке сопла в 12 мм перед выходным фланцем]
 *
 * Стенка 2.4, фланцы 6. Внутренний контур — единый лофт без ступенек.
 * Опции: duct_split (2 части по границе пленум/сопло), guide_vanes.
 *
 * Локальные координаты: x=0 — левая грань трака, y=0 — задняя плоскость панели,
 * z=0 — верх base_plate.
 */

include <params.scad>
use <lib/shapes.scad>

part = "duct"; // [duct, duct_a, duct_b, duct_section]

part_checks();

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

in_flange_h = in_flange_w;                 // 150 (in_flange_w из params)
in_flange_z0 = fan_center_zl - in_flange_h / 2;

module inlet_flange() {
    difference() {
        translate([track_cx - in_flange_w / 2, y_in, in_flange_z0])
            cube([in_flange_w, duct_flange_t, in_flange_h]);
        // Пазы под болты сэндвича (межцентровое 124.5…126) + удлинённые гнёзда гаек M4
        for (sx = [-1, 1], sz = [-1, 1]) {
            hull() for (pt = [fan_hole_pitch_min, fan_hole_pitch_max])
                hole_y(track_cx + sx * pt / 2, fan_center_zl + sz * pt / 2, m4_clear_d, y_in - 1, duct_flange_t + 2);
            hull() for (pt = [fan_hole_pitch_min, fan_hole_pitch_max])
                hex_pocket_y(track_cx + sx * pt / 2, fan_center_zl + sz * pt / 2, m4_nut_af, m4_nut_h + 0.01,
                             y_in + duct_flange_t - m4_nut_h);
        }
    }
}

module outlet_flange() {
    difference() {
        translate([0, y_outf, out_flange_z0])
            cube([out_flange_w, duct_flange_t, out_flange_h]);
        for (bx = duct_bolt_xs, bz = duct_bolt_zs)
            hole_y(bx, bz, m3_clear_d, y_outf - 1, duct_flange_t + 2);
    }
}

// Порт датчика T_in: горизонтальное отверстие через левую стенку сопла у выхода
t_in_y = y_outf - 12;
t_in_z = (outlet_seal_z0 + outlet_z1) / 2;
module t_in_port_cut() {
    translate([track_cx - outlet_w / 2 - 10, t_in_y, t_in_z]) rotate([0, 90, 0])
        cylinder(h = 14, d = 4, $fn = 24);
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
    difference() {
        union() {
            difference() {
                union() { shell_outer(); inlet_flange(); outlet_flange(); }
                shell_inner();
            }
            vanes();
        }
        t_in_port_cut();
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
         "; inlet inner ", inlet_w, "x", inlet_h, " R", duct_inlet_corner_r, " @z", inlet_cz,
         "; outlet ", outlet_w, "x", outlet_h, " z ", outlet_z0, "..", outlet_z1,
         "; min bend R", duct_bend_r_min, "; outlet flange ", out_flange_w, "x", out_flange_h,
         "; T_in port y=", t_in_y, " z=", t_in_z));
echo(str("[DUCT] print envelope approx ", max(out_flange_w, in_flange_w), " x ",
         max(in_flange_h, out_flange_h), " x ", duct_len, " mm (bed ", print_bed_x, "x", print_bed_y, ")"));

if (part == "duct_a") duct_a();
else if (part == "duct_b") duct_b();
else if (part == "duct_section") duct_section();
else duct_full();
