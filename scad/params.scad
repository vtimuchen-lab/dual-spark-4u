/*
 * dual-spark-4u — общие параметры проекта (v2: 5U-модуль в 18U шкафу).
 *
 * ВСЕ размеры в миллиметрах. Оси модуля:
 *   X = ширина, 0 = ось симметрии модуля (= ось панели ФП-5 и base_plate)
 *   Y = глубина, 0 = ЗАДНЯЯ плоскость панели ФП-5 (к ней прижат вентилятор);
 *       панель и решётка лежат в y < 0, тракт растёт в +Y
 *   Z = высота, 0 = верх полки шкафа (= низ base_plate)
 *
 * Статус параметра:
 *   [SRC]  — есть источник (см. docs/01_analysis.md, docs/TZ.md)
 *   [ASSM] — инженерное допущение, обосновано в документации
 *   TO_MEASURE — реальное значение неизвестно → значение undef.
 *                Детали, которым оно не нужно, рендерятся; сборка,
 *                base_plate и вертикальная разметка панели — нет
 *                (assert), пока параметр не измерен и не внесён.
 *
 * Файл подключается через include <params.scad> во всех остальных .scad.
 */

// ---------------------------------------------------------------------------
// 1. УСТРОЙСТВО: MSI EdgeXpert AI (MS-C931), класс DGX Spark / GB10
// ---------------------------------------------------------------------------
device_width  = 151;   // [SRC] карточки MS-C931: 151 x 151 x 52
device_depth  = 151;   // [SRC]
device_height = 52;    // [SRC] (с ножками или без — TO_MEASURE п.13)
device_mass_kg = 1.2;  // [SRC]

// Зона сот на передней грани: внешний габарит минус рамка. TO_MEASURE п.15.
device_intake_margin_x   = 3;  // [ASSM]
device_intake_margin_top = 3;  // [ASSM]
device_intake_margin_bot = 3;  // [ASSM]

// Ножки: 4 круглые по углам (msi.png в dgx-spark-printables). TO_MEASURE п.14.
device_foot_dia    = 16;  // [ASSM]
device_foot_inset  = 20;  // [ASSM] центр ножки от бокового и переднего/заднего края
device_foot_height = 4;   // [ASSM] «elevated stacking footpads»

// Нижняя щелевая решётка у переднего края по центру (msi.png). TO_MEASURE п.16.
device_bottom_vent_w = 40;  // [ASSM]
device_bottom_vent_d = 55;  // [ASSM]
device_bottom_vent_front_offset = 12; // [ASSM]

// ---------------------------------------------------------------------------
// 2. ВЕНТИЛЯТОР: Arctic P14 Pro PST (ACFAN00314A)  [SRC: Arctic datasheet]
// ---------------------------------------------------------------------------
fan_model      = "Arctic P14 Pro PST";
fan_size       = 140;
fan_thickness  = 27;     // [SRC] 140 x 140 x 27
fan_mass_g     = 242;    // [SRC]
fan_hole_pitch = 124.5;  // [SRC] стандарт; у Arctic встречается «125» → пазы ±0.5
fan_hole_tol   = 0.5;    // допуск межцентрового → отверстия выполнены пазами ±tol
fan_hole_dia   = 4.5;    // под болт M4
fan_open_dia   = 138;    // [ASSM] вырез в панели и проём фланца (без решётки)
fan_hub_dia    = 45;     // [ASSM] для оценки мёртвой зоны
fan_rpm_min    = 400;    // [SRC]
fan_rpm_max    = 2500;   // [SRC]
fan_q_max_m3h  = 186;    // [SRC]
fan_p_max_mmH2O = 5.2;   // [SRC]
fan_i_a        = 0.35;   // [SRC]
pwm_min_percent = 20;    // [SRC] P14 Pro: 0 об/мин при PWM < 5 % → контроллер не ниже 15–20 %, автостоп запрещён

grille_t       = 3;      // [ASSM] ARCTIC Fan Grill 140, проволочная; TO_MEASURE п.21

// ---------------------------------------------------------------------------
// 3. ШКАФ 18U И ПОЛКА — ВСЁ TO_MEASURE (undef)
// ---------------------------------------------------------------------------
rack_opening_w     = undef; // TO_MEASURE п.1  проём между внутренними гранями передних стоек (EIA-310 номинал 450.85)
shelf_top_z        = undef; // TO_MEASURE п.2  верх полки относительно НИЖНЕГО края ФП-5 (вверх +)
shelf_depth        = undef; // TO_MEASURE п.3  глубина полки
panel_t            = undef; // TO_MEASURE п.4  толщина листа ФП-5
panel_hole_pitch_v = undef; // TO_MEASURE п.5  вертикальный шаг крепёжных отверстий в ушах ФП-5
rack_depth         = 600;   // [SRC] глубина шкафа (ТЗ v2 п.1)

// ---------------------------------------------------------------------------
// 4. ФРОНТАЛЬНАЯ ПАНЕЛЬ ЦМО ФП-5 (сталь, RAL 7035)
// ---------------------------------------------------------------------------
panel_w        = 482.6;  // [SRC]
panel_h        = 221.5;  // [SRC]
panel_fold     = 10;     // [SRC] отбортовка внутрь (в −Y… т.е. назад, в модуль)
panel_edge_keepout = 15; // [SRC ТЗ v2] вырезы и фланцы не ближе 15 мм к краям панели
panel_color    = [0.78, 0.78, 0.76]; // RAL 7035 (визуально)

// ---------------------------------------------------------------------------
// 5. BASE PLATE (алюминий 3 мм) И УГОЛКИ
// ---------------------------------------------------------------------------
base_plate_t        = 3;    // [SRC ТЗ v2]
base_plate_side_gap = 3;    // [SRC ТЗ v2] ширина = rack_opening_w − 2×3
base_plate_depth_min = 330; // [SRC ТЗ v2] ≥ 330; фактическая = по полке (TO_MEASURE п.3)
base_plate_front_gap = 2;   // [ASSM] зазор от задней плоскости панели до переднего края плиты

bracket_w      = 30;   // [ASSM] ширина уголка panel↔base_plate
bracket_h      = 60;   // [ASSM] высота вертикальной полки (по панели)
bracket_d      = 50;   // [ASSM] глубина горизонтальной полки (по плите)
bracket_t      = 5;    // [ASSM] толщина полок
bracket_hole_d = 4.5;  // M4
bracket_x_from_center = 0; // 0 → автоматически: снаружи от фланца воздуховода + 5 мм

// ---------------------------------------------------------------------------
// 6. ТРАКТ: решётка → панель → вентилятор → воздуховод → holder → MSI → выхлоп
// ---------------------------------------------------------------------------
fan_axis_above_plate = 75;  // [SRC ТЗ v2] ось вентилятора = верх base_plate + 75

plenum_len   = 50;   // [ASSM] (ТЗ 40–80), включая входной фланец
nozzle_len   = 70;   // [ASSM] включая выходной фланец; duct = 120 (ТЗ 100–180)
duct_wall    = 2.4;  // [ASSM] (ТЗ 2–3)
duct_flange_t = 6;   // [ASSM]
duct_inlet_corner_r  = 12;
duct_outlet_corner_r = 6;
duct_slices  = 28;
duct_split   = false; // true → две части по границе plenum/nozzle
duct_tongue  = 2;
guide_vanes  = 0;     // 0 = нет; 2 = две вертикальные лопатки
vane_t       = 1.6;

gasket_t     = 5;    // [ASSM] EPDM между выходным фланцем и передней гранью MSI
outlet_under_device = 8;  // [ASSM] выход заходит ниже дна MSI (подача под ножки / к нижней решётке)
outlet_over_device  = 0;

rear_free_zone = 90;  // [SRC ТЗ v2] свободный выхлоп ≥ 90

// ---------------------------------------------------------------------------
// 7. HOLDER (адаптация spark-rack-10 holder)
// ---------------------------------------------------------------------------
holder_side_clearance = 10;
holder_rear_clearance = 1;
holder_wall      = 5;
holder_floor_t   = 5;
rail_w           = 20;
channel_w        = 20;         // используется, если rails_follow_feet = false
rails_follow_feet = true;      // внешние рельсы центрируются под ножками MSI (device_foot_inset)
rail_setback_margin = 3;       // рельс выходит за край ножки на столько мм
back_stop_t      = 3;
back_stop_w      = 10;
back_stop_extra_h = 10;
back_stop_r      = 2;
guide_wall_extra_h = 15;
front_post_len   = 25;
front_post_w     = 10;
step_r           = 5;

holder_mount_slot_l   = 10;    // пазы M4 → base_plate
holder_mount_slot_w   = 4.5;
holder_mount_cbore_d  = 9;
holder_mount_cbore_h  = 2.5;
holder_mount_pitch_x  = 140;   // [ASSM] сверловка base_plate делается ПО ЭТИМ значениям
holder_mount_pitch_y  = 120;   // [ASSM]

strap_slots      = true;
strap_slot_w     = 22;
strap_slot_h     = 3;

sensor_pocket_d  = 6.2;
sensor_pocket_h  = 10;

// Байпас под устройством: заслонка-гребёнка в каналах у заднего края.
// 0 = каналы открыты назад (нет заслонки), 1 = каналы перекрыты полностью.
bypass_block     = 0.5;        // [ASSM] предмет испытаний (docs/04 §7)
baffle_t         = 3;
baffle_finger_len = 15;
baffle_clearance = 0.3;

// ---------------------------------------------------------------------------
// 8. ЭЛЕКТРИКА (места на base_plate)
// ---------------------------------------------------------------------------
dc_jack_hole_d   = 12;   // [ASSM] панельное гнездо 5.5×2.5 (резьба M12/ø11.5) — TO_MEASURE п.24
// Зоны электроники: полосы base_plate снаружи от воздуховодов, по одной на сторону
// (левая — контроллер трака 1 + WAGO, правая — контроллер трака 2 + DC-гнездо),
// между уголком и выходным фланцем воздуховода. Ширина зависит от rack_opening_w.
ctrl_zone_margin = 2;    // [ASSM] зазор зоны от воздуховода и от края плиты
ctrl_hole_grid   = 10;   // сетка M3 в зоне электроники

// ---------------------------------------------------------------------------
// 9. КРЕПЁЖ И ПЕЧАТЬ
// ---------------------------------------------------------------------------
m3_insert_hole_d = 4.0;
m3_insert_depth  = 6;
m3_clear_d       = 3.4;
m4_clear_d       = 4.5;
m4_nut_af        = 7.0;
m4_nut_h         = 3.2;
m4_head_d        = 8.5;
print_bed_x = 250;
print_bed_y = 250;
print_bed_z = 250;
$fn = 48;

// ---------------------------------------------------------------------------
// ПРОИЗВОДНЫЕ ВЕЛИЧИНЫ (не редактировать)
// ---------------------------------------------------------------------------
function known(v) = !is_undef(v);

// Вертикаль (z от низа base_plate = верх полки)
fan_center_z    = base_plate_t + fan_axis_above_plate;          // 78
device_base_z   = fan_center_z - device_height / 2;             // 52 (ось MSI = ось вентилятора)
device_center_z = fan_center_z;
// Локальные координаты holder'а и воздуховода: z от ВЕРХА base_plate
hz0 = base_plate_t;                      // смещение локального z=0 деталей
fan_center_zl   = fan_axis_above_plate;  // 75
device_base_zl  = fan_center_zl - device_height / 2;  // 49

// Трак (локально: x=0 — левая наружная грань holder'а, y=0 — задняя плоскость панели)
holder_outer_w = device_width + 2 * holder_side_clearance + 2 * holder_wall;   // 181
track_w        = max(holder_outer_w, fan_size + 2 * holder_wall);
track_cx       = track_w / 2;
device_x0      = track_cx - device_width / 2;
track_gap      = 15;                       // [ASSM] кабель-канал между траками
track_pitch    = track_w + track_gap;      // 196
pair_w         = 2 * track_w + track_gap;  // 377

y_fan_front    = 0;                               // вентилятор прижат к задней плоскости панели
y_duct_in      = y_fan_front + fan_thickness;     // 27
duct_len       = plenum_len + nozzle_len;
y_duct_out     = y_duct_in + duct_len;            // 147
y_holder_front = y_duct_out;
y_device_front = y_holder_front + gasket_t;
y_device_rear  = y_device_front + device_depth;
y_back_stop    = y_device_rear + holder_rear_clearance;
y_holder_rear  = y_back_stop + back_stop_t;
y_track_end    = y_device_rear + rear_free_zone;
track_len      = y_track_end;

outlet_w   = device_width - 2 * device_intake_margin_x;
outlet_z0  = device_base_zl - outlet_under_device;
outlet_z1  = device_base_zl + device_height - device_intake_margin_top + outlet_over_device;
outlet_h   = outlet_z1 - outlet_z0;
outlet_cz  = (outlet_z0 + outlet_z1) / 2;
inlet_w    = fan_size - 2 * duct_wall;
inlet_h    = fan_size - 2 * duct_wall;
inlet_cz   = fan_center_zl;

rail_top_z      = device_base_zl;
guide_top_z     = device_base_zl + guide_wall_extra_h;
post_top_z      = device_base_zl + device_height + 8;
back_stop_top_z = device_base_zl + back_stop_extra_h;
rail_front_setback = rails_follow_feet
    ? max(0, device_foot_inset - device_foot_dia / 2 - rail_setback_margin) : 20;
rail_rear_setback  = rail_front_setback;

out_flange_w  = holder_outer_w;
out_flange_z0 = max(0, outlet_z0 - duct_flange_t - 4);
out_flange_z1 = post_top_z;
out_flange_h  = out_flange_z1 - out_flange_z0;
duct_bolt_xs  = [front_post_w / 2, holder_outer_w - front_post_w / 2];
duct_bolt_zs  = [device_base_zl + 6, device_base_zl + device_height - 4];
in_flange_w   = fan_size + 2 * holder_wall;   // 150

// Панель и вырезы (x от оси модуля; z от нижнего края панели — ТОЛЬКО если shelf_top_z известен)
fan_cx_from_center = [-track_pitch / 2, track_pitch / 2];     // ±98
fan_center_z_panel = known(shelf_top_z) ? shelf_top_z + fan_center_z : undef;
// Допустимый диапазон оси по вертикали: фланец 150 должен отстоять от краёв панели ≥ keepout
fan_center_z_panel_min = panel_edge_keepout + in_flange_w / 2;             // 90
fan_center_z_panel_max = panel_h - panel_edge_keepout - in_flange_w / 2;   // 131.5
shelf_top_z_min = fan_center_z_panel_min - fan_center_z;                  // 12
shelf_top_z_max = fan_center_z_panel_max - fan_center_z;                  // 53.5

// Уголки panel↔base_plate
bracket_cx = bracket_x_from_center > 0 ? bracket_x_from_center
           : track_pitch / 2 + in_flange_w / 2 + 5 + bracket_w / 2;      // 193
// Зоны электроники (x — внутренняя граница полосы, ширина — при известной плите)
ctrl_zone_x_in = track_pitch / 2 + in_flange_w / 2 + ctrl_zone_margin;   // 175
ctrl_zone_y0   = base_plate_front_gap + bracket_d + 7;                    // за уголком
ctrl_zone_y1   = y_duct_out - 6;                                          // до выходного фланца (181 wide)
ctrl_zone_d    = ctrl_zone_y1 - ctrl_zone_y0;

// Base plate (ширина — только при известном rack_opening_w)
base_plate_w = known(rack_opening_w) ? rack_opening_w - 2 * base_plate_side_gap : undef;
ctrl_zone_w  = known(base_plate_w) ? base_plate_w / 2 - ctrl_zone_margin - ctrl_zone_x_in : undef;
base_plate_d = known(shelf_depth) ? max(base_plate_depth_min, min(shelf_depth, y_track_end + 10)) : undef;
base_plate_y0 = base_plate_front_gap;

// Болт сэндвича: решётка + панель + вентилятор + фланец(гайка внутри) + выступ 2–3 мм
sandwich_stack = known(panel_t) ? grille_t + panel_t + fan_thickness + duct_flange_t : undef;

// --- Проверки --------------------------------------------------------------
// Детали вызывают part_checks(); сборка/плита/панель — rack_checks().
module part_checks() {
    assert(holder_outer_w <= print_bed_x && y_holder_rear - y_holder_front <= print_bed_y,
           "Holder exceeds print bed");
    assert(duct_len <= print_bed_z || duct_split,
           "Duct taller than print bed: set duct_split = true");
    assert(outlet_w * outlet_h < inlet_w * inlet_h, "Outlet area must be smaller than inlet area");
    assert(outlet_w <= in_flange_w, "Outlet wider than the duct body");
    assert(rail_front_setback >= 0, "Rail setback negative");
}

module rack_checks() {
    assert(known(rack_opening_w), "TO_MEASURE: rack_opening_w (п.1 чек-листа) — проём между передними стойками");
    assert(known(shelf_top_z),    "TO_MEASURE: shelf_top_z (п.2) — верх полки относительно нижнего края ФП-5");
    assert(known(shelf_depth),    "TO_MEASURE: shelf_depth (п.3) — глубина полки");
    assert(known(panel_t),        "TO_MEASURE: panel_t (п.4) — толщина листа ФП-5");
    assert(known(panel_hole_pitch_v), "TO_MEASURE: panel_hole_pitch_v (п.5) — шаг отверстий в ушах ФП-5");
    assert(base_plate_w >= pair_w,
           str("Base plate too narrow: ", base_plate_w, " < pair ", pair_w));
    assert(2 * bracket_cx + bracket_w <= base_plate_w,
           str("Brackets outside base plate: need ", 2 * bracket_cx + bracket_w, " > ", base_plate_w));
    assert(2 * bracket_cx + bracket_w <= panel_w - 2 * panel_edge_keepout,
           "Brackets inside panel keep-out");
    assert(ctrl_zone_w >= 30,
           str("Electronics strip too narrow: ", ctrl_zone_w, " mm (< 30) — rack opening too small"));
    assert(fan_center_z_panel >= fan_center_z_panel_min && fan_center_z_panel <= fan_center_z_panel_max,
           str("Fan cutouts leave the 15 mm panel margin: axis ", fan_center_z_panel,
               " must be in [", fan_center_z_panel_min, ", ", fan_center_z_panel_max,
               "] → shelf_top_z in [", shelf_top_z_min, ", ", shelf_top_z_max, "]"));
    assert(shelf_depth >= base_plate_depth_min, str("Shelf too shallow: ", shelf_depth, " < ", base_plate_depth_min));
    assert(shelf_depth >= y_track_end - 30,
           str("Shelf must carry the module: need ≥ ", y_track_end - 30, " mm, have ", shelf_depth));
    assert(y_track_end + 20 <= rack_depth,
           str("Module deeper than rack: ", y_track_end + 20, " > ", rack_depth));
}

module fit_report() {
    rack_checks();
    echo(str("[FIT] electronics strips ", ctrl_zone_w, " x ", ctrl_zone_d, " mm per side at x=±", ctrl_zone_x_in, "..±", ctrl_zone_x_in + ctrl_zone_w));
    echo(str("[FIT] pair ", pair_w, " on base plate ", base_plate_w, " x ", base_plate_d,
             "; module length ", y_track_end, "; fan axis on panel z=", fan_center_z_panel,
             " (allowed ", fan_center_z_panel_min, "..", fan_center_z_panel_max, ")"));
    echo(str("[FIT] sandwich bolt stack ", sandwich_stack, " mm → M4 x ",
             ceil((sandwich_stack + 2.5) / 5) * 5, " (nut inside flange, 2–3 mm protrusion)"));
}

module geo_report() {
    echo(str("[GEO] fan axis z=", fan_center_z, " above shelf (", fan_center_zl, " above plate); MSI base z=",
             device_base_z, "; outlet ", outlet_w, "x", outlet_h, " @zl", outlet_cz,
             "; inlet ", inlet_w, "x", inlet_h, "; area ratio ", (inlet_w * inlet_h) / (outlet_w * outlet_h)));
    echo(str("[GEO] y: fan 0..", y_duct_in, "; duct ..", y_duct_out, "; MSI ", y_device_front, "..",
             y_device_rear, "; exhaust zone to ", y_track_end, "; rails setback ", rail_front_setback));
}
