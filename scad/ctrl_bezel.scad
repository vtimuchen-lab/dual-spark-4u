/*
 * ctrl_bezel.scad — печатная рамка PWM-термоконтроллера на ЛИЦЕВОЙ стороне ФП-5.
 *
 * Контроллер — панельный корпус с защёлками (лицевая рамка с дисплеем и
 * кнопками). Он вставляется СПЕРЕДИ в прямоугольный вырез лицевой стенки
 * (ctrl_cut_* + 0.3), защёлки берут стенку толщиной ctrl_clip_t. Карман за
 * стенкой — по зубьям защёлок (ctrl_w × ctrl_h) на глубину ctrl_d с вилками.
 * Задняя стенка 1.5 мм изолирует контроллер от стальной панели. Две лапки с
 * heat-set M3 — на всю глубину рамки (печать лицом вниз без поддержек): винты
 * M3×8 заходят СЗАДИ панели через отверстия Ø3.4. Кабели 12 В и вентилятора
 * уходят из кармана через Ø12 в задней стенке — прямо в такое же отверстие в
 * панели за рамкой (на оси тракта); рамки обоих трактов одинаковые. Датчик
 * NTC — в притоке: его капля проходит из кармана вниз через втулку в нижней
 * стенке и висит перед фильтром на решётке (ctrl_probe_*), вилка XH остаётся
 * в кармане на контроллере.
 *
 * Сборка: разъём вентилятора и провода 12 В — через Ø12 панели и рамки (затем
 * разрезная втулка или кант на кромку панели) → вилки на контроллер → каплю
 * датчика через втулку вниз → контроллер в вырез спереди до щелчка.
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
ft = ctrl_known ? bezel_front_t : 0;
cut_w = ctrl_known ? ctrl_cut_w + bezel_cut_clear : 0; cut_h = ctrl_known ? ctrl_cut_h + bezel_cut_clear : 0;
fw = ctrl_known ? ctrl_frame_w : 0; fh = ctrl_known ? ctrl_frame_h : 0; frt = ctrl_known ? ctrl_frame_t : 0;
cdp = ctrl_known ? ctrl_d : 0;
pocket_x0 = bezel_wall; pocket_w = w - 2 * bezel_wall;
pocket_z0 = bezel_wall; pocket_h = h - 2 * bezel_wall;
pocket_y0 = bezel_back_t; pocket_d = d - ft - bezel_back_t;
pr_y = probe_known ? probe_y : 0; pr_o = probe_known ? probe_r_o : 0;
pr_b = probe_known ? (ctrl_probe_d + ctrl_probe_fit) / 2 : 0;
pr_x = w / 2 + ctrl_probe_dx;

// Втулка датчика под нижней стенкой: от оси датчика до лицевой плоскости рамки,
// чтобы при печати лицом вниз она стояла на столе без поддержек.
module probe_boss() {
    hull() {
        translate([pr_x, pr_y, -ctrl_probe_boss]) cylinder(h = ctrl_probe_boss + bezel_wall, r = pr_o, $fn = 32);
        translate([pr_x - pr_o, d - 0.01, -ctrl_probe_boss]) cube([2 * pr_o, 0.01, ctrl_probe_boss + bezel_wall]);
    }
}

module bezel() {
    difference() {
        union() {
            rbox([w, d, h], 2);
            probe_boss();
            // лапки: на всю глубину (стоят на столе при печати), заходят в корпус на 1 мм
            for (sx = [-1, 1])
                translate([sx > 0 ? w - 1 : -bezel_lug_w, 0, h / 2 - bezel_lug_h / 2])
                    cube([bezel_lug_w + 1, d, bezel_lug_h]);
        }
        // карман: корпус по зубьям защёлок + вилки
        translate([pocket_x0, pocket_y0, pocket_z0]) cube([pocket_w, pocket_d + 0.01, pocket_h]);
        // вырез под корпус в лицевой стенке (защёлки берут стенку ft)
        translate([w / 2 - cut_w / 2, d - ft - 0.01, h / 2 - cut_h / 2]) cube([cut_w, ft + 0.02, cut_h]);
        // отверстие датчика: сквозь втулку и нижнюю стенку в карман
        translate([pr_x, pr_y, -ctrl_probe_boss - 0.01]) cylinder(h = ctrl_probe_boss + bezel_wall + 0.02, r = pr_b, $fn = 32);
        // провода: Ø12 в задней стенке, соосно отверстию в панели (cable_hole_dx от центра)
        translate([w / 2 + (ctrl_known ? cable_hole_dx : 0), -0.01, h / 2]) rotate([-90, 0, 0])
            cylinder(h = bezel_back_t + 0.02, d = cable_hole_d, $fn = 48);
        // heat-set M3 в лапках (с задней плоскости, глухие)
        for (sx = [-1, 1])
            translate([sx > 0 ? w + bezel_lug_w / 2 : -bezel_lug_w / 2, -0.01, h / 2])
                rotate([-90, 0, 0]) cylinder(h = m3_insert_depth, d = m3_insert_hole_d, $fn = 24);
    }
}

// Макет контроллера: лицевая рамка перед стенкой, корпус в кармане
module ctrl_mockup() {
    color([0.12, 0.12, 0.13, 0.95]) {
        translate([w / 2 - fw / 2, d, h / 2 - fh / 2]) cube([fw, frt, fh]);
        translate([w / 2 - cut_w / 2 + 0.15, d - cdp, h / 2 - cut_h / 2 + 0.15]) cube([cut_w - 0.3, cdp, cut_h - 0.3]);
    }
    color([0.9, 0.15, 0.1]) translate([w / 2 - fw * 0.25, d + frt, h / 2 - fh * 0.2]) cube([fw * 0.35, 0.3, fh * 0.4]);
}

module probe_mockup() {
    color([0.15, 0.15, 0.15])
        translate([pr_x, pr_y, -ctrl_probe_boss - 8]) cylinder(h = ctrl_probe_boss + bezel_wall + 8, d = probe_known ? ctrl_probe_d : 0, $fn = 24);
}

if (ctrl_known)
    echo(str("[BEZEL] ", w, " x ", h, " x ", d, " (pocket ", pocket_w, " x ", pocket_h, " x ", pocket_d,
             "; cutout ", cut_w, " x ", cut_h, " in ", ft, " mm wall); lugs at ±", bezel_lug_dx,
             " from track axis; cable hole Ø", cable_hole_d, " behind the bezel at ", cable_hole_dx,
             "; controller front ", ctrl_front, " mm from post face (≤ ", door_gap - door_margin, ")",
             "; NTC probe Ø", ctrl_probe_d, " at ", pr_y, " in front of panel, boss down ", ctrl_probe_boss));

if (part == "bezel_with_ctrl") { bezel(); ctrl_mockup(); probe_mockup(); }
else bezel();
