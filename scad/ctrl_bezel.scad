/*
 * ctrl_bezel.scad — печатная рамка PWM-термоконтроллера на ЛИЦЕВОЙ стороне ФП-5.
 *
 * Карман под плату ctrl_w × ctrl_h × ctrl_d (TO_MEASURE п.11), лицевая стенка с
 * окном под дисплей/кнопки (ctrl_win_*, по умолчанию плата минус 3 мм), задняя
 * стенка 1.5 мм изолирует пайку от стальной панели. Две лапки с heat-set M3:
 * винты M3×8 заходят СЗАДИ панели через отверстия Ø3.4. Кабели выходят через
 * вырез в боковой стенке у задней плоскости к отверстию Ø12 с втулкой в панели.
 *
 * Локальные координаты детали: x 0..bezel_w (+лапки снаружи), y 0 — плоскость
 * панели, +y наружу (к стеклу), z 0..bezel_h. Печатать лицевой стенкой вниз.
 */

include <params.scad>
use <lib/shapes.scad>

part = "bezel"; // [bezel, bezel_with_ctrl]

bezel_checks();

// до замера контроллера габариты undef → нули, чтобы не было предупреждений до assert
w = ctrl_known ? bezel_w : 0; h = ctrl_known ? bezel_h : 0; d = ctrl_known ? bezel_d : 0;
cw = ctrl_known ? ctrl_w : 0; ch = ctrl_known ? ctrl_h : 0; cdp = ctrl_known ? ctrl_d : 0;
ww = ctrl_known ? ctrl_win_w_eff : 0; wh = ctrl_known ? ctrl_win_h_eff : 0;
pocket_x0 = bezel_wall; pocket_w = w - 2 * bezel_wall;
pocket_z0 = bezel_wall; pocket_h = h - 2 * bezel_wall;
pocket_y0 = bezel_back_t; pocket_d = cdp + bezel_clear;
win_cx = w / 2 + ctrl_win_dx; win_cz = h / 2 + ctrl_win_dz;
notch_w = 10; notch_h = 6;   // вырез под кабели в боковой стенке (у задней плоскости)
notch_side = cable_hole_side; // та же сторона, где отверстие в панели

module bezel() {
    difference() {
        union() {
            translate([0, 0, 0]) rbox([w, d, h], 2);
            // лапки
            for (sx = [-1, 1])
                translate([sx > 0 ? w : -bezel_lug_w, 0, h / 2 - bezel_lug_h / 2])
                    cube([bezel_lug_w, bezel_lug_t, bezel_lug_h]);
        }
        // карман платы
        translate([pocket_x0, pocket_y0, pocket_z0]) cube([pocket_w, pocket_d + 0.01, pocket_h]);
        // окно в лицевой стенке
        translate([win_cx - ww / 2, d - bezel_front_t - 0.01, win_cz - wh / 2])
            cube([ww, bezel_front_t + 0.02, wh]);
        // вырез под кабели: боковая стенка, от задней плоскости
        translate([notch_side > 0 ? w - bezel_wall - 0.01 : -0.01, -0.01, h / 2 - notch_h / 2])
            cube([bezel_wall + 0.02, notch_w, notch_h]);
        // heat-set M3 в лапках (с задней плоскости, глухие)
        for (sx = [-1, 1])
            translate([sx > 0 ? w + bezel_lug_w / 2 : -bezel_lug_w / 2, -0.01, h / 2])
                rotate([-90, 0, 0]) cylinder(h = m3_insert_depth, d = m3_insert_hole_d, $fn = 24);
    }
}

module ctrl_mockup() {
    color([0.1, 0.4, 0.15, 0.9])
        translate([pocket_x0 + bezel_clear, pocket_y0, pocket_z0 + bezel_clear])
            cube([cw, 1.6, ch]);                               // плата
    color([0.9, 0.2, 0.2, 0.9])
        translate([win_cx - ww * 0.3, pocket_y0 + 1.6, win_cz - 5]) cube([ww * 0.6, cdp - 1.6, 10]); // дисплей
}

if (ctrl_known)
    echo(str("[BEZEL] ", w, " x ", h, " x ", d, " (pocket ", pocket_w, " x ", pocket_h, " x ", pocket_d,
             "; window ", ww, " x ", wh, "); lugs at ±", bezel_lug_dx,
             " from track axis; cable hole at ", cable_hole_side * cable_hole_dx));

if (part == "bezel_with_ctrl") { bezel(); ctrl_mockup(); }
else bezel();
