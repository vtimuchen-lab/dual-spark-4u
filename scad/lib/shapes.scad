/*
 * Вспомогательные примитивы. Подключать через use <lib/shapes.scad>.
 */

// Прямоугольник со скруглёнными углами, центрированный в (0,0)
module rrect(w, h, r, fn = 32) {
    r_ = min(r, w / 2 - 0.01, h / 2 - 0.01);
    hull()
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * (w / 2 - r_), sy * (h / 2 - r_)])
                circle(r = r_, $fn = fn);
}

// Капсула (slot) длиной l по X, шириной w, центрирована
module slot2d(l, w, fn = 24) {
    hull()
        for (sx = [-1, 1])
            translate([sx * (l - w) / 2, 0]) circle(d = w, $fn = fn);
}

// Скруглённый по вертикальным рёбрам параллелепипед, угол в начале координат
module rbox(size, r, fn = 32) {
    translate([size[0] / 2, size[1] / 2, 0])
        linear_extrude(height = size[2])
            rrect(size[0], size[1], r, fn);
}

// Плавная интерполяция (нулевой наклон на концах → эквивалент большого радиуса)
function smoothstep(t) = t * t * (3 - 2 * t);
function lerp(a, b, t) = a + (b - a) * t;

/*
 * Лофт по Y между двумя скруглёнными прямоугольниками в плоскости XZ.
 * Сечение задано: центр [cx, cz], ширина w, высота h, радиус r.
 * Профиль перехода: smoothstep → тангенциально-непрерывный вход и выход.
 * y0..y1 — продольные координаты. n — число ломтей.
 */
module loft_xz(y0, y1, s0, s1, n = 24, fn = 32) {
    L = y1 - y0;
    for (i = [0 : n - 1]) {
        t0 = i / n;
        t1 = (i + 1) / n;
        hull() {
            section_slab(y0 + t0 * L, s0, s1, smoothstep(t0), fn);
            section_slab(y0 + t1 * L, s0, s1, smoothstep(t1), fn);
        }
    }
}

// Тонкий ломоть сечения на координате y, s = [cx, cz, w, h, r]
module section_slab(y, s0, s1, u, fn) {
    cx = lerp(s0[0], s1[0], u);
    cz = lerp(s0[1], s1[1], u);
    w  = lerp(s0[2], s1[2], u);
    h  = lerp(s0[3], s1[3], u);
    r  = lerp(s0[4], s1[4], u);
    translate([cx, y, cz])
        rotate([90, 0, 0])
            translate([0, 0, -0.005])
                linear_extrude(height = 0.01)
                    rrect(w, h, r, fn);
}

// Отверстие вдоль Y (сквозное), центр (x, z), на глубине от y0 длиной l
module hole_y(x, z, d, y0, l, fn = 32) {
    translate([x, y0 - 0.01, z])
        rotate([-90, 0, 0])
            cylinder(h = l + 0.02, d = d, $fn = fn);
}

// Шестигранное гнездо под гайку вдоль Y
module hex_pocket_y(x, z, af, h, y0) {
    translate([x, y0 - 0.01, z])
        rotate([-90, 0, 0])
            cylinder(h = h + 0.01, d = af / cos(30), $fn = 6);
}

// --- Макеты (не для печати) -------------------------------------------------
module fan_mockup(size = 140, t = 25, hub = 45, hole_pitch = 124.5) {
    // Рамка
    color([0.08, 0.08, 0.09, 0.9])
    difference() {
        translate([0, t, 0]) rotate([90, 0, 0])
            linear_extrude(height = t) rrect(size, size, 6);
        translate([0, t + 0.1, 0]) rotate([90, 0, 0])
            linear_extrude(height = t + 0.2) circle(d = size - 3, $fn = 96);
        for (sx = [-1, 1], sz = [-1, 1])
            hole_y(sx * hole_pitch / 2, sz * hole_pitch / 2, 4.4, -1, t + 2);
    }
    // Ступица и лопасти (условно)
    color([0.45, 0.35, 0.25, 0.95])
    translate([0, t / 2, 0]) rotate([90, 0, 0]) {
        cylinder(h = t * 0.6, d = hub, center = true, $fn = 48);
        for (i = [0 : 6])
            rotate(i * 360 / 7)
                hull() {
                    translate([hub / 2 - 2, -3, 0]) cylinder(h = 2, r = 3, center = true);
                    translate([size / 2 - 10, 10, 0]) cylinder(h = 2, r = 6, center = true);
                }
    }
}

module device_mockup(w, d, h, foot_dia = 16, foot_inset = 20, foot_h = 4,
                     vent_w = 40, vent_d = 55, vent_front = 12,
                     intake_mx = 3, intake_mt = 3, intake_mb = 3) {
    color([0.14, 0.15, 0.16, 0.85]) cube([w, d, h]);
    // передняя сотовая решётка — зона всасывания
    color([0.35, 0.65, 0.95, 0.9])
        translate([intake_mx, -0.4, intake_mb])
            cube([w - 2 * intake_mx, 0.4, h - intake_mt - intake_mb]);
    // задняя решётка — выхлоп
    color([0.95, 0.45, 0.3, 0.9])
        translate([intake_mx, d, h * 0.45])
            cube([w - 2 * intake_mx, 0.4, h * 0.5]);
    // ножки
    color([0.2, 0.2, 0.2])
        for (fx = [foot_inset, w - foot_inset], fy = [foot_inset, d - foot_inset])
            translate([fx, fy, -foot_h]) cylinder(h = foot_h, d = foot_dia, $fn = 32);
    // нижняя щелевая решётка (по msi.png — у переднего края, по центру)
    color([0.35, 0.65, 0.95, 0.9])
        translate([w / 2 - vent_w / 2, vent_front, -0.4])
            cube([vent_w, vent_d, 0.4]);
}
