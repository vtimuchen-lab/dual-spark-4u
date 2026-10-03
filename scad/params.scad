/*
 * dual-spark-4u — общие параметры проекта.
 *
 * ВСЕ размеры в миллиметрах. Оси в сборке:
 *   X = ширина корпуса (слева направо, если смотреть спереди)
 *   Y = глубина корпуса (0 = плоскость всасывания вентилятора, растёт к задней стенке)
 *   Z = высота (0 = металлическое дно 4U-корпуса)
 *
 * Статус каждого параметра:
 *   [SRC]  — есть источник (ссылка в docs/01_analysis.md)
 *   [ASSM] — инженерное допущение, обосновано в документации
 *   [TO_MEASURE] — реальное значение неизвестно, ОБЯЗАТЕЛЬНО измерить
 *                  перед финальной STL (см. docs/03_measure_checklist.md)
 *
 * Файл подключается через include <params.scad> во всех остальных .scad.
 */

// ---------------------------------------------------------------------------
// 1. УСТРОЙСТВО: MSI EdgeXpert AI (MS-C931), класс DGX Spark / GB10
// ---------------------------------------------------------------------------
device_width  = 151;   // [SRC] MSI datasheet via resellers: 151 x 151 x 52 mm. TO_MEASURE штангенциркулем
device_depth  = 151;   // [SRC] то же
device_height = 52;    // [SRC] то же (без ножек? — TO_MEASURE: высота с ножками и без)
device_mass_kg = 1.2;  // [SRC] 1.2 kg

// Воздухозабор на передней грани (сотовая решётка во всю переднюю панель).
// Геометрия реальной решётки неизвестна — выставлено по внешнему габариту
// минус рамка. TO_MEASURE: ширина/высота зоны сот и её смещение от низа.
device_intake_margin_x = 3;    // [ASSM] рамка сбоку от сот
device_intake_margin_top = 3;  // [ASSM] рамка сверху
device_intake_margin_bot = 3;  // [ASSM] рамка снизу

// Ножки: 4 круглые резиновые, по углам (видно на msi.png из dgx-spark-printables).
device_foot_dia    = 16;  // [ASSM] диаметр площадки ножки. TO_MEASURE
device_foot_inset  = 20;  // [ASSM] центр ножки от бокового/переднего края. TO_MEASURE
device_foot_height = 4;   // [ASSM] «elevated stacking footpads» по MSI; TO_MEASURE

// Нижняя щелевая решётка (8 щелей) — по фото msi.png ближе к ПЕРЕДНЕМУ краю, по центру.
device_bottom_vent_w = 40;  // [ASSM] ширина поля щелей. TO_MEASURE
device_bottom_vent_d = 55;  // [ASSM] глубина поля щелей. TO_MEASURE
device_bottom_vent_front_offset = 12; // [ASSM] от переднего края. TO_MEASURE

// ---------------------------------------------------------------------------
// 2. ВЕНТИЛЯТОР 140 x 140 x 25, 12 V PWM
// ---------------------------------------------------------------------------
fan_size       = 140;    // [SRC] стандарт
fan_thickness  = 25;     // [SRC] стандарт
fan_hole_pitch = 124.5;  // [SRC] стандартная сетка отверстий 140-мм вентиляторов
fan_hole_dia   = 4.5;    // [SRC] под винт вентилятора / M4
fan_rubber_hole_dia = 5.2; // [SRC] под резиновые антивибрационные штифты
fan_open_dia   = 138;    // [ASSM] проём в кронштейне/фланце (без решётки)
fan_hub_dia    = 45;     // [ASSM] ступица типичного 140-мм (NF-A14 ≈ 44 mm) — для расчёта мёртвой зоны
fan_mount_type = "screws"; // [screws, rubber]

// ---------------------------------------------------------------------------
// 3. КОРПУС 4U — ВСЁ TO_MEASURE (фото в сессии отсутствуют)
// ---------------------------------------------------------------------------
chassis_inner_width  = 430; // [TO_MEASURE] типично 430–440 для 19" 4U
chassis_inner_height = 160; // [TO_MEASURE] типично 155–170 (4U = 177.8 внешн.)
chassis_inner_depth  = 450; // [TO_MEASURE] у 4U бывает 350…650
chassis_floor_t      = 1.2; // [TO_MEASURE] толщина дна
chassis_front_dead_zone = 25; // [TO_MEASURE] глубина, занятая передней дверцей/панелью/фильтром
chassis_rear_dead_zone  = 20; // [TO_MEASURE] глубина, занятая задней панелью/разъёмами
chassis_floor_hole_pitch_x = 0; // [TO_MEASURE] шаг существующих отверстий дна (0 = сверлить новые)
chassis_floor_hole_pitch_y = 0; // [TO_MEASURE]

// ---------------------------------------------------------------------------
// 4. ТРАКТ: кронштейн → вентилятор → воздуховод → holder → устройство → выхлоп
// ---------------------------------------------------------------------------
bracket_t          = 5;    // [ASSM] толщина передней рамки вентилятора
bracket_foot_w     = 25;   // [ASSM] ширина лапок крепления к дну
bracket_foot_d     = 30;   // [ASSM] глубина лапок
fan_floor_clearance = 5;   // [ASSM] зазор от дна до нижней кромки рамки вентилятора

plenum_len   = 50;   // [ASSM] участок выравнивания потока (ТЗ: 40–80)
nozzle_len   = 70;   // [ASSM] плавное сужение; суммарно duct = 120 (ТЗ: 100–180)
duct_wall    = 2.4;  // [ASSM] аэродинамическая оболочка (ТЗ: 2–3)
duct_flange_t = 6;   // [ASSM] фланцы воздуховода
duct_inlet_corner_r  = 12;  // [ASSM] радиус углов сечения на входе
duct_outlet_corner_r = 6;   // [ASSM] радиус углов сечения на выходе
duct_slices  = 28;   // точность лофта (больше = глаже, дольше рендер)
duct_split   = false; // true → делит воздуховод на 2 части по границе plenum/nozzle
duct_tongue  = 2;    // высота/ширина шипа tongue-and-groove при split
guide_vanes  = 0;    // число направляющих лопаток в сужении (0 = нет; 2 = две вертикальные)
vane_t       = 1.6;  // толщина лопатки

gasket_t     = 5;    // [ASSM] вспененный EPDM между фланцем воздуховода и передней гранью MSI
outlet_under_device = 8;  // [ASSM] выход воздуховода заходит ниже дна устройства (подача к нижней решётке и под ножки)
outlet_over_device  = 0;  // [ASSM] выход выше верха устройства (обычно 0 — верх MSI глухой)

align_device_to_fan = true; // true → ось выхода совпадает с осью вентилятора (прямое сопло)
device_base_z_manual = 25;  // используется, если align_device_to_fan = false

rear_free_zone = 90;  // [ASSM] свободная зона за устройством (ТЗ: 70–100)

// ---------------------------------------------------------------------------
// 5. HOLDER (адаптация spark-rack-10/dgx_spark_rack_mount.scad, part="holder")
// ---------------------------------------------------------------------------
holder_side_clearance = 10;  // [SRC] 10.5 в исходнике; 10 здесь (ширина MSI уже 151)
holder_rear_clearance = 1;   // [ASSM] зазор до заднего стопора
holder_wall      = 5;        // [SRC] 5 mm структурные стенки
holder_floor_t   = 5;        // [SRC] 5 mm дно
rail_w           = 20;       // [SRC] floor_support_width
channel_w        = 20;       // [SRC] floor_channel_width
rail_front_setback = 20;     // [SRC] floor_support_front_setback
rail_rear_setback  = 20;     // [SRC] floor_support_rear_setback
back_stop_t      = 3;        // [SRC]
back_stop_w      = 10;       // [SRC]
back_stop_extra_h = 10;      // [SRC] над опорной плоскостью
back_stop_r      = 2;        // [SRC]
guide_wall_extra_h = 15;     // [ASSM] высота боковых направляющих над дном устройства (низкие — не перекрывают боковые решётки)
front_post_len   = 25;       // [ASSM] глубина передних стоек (под фланец воздуховода)
front_post_w     = 10;       // [ASSM] ширина стойки (под heat-set M3)
step_r           = 5;        // [SRC] wall_profile_corner_radius

holder_mount_slot_l   = 10;  // [ASSM] продольный паз под M4 к дну корпуса
holder_mount_slot_w   = 4.5;
holder_mount_cbore_d  = 9;   // [ASSM] под головку M4 / шайбу
holder_mount_cbore_h  = 2.5;
holder_mount_pitch_x  = 140; // [TO_MEASURE] — согласовать с отверстиями дна корпуса
holder_mount_pitch_y  = 120; // [TO_MEASURE]

strap_slots      = true;     // пазы под 20-мм липучку для транспортировки
strap_slot_w     = 22;
strap_slot_h     = 3;

sensor_pocket_d  = 6.2;      // [ASSM] гнездо под датчик (DS18B20 TO-92 / NTC капля)
sensor_pocket_h  = 10;

// ---------------------------------------------------------------------------
// 6. КРЕПЁЖ
// ---------------------------------------------------------------------------
m3_insert_hole_d = 4.0;  // [SRC] heat-set M3 (OD 4.0–4.6) — проверить по вашим вставкам
m3_insert_depth  = 6;
m3_clear_d       = 3.4;
m4_clear_d       = 4.5;
m4_nut_af        = 7.0;  // [SRC] M4 гайка 7 mm по граням
m4_nut_h         = 3.2;
m4_head_d        = 8.5;

// ---------------------------------------------------------------------------
// 7. ПЕЧАТЬ
// ---------------------------------------------------------------------------
print_bed_x = 250;
print_bed_y = 250;
print_bed_z = 250;

$fn = 48;

// ---------------------------------------------------------------------------
// ПРОИЗВОДНЫЕ ВЕЛИЧИНЫ (не редактировать)
// ---------------------------------------------------------------------------
fan_center_z  = fan_floor_clearance + fan_size / 2;
device_base_z = align_device_to_fan ? fan_center_z - device_height / 2
                                    : device_base_z_manual;
device_center_z = device_base_z + device_height / 2;

// Локальная система трака: x=0 — левая наружная грань holder'а,
// y=0 — плоскость всасывания вентилятора (передняя грань кронштейна).
holder_outer_w = device_width + 2 * holder_side_clearance + 2 * holder_wall;
track_w        = max(holder_outer_w, fan_size + 2 * holder_wall);
track_cx       = track_w / 2;            // ось трака по X
device_x0      = track_cx - device_width / 2;

y_fan_front    = bracket_t;                       // передняя плоскость вентилятора
y_duct_in      = y_fan_front + fan_thickness;     // входной фланец воздуховода
duct_len       = plenum_len + nozzle_len;         // включая фланцы
y_duct_out     = y_duct_in + duct_len;            // задняя плоскость выходного фланца = перед holder'а
y_holder_front = y_duct_out;
y_device_front = y_holder_front + gasket_t;
y_device_rear  = y_device_front + device_depth;
y_back_stop    = y_device_rear + holder_rear_clearance;
y_holder_rear  = y_back_stop + back_stop_t;
y_track_end    = y_device_rear + rear_free_zone;
track_len      = y_track_end;

// Выход воздуховода (проём) — по зоне сот + заход под устройство
outlet_w   = device_width - 2 * device_intake_margin_x;
outlet_z0  = device_base_z - outlet_under_device;
outlet_z1  = device_base_z + device_height - device_intake_margin_top + outlet_over_device;
outlet_h   = outlet_z1 - outlet_z0;
outlet_cz  = (outlet_z0 + outlet_z1) / 2;

// Вход воздуховода (внутреннее сечение) — квадрат по рамке вентилятора
inlet_w    = fan_size - 2 * duct_wall;
inlet_h    = fan_size - 2 * duct_wall;
inlet_cz   = fan_center_z;

// Высоты holder'а
rail_top_z     = device_base_z;                     // верх рельсов = дно устройства
guide_top_z    = device_base_z + guide_wall_extra_h; // низкие боковые направляющие
post_top_z     = device_base_z + device_height + 8;  // передние стойки под фланец
back_stop_top_z = device_base_z + back_stop_extra_h;

// Фланец выхода воздуховода — по наружной ширине holder'а
out_flange_w   = holder_outer_w;
out_flange_z0  = max(0, outlet_z0 - duct_flange_t - 4);
out_flange_z1  = post_top_z;
out_flange_h   = out_flange_z1 - out_flange_z0;

// Болты M3 воздуховод→holder: по центрам передних стоек
post_cx_l = holder_wall + front_post_w / 2 - holder_wall; // от наружной грани
duct_bolt_xs = [front_post_w / 2, holder_outer_w - front_post_w / 2];
duct_bolt_zs = [device_base_z + 6, device_base_z + device_height - 4];

// Пара траков в корпусе
track_gap  = 15;  // [ASSM] зазор между траками (кабель-канал)
pair_w     = 2 * track_w + track_gap;
track_x0   = (chassis_inner_width - pair_w) / 2;  // левый трак
track_x1   = track_x0 + track_w + track_gap;      // правый трак
y_track_origin = chassis_front_dead_zone;         // трак начинается за мёртвой зоной передней панели

// Контроль сходимости (в echo, не assert, чтобы модель всегда рендерилась)
module fit_report() {
    echo(str("[FIT] track: ", track_w, " x ", track_len, " mm; pair width ", pair_w,
             " mm vs chassis inner width ", chassis_inner_width, " (TO_MEASURE) -> ",
             pair_w <= chassis_inner_width ? "OK" : "DOES NOT FIT"));
    echo(str("[FIT] depth needed: ", y_track_origin + track_len + chassis_rear_dead_zone,
             " mm vs chassis inner depth ", chassis_inner_depth, " (TO_MEASURE) -> ",
             y_track_origin + track_len + chassis_rear_dead_zone <= chassis_inner_depth ? "OK" : "DOES NOT FIT"));
    echo(str("[FIT] height needed: ", fan_floor_clearance + fan_size + 5,
             " mm vs chassis inner height ", chassis_inner_height, " (TO_MEASURE) -> ",
             fan_floor_clearance + fan_size + 5 <= chassis_inner_height ? "OK" : "DOES NOT FIT"));
    echo(str("[GEO] fan center z=", fan_center_z, "; device base z=", device_base_z,
             "; device center z=", device_center_z, "; axis offset=", fan_center_z - outlet_cz, " mm"));
    echo(str("[GEO] duct ", duct_len, " mm (plenum ", plenum_len, " + nozzle ", nozzle_len,
             "); inlet ", inlet_w, "x", inlet_h, " -> outlet ", outlet_w, "x", outlet_h,
             "; area ratio ", (inlet_w * inlet_h) / (outlet_w * outlet_h)));
    echo(str("[GEO] y: fan ", y_fan_front, "..", y_duct_in, "; duct ..", y_duct_out,
             "; device ", y_device_front, "..", y_device_rear, "; rear free zone to ", y_track_end));
}
