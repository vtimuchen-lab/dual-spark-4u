/*
 * fan_bracket.scad — передняя рамка 140-мм вентилятора.
 *
 * Схема «сэндвич»: [рамка] – [вентилятор 25 мм] – [входной фланец воздуховода].
 * 4 болта M4×45 проходят через рамку и штатные угловые отверстия вентилятора
 * в гайки (гнёзда) входного фланца воздуховода. Вентилятор меняется без
 * перепечатки воздуховода. Рамка стоит на двух лапках с пазами M4 к дну.
 *
 * Проём 138 мм без решётки (ТЗ п.7, п.23). Опциональная защитная решётка
 * — покупная проволочная 140 мм под те же 4 болта.
 *
 * Локальные координаты: x=0 — левая грань трака, y=0 — передняя грань рамки
 * (плоскость всасывания), z=0 — дно корпуса.
 */

include <params.scad>
use <lib/shapes.scad>

part = "bracket"; // [bracket, bracket_with_fan]

hole_d = fan_mount_type == "rubber" ? fan_rubber_hole_dia : fan_hole_dia;
frame_w = fan_size + 2 * holder_wall;   // 150
frame_z0 = fan_floor_clearance - holder_wall;  // низ рамки (0 при зазоре 5 и стенке 5)
frame_h  = fan_size + 2 * holder_wall;

module bracket() {
    difference() {
        union() {
            // Плита рамки
            translate([track_cx, 0, 0])
                translate([-frame_w / 2, 0, max(0, frame_z0)])
                    cube([frame_w, bracket_t, frame_h - max(0, -frame_z0)]);
            // Лапки к дну
            for (sx = [-1, 1])
                translate([track_cx + sx * (frame_w / 2 - bracket_foot_w / 2) - bracket_foot_w / 2, 0, 0])
                    cube([bracket_foot_w, bracket_foot_d, holder_floor_t]);
            // Косынки лапок
            for (sx = [-1, 1])
                translate([track_cx + sx * (frame_w / 2 - 2.5), bracket_t, 0])
                    rotate([90, 0, 90])
                        linear_extrude(height = 5, center = true)
                            polygon([[0, 0], [bracket_foot_d - bracket_t, 0], [0, 30]]);
        }
        // Проём
        hole_y(track_cx, fan_center_z, fan_open_dia, -1, bracket_t + 2, 96);
        // 4 отверстия вентилятора
        for (sx = [-1, 1], sz = [-1, 1])
            hole_y(track_cx + sx * fan_hole_pitch / 2, fan_center_z + sz * fan_hole_pitch / 2,
                   hole_d, -1, bracket_t + 2);
        // Пазы M4 в лапках
        for (sx = [-1, 1])
            translate([track_cx + sx * (frame_w / 2 - bracket_foot_w / 2), bracket_t + (bracket_foot_d - bracket_t) / 2, -0.01])
                linear_extrude(height = holder_floor_t + 0.02)
                    rotate(90) slot2d(10, m4_clear_d);
    }
}

module bracket_with_fan() {
    bracket();
    translate([track_cx, y_fan_front, fan_center_z])
        fan_mockup(fan_size, fan_thickness, fan_hub_dia, fan_hole_pitch);
}

echo(str("[BRACKET] frame ", frame_w, " x ", frame_h, " x ", bracket_t,
         " mm; opening ", fan_open_dia, "; holes ", hole_d, " @ ", fan_hole_pitch,
         "; fan center z=", fan_center_z));

if (part == "bracket_with_fan") bracket_with_fan();
else bracket();
