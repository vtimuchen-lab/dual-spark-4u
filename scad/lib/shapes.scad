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

// Паз отверстия вентилятора: hull двух окружностей на межцентровых pmin и pmax
// (sx, sz — квадрант, ±1). 2D, центр вентилятора в (0,0).
module fan_hole_slot2d(sx, sz, pmin, pmax, d, fn = 24) {
    hull() for (p = [pmin, pmax]) translate([sx * p / 2, sz * p / 2]) circle(d = d, $fn = fn);
}

/*
 * Макет MSI EdgeXpert по замерам. Начало координат — левый-передний-нижний угол
 * КОРПУСА (без ножек); ножки уходят в −z. «Левый» — при взгляде спереди.
 *   hc = [w, h, z0]           — сотовая полоса на передней грани (центр по ширине)
 *   bv = [w, d, x0, y0]       — нижняя решётка (x0 от левого края, y0 от передней грани)
 *   rx = [w, h, top]          — задний выхлоп (центр по ширине, top — от верха)
 *   ft = [dia, h, inset_x, inset_y]
 */
module device_mockup(w, d, h, hc, bv, rx, ft) {
    color([0.14, 0.15, 0.16, 0.85]) cube([w, d, h]);
    color([0.35, 0.65, 0.95, 0.95])            // соты — вход
        translate([(w - hc[0]) / 2, -0.4, hc[2]]) cube([hc[0], 0.4, hc[1]]);
    color([0.95, 0.45, 0.3, 0.95])             // задний выхлоп
        translate([(w - rx[0]) / 2, d, h - rx[2] - rx[1]]) cube([rx[0], 0.4, rx[1]]);
    color([0.35, 0.65, 0.95, 0.95])            // нижняя решётка
        translate([bv[2], bv[3], -0.4]) cube([bv[0], bv[1], 0.4]);
    color([0.2, 0.2, 0.2])                     // ножки
        for (fx = [ft[2], w - ft[2]], fy = [ft[3], d - ft[3]])
            translate([fx, fy, -ft[1]]) cylinder(h = ft[1], d = ft[0], $fn = 32);
}
