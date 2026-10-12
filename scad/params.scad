/*
 * dual-spark-4u — общие параметры проекта (v3: замеры раундов 1+2 внесены).
 *
 * ВСЕ размеры в миллиметрах. Оси модуля:
 *   X = ширина, 0 = ось симметрии модуля (= ось панели ФП-5 и base_plate)
 *   Y = глубина, 0 = ЗАДНЯЯ плоскость панели ФП-5 (= передняя грань стоек);
 *       панель, решётки и рамки контроллеров лежат в y < 0, тракт растёт в +Y
 *   Z = высота, 0 = верх полки шкафа (= низ base_plate)
 * Детали трака (holder, duct) строятся в локальных координатах:
 *   x = 0 — левая наружная грань holder'а, z = 0 — ВЕРХ base_plate.
 *
 * Статус параметра:
 *   [MEAS п.N] — замер (docs/08_measurements.md, пункт N сводки)
 *   [SRC]      — источник (паспорт, стандарт, ТЗ)
 *   [ASSM]     — инженерное допущение, обосновано в документации
 *   TO_MEASURE — неизвестно → undef. Деталь, которой оно нужно, не собирается
 *                (assert) и не экспортируется; остальные детали не блокируются.
 */

// ---------------------------------------------------------------------------
// 1. УСТРОЙСТВО: MSI EdgeXpert AI (MS-C931)
// ---------------------------------------------------------------------------
device_width  = 151;   // [MEAS п.6]
device_depth  = 150;   // [MEAS п.6]
device_height = 51;    // [MEAS п.6] корпус без ножек (с ножками 56.3)
device_mass_kg = 1.2;  // [SRC]

device_foot_dia     = 14.2; // [MEAS п.7]
device_foot_height  = 5.3;  // [MEAS п.7]
device_foot_inset_x = 16.3; // [MEAS п.7] центр ножки от боковой грани
device_foot_inset_y = 22;   // [MEAS п.7] центр ножки от передней/задней грани

// Передняя сотовая решётка — полоса у НИЗА передней грани
honeycomb_w  = 138.2;  // [MEAS п.8] (по бокам 6.2)
honeycomb_h  = 22.4;   // [MEAS п.8]
honeycomb_z0 = 6.0;    // [MEAS п.8] низ полосы над низом корпуса. Привязка от низа:
                       // 6.0 + 22.4 + 23.5 (от верха) = 51.9 ≠ 51 → расхождение 0.9 мм,
                       // покрыто полями выхода воздуховода (outlet_margin_*)

// Нижняя решётка (в днище), вид спереди: у ЛЕВОГО края, середина глубины
bottom_vent_w  = 50.1; // [MEAS п.9]
bottom_vent_d  = 38.2; // [MEAS п.9]
bottom_vent_x0 = 11;   // [MEAS п.9] от левого края (справа 87.2: сумма 148.3 ≠ 151, ±2)
bottom_vent_y0 = 59.7; // [MEAS п.9] от передней грани (сзади 54.5: сумма 152.4 ≠ 150, ±2)

// Задний выхлоп — полоса у ВЕРХА задней грани (привязка от верха)
rear_exhaust_w   = 143.6; // [MEAS п.10] (по бокам 5.4)
rear_exhaust_h   = 24.4;  // [MEAS п.10]
rear_exhaust_top = 4.4;   // [MEAS п.10] верх полосы ниже верха корпуса

// Датчик T_out: центр выхлопа
t_out_below_top = 17;  // [MEAS вывод] ниже верха корпуса
t_out_behind    = 15;  // [MEAS вывод] за задней гранью

rear_port_z0 = undef;  // TO_MEASURE п.14b низ портов/кнопки над низом корпуса (справочно;
                       // задние упоры по умолчанию ≤ 4 мм, у углов)

// ---------------------------------------------------------------------------
// 2. ВЕНТИЛЯТОР: Arctic P14 Pro PST (ACFAN00314A)
// ---------------------------------------------------------------------------
fan_model      = "Arctic P14 Pro PST";
fan_size       = 140;    // [SRC]
fan_thickness  = 27;     // [SRC]
fan_corner_t   = undef;  // TO_MEASURE п.13b толщина в углу по резиновым амортизаторам (в пакете болта)
fan_mass_g     = 242;    // [SRC]
fan_hole_pitch_min = 124.5; // [SRC] стандарт 140 мм
fan_hole_pitch_max = 126;   // [MEAS п.13] замер на P14 Pro → все отверстия = пазы 124.5…126
fan_hole_dia   = 4.5;    // под M4
fan_open_dia   = 138;    // [ASSM] вырез в панели (без решётки)
fan_hub_dia    = 45;     // [ASSM]
fan_rpm_min    = 400;    // [SRC]
fan_rpm_max    = 2500;   // [SRC]
fan_q_max_m3h  = 186;    // [SRC]
fan_p_max_mmH2O = 5.2;   // [SRC]
fan_i_a        = 0.35;   // [SRC]
pwm_min_percent = 20;    // [SRC] 0 об/мин при PWM < 5 % → минимум 15–20 %, автостоп запрещён

grille_stack_t = 1.3;    // [MEAS п.14] толщина решётки ARCTIC в углу (в пакете болта)
grille_depth   = 3.8;    // [MEAS п.14] общая высота решётки (выступ перед панелью)

// ---------------------------------------------------------------------------
// 3. ШКАФ 18U, ПОЛКА, ПАНЕЛЬ ФП-5
// ---------------------------------------------------------------------------
rack_opening_w = 450;    // [MEAS п.1] между внутренними гранями передних стоек
shelf_top_z    = 40;     // [MEAS п.2] верх полки над нижним краем ФП-5
shelf_depth    = 445;    // [MEAS п.3] (передний край полки принят на y = 0 — [ASSM])
door_gap       = 65;     // [MEAS п.12] стекло двери ↔ передняя грань стойки (= y 0)
air_inlet_h    = 60;     // [MEAS п.16] щель по низу передней стенки (между ИБП и полом)
rack_depth     = 600;    // [SRC]

panel_w        = 482.6;  // [SRC] карточка ЦМО
panel_h        = 221.5;  // [SRC]
panel_fold     = 10;     // [SRC] отбортовка внутрь
panel_edge_keepout = 15; // [SRC ТЗ v2] вырезы, фланцы и отверстия ≥ 15 мм от краёв
panel_t        = 3.5;    // [MEAS п.4] лист + пылевой фильтр (временно) — входит в пакет болта
panel_sheet_t  = undef;  // TO_MEASURE п.4a лист без фильтра (справочно)
panel_color    = [0.78, 0.78, 0.76]; // RAL 7035

// Уши ФП-5 — справочно, на геометрию модуля не влияют (рисуются на чертеже, если заданы)
ear_hole_low   = undef;  // TO_MEASURE п.5a низ панели → центр нижнего отверстия
ear_hole_high  = undef;  // TO_MEASURE п.5b низ панели → центр верхнего отверстия
ear_hole_count = undef;  // TO_MEASURE п.5c
rack_ear_hole_spacing = 465.1; // [SRC EIA-310] между центрами отверстий ушей по горизонтали

// ---------------------------------------------------------------------------
// 4. BASE PLATE (алюминий 3 мм) И УГОЛКИ
// ---------------------------------------------------------------------------
base_plate_t         = 3;    // [SRC ТЗ v2]
base_plate_side_gap  = 3;    // [SRC ТЗ v2] ширина = rack_opening_w − 2×3
base_plate_depth_min = 330;  // [SRC ТЗ v2]
base_plate_front_gap = 2;    // [ASSM] от задней плоскости панели до переднего края плиты

// Печатные уголки panel↔base_plate не печатаем: панель и плита крепятся через
// штатные отверстия (решение пользователя 2026-10-12, фото IMG_5497). При false
// в панели и плите нет отверстий под уголки, уголок — только опциональный STL.
use_panel_brackets = false;  // [ASSM]

bracket_w      = 30;   // [ASSM]
bracket_h      = 60;   // [ASSM]
bracket_d      = 50;   // [ASSM]
bracket_t      = 5;    // [ASSM]
bracket_hole_d = 4.5;  // M4

// ---------------------------------------------------------------------------
// 5. ТРАКТ: решётка → панель → вентилятор → воздуховод → MSI → выхлоп
// ---------------------------------------------------------------------------
fan_axis_above_plate = 75;  // [SRC ТЗ v2] = центр полосы сот MSI (MSI поднят под ось)

plenum_len   = 50;   // [ASSM] (ТЗ 40–80), включая входной фланец
nozzle_len   = 150;  // [MEAS вывод] сужение ~5:1 → длинное сопло; включая выходной фланец
duct_wall    = 2.4;  // [ASSM]
duct_flange_t = 6;   // [ASSM]
duct_inlet_corner_r  = 20;  // [MEAS вывод] ≥ R20
duct_outlet_corner_r = 6;   // ограничено высотой выхода
duct_min_bend_r = 20;       // [MEAS вывод] минимальный радиус кривизны стенки сопла (assert)
duct_slices  = 36;
duct_split   = false;       // true → две части по границе plenum/nozzle
duct_tongue  = 2;
guide_vanes  = 0;
vane_t       = 1.6;

// Выход воздуховода = полоса сот + поля
outlet_margin_side = 1;   // [ASSM]
outlet_margin_top  = 3;   // [ASSM]
outlet_margin_bot  = 1;   // [ASSM] (покрывает расхождение 0.9 мм привязки сот)
// Подача холодного воздуха под днище (к нижней решётке и стенкам корпуса):
// вырез выхода опускается ниже дна корпуса на under_feed_h. false → снизу
// уплотнение EPDM 5 мм на полосе 5 мм под сотами (герметичный вариант).
under_feed   = true;  // [ASSM] предмет испытаний (docs/04 §7)
under_feed_h = 3;     // [ASSM]

gasket_t     = 5;    // [ASSM] EPDM 5×5 между выходным фланцем и MSI
gasket_w     = 5;    // [ASSM] ширина ленты (снизу под сотами всего 5 мм полосы)

rear_free_zone = 90; // [SRC ТЗ v2]

// ---------------------------------------------------------------------------
// 6. HOLDER (адаптация spark-rack-10 holder): опоры под ножки вместо рельсов
// ---------------------------------------------------------------------------
holder_side_clearance = 10;
holder_rear_clearance = 1;
holder_wall      = 5;
holder_floor_t   = 5;
pedestal_size    = 24;   // [ASSM] квадратная опора под ножку
pedestal_r       = 3;
foot_pocket_clear = 0.5; // [ASSM] радиальный зазор гнезда ножки
foot_pocket_depth = 2;   // [ASSM]
back_stop_t      = 3;
back_stop_h_above_body = 4;  // [ASSM] упор выше низа корпуса (не доходит до портов)
back_stop_overlap = 3;       // [ASSM] заход упора за угол корпуса
guide_wall_extra_h = 15;     // низкие боковые направляющие над низом корпуса
front_post_len   = 25;
front_post_w     = 10;
step_r           = 5;

holder_mount_slot_l   = 10;
holder_mount_slot_w   = 4.5;
holder_mount_cbore_d  = 9;
holder_mount_cbore_h  = 2.5;
holder_mount_pitch_x  = 80;   // [ASSM] вне опор; сверловка base_plate — по этим значениям
holder_mount_pitch_y  = 120;  // [ASSM]

strap_slots      = true;
strap_slot_w     = 22;
strap_slot_h     = 3;

sensor_pocket_d  = 6.2;
sensor_pocket_h  = 10;
// Стойка T_out: тонкое ребро за вилками кабелей + консоль к точке замера
t_out_post_behind = 50;  // [ASSM] ребро стоит на 50 мм за задней гранью (за вилками USB-C/HDMI/QSFP)
t_out_fin_t       = 3;
t_out_fin_len     = 12;
t_out_arm_h       = 6;

// Заслонка под днищем (сзади): закрывает выход подаваемого под днище воздуха назад.
// 0 = открыто, 1 = закрыто до днища. Вставляется сверху в пазы боковых стенок.
bypass_block     = 0.5;   // [ASSM] предмет испытаний
baffle_t         = 3;
baffle_clearance = 0.3;
baffle_groove_depth = 2;
baffle_y_body    = 145;   // [ASSM] от передней грани MSI (за задними опорами, до упоров)

// ---------------------------------------------------------------------------
// 7. ЭЛЕКТРИКА (base_plate) — только WAGO и DC-гнездо
// ---------------------------------------------------------------------------
dc_jack_inline   = true;  // [ASSM] гнездо — кабельная «мама» 5.5×2.5 под штекер БП (пользователь
                          // 2026-10-12): стяжкой к площадкам на 2 отверстиях M3 в правой полосе,
                          // провода → WAGO; стойка dc_jack_bracket не нужна
dc_jack_d        = undef; // TO_MEASURE п.15 — только для панельного гнезда (dc_jack_inline = false)
ctrl_zone_margin = 2;
strip_holes_pitch = [20, 30];  // [ASSM] 2×2 отверстия M3 в каждой полосе: печатный держатель WAGO /
                               // площадки стяжек (WAGO 221-500 — по месту)

// ---------------------------------------------------------------------------
// 8. ТЕРМОКОНТРОЛЛЕРЫ — на лицевой стороне ФП-5 над вентиляторами (TZ §4.1)
// ---------------------------------------------------------------------------
// Контроллер — панельный корпус с защёлками (фото пользователя 2026-10-12):
// лицевая рамка с дисплеем °C / ×100 об/мин и кнопками +, −/OK, сзади провода
// 12 В, вилка вентилятора и вилка XH датчика NTC (капля на проводе). Корпус
// вставляется СПЕРЕДИ в прямоугольный вырез лицевой стенки печатной рамки
// ctrl_bezel и держится своими защёлками; сталь ФП-5 прямоугольно не режется.
ctrl_cut_w   = undef;  // TO_MEASURE п.11a корпус за лицевой рамкой без защёлок: ширина (= вырез)
ctrl_cut_h   = undef;  // TO_MEASURE п.11a то же: высота
ctrl_w       = undef;  // TO_MEASURE п.11b корпус за рамкой по зубьям защёлок: ширина
ctrl_h       = undef;  // TO_MEASURE п.11b то же: высота (рамка встаёт над вентилятором при ≤ 24.7)
ctrl_d       = undef;  // TO_MEASURE п.11c глубина за лицевой рамкой с вилками проводов и датчика
ctrl_frame_w = undef;  // TO_MEASURE п.11d лицевая рамка контроллера: ширина
ctrl_frame_h = undef;  // TO_MEASURE п.11d высота
ctrl_frame_t = undef;  // TO_MEASURE п.11d толщина (выступ перед вырезом)
ctrl_clip_t  = undef;  // TO_MEASURE п.11e толщина стенки под защёлки: задняя грань рамки ↔ зуб защёлки

bezel_wall      = 3;
bezel_back_t    = 1.5;
bezel_clear     = 0.4;
bezel_cut_clear = 0.3;  // [ASSM] вырез под корпус: + 0.3 к ctrl_cut_*
bezel_lug_w     = 10;
bezel_lug_t     = 7;
bezel_lug_h     = 14;
bezel_fan_clearance = 2;
door_margin     = 3;    // [SRC ТЗ п.8] всё перед панелью ≤ door_gap − 3
cable_hole_d    = 12;   // [SRC ТЗ п.8]
cable_hole_gap  = 8;
cable_hole_side = 1;
// Датчик контроллера — на лицевой стороне, в притоке (решение пользователя
// 2026-10-12, вместо T_out): NTC свисает из втулки в нижней стенке рамки перед
// верхом решётки, в поток, который засасывает вентилятор.
ctrl_probe_d    = undef; // TO_MEASURE п.11f наибольший диаметр капли NTC-датчика
ctrl_probe_fit  = 0.3;   // [ASSM] зазор в отверстии втулки (провод фиксируется каплей силикона)
ctrl_probe_wall = 1.6;   // [ASSM] стенка втулки
ctrl_probe_boss = 12;    // [ASSM] втулка вниз от рамки
ctrl_probe_gap  = 5;     // [ASSM] датчик ↔ лицо магнитного фильтра на решётке
front_filter_t  = 1.5;   // [SRC аналог: Akasa GRM14 140 мм] магнитный фильтр 140 мм поверх стальной
                         // решётки ARCTIC; уточнить п.21. Не в пакете болта.
ctrl_probe_dx   = 0;     // [ASSM] смещение втулки от центра рамки по x

// ---------------------------------------------------------------------------
// 9. КРЕПЁЖ И ПЕЧАТЬ
// ---------------------------------------------------------------------------
m3_insert_hole_d = 4.0;  // [ASSM] по вашим вставкам
m3_insert_depth  = 6;
m3_clear_d       = 3.4;
m4_clear_d       = 4.5;
m4_nut_af        = 7.0;
m4_nut_h         = 3.2;
m4_head_d        = 8.5;
m4_lengths       = [25, 30, 35, 40, 45, 50];  // стандартный ряд DIN 912
bolt_min_protrusion = 1.5;   // за гайкой
print_bed_x = 330;    // [MEAS] стол принтера пользователя 330 × 320 (макс.)
print_bed_y = 320;    // [MEAS]
print_bed_z = 250;    // [ASSM] высота печати не названа; самая высокая деталь — воздуховод 200
                      // (если высота < 200 — воздуховод из двух частей, duct_split)
$fn = 48;

// ===========================================================================
// ПРОИЗВОДНЫЕ ВЕЛИЧИНЫ (не редактировать)
// ===========================================================================
function known(v) = !is_undef(v);
function first_ge(list, v) = [for (x = list) if (x >= v) x][0];

// --- вертикаль (локально: над верхом base_plate) ---------------------------
hz0 = base_plate_t;
fan_center_zl     = fan_axis_above_plate;                         // 75
fan_center_z      = base_plate_t + fan_center_zl;                 // 78 над полкой
honeycomb_cz_body = honeycomb_z0 + honeycomb_h / 2;               // 17.2
device_base_zl    = fan_center_zl - honeycomb_cz_body;            // 57.8 — низ корпуса MSI
foot_seat_zl      = device_base_zl - device_foot_height;          // 52.5 — опора ножек
pedestal_top_zl   = foot_seat_zl + foot_pocket_depth;             // 54.5
device_top_zl     = device_base_zl + device_height;               // 108.8
t_out_zl          = device_top_zl - t_out_below_top;              // 91.8

// --- трак: ширина ------------------------------------------------------------
holder_outer_w = device_width + 2 * holder_side_clearance + 2 * holder_wall;   // 181
track_w        = max(holder_outer_w, fan_size + 2 * holder_wall);
track_cx       = track_w / 2;
device_x0      = track_cx - device_width / 2;
dev_x          = holder_wall + holder_side_clearance;   // в координатах holder'а
track_gap      = 15;
track_pitch    = track_w + track_gap;      // 196
pair_w         = 2 * track_w + track_gap;  // 377
in_flange_w    = fan_size + 2 * holder_wall;   // 150

// --- трак: глубина (y от задней плоскости панели) ---------------------------
y_fan_front    = 0;
y_duct_in      = y_fan_front + fan_thickness;     // 27
duct_len       = plenum_len + nozzle_len;         // 200
y_duct_out     = y_duct_in + duct_len;            // 227
y_holder_front = y_duct_out;
y_device_front = y_holder_front + gasket_t;       // 232
y_device_rear  = y_device_front + device_depth;   // 382
y_back_stop    = y_device_rear + holder_rear_clearance;
y_t_out        = y_device_rear + t_out_behind;
y_t_out_post   = y_device_rear + t_out_post_behind;
y_holder_rear  = y_t_out_post + t_out_fin_len / 2 + 6;
holder_depth   = y_holder_rear - y_holder_front;
y_track_end    = y_device_rear + rear_free_zone;  // 472
track_len      = y_track_end;

// --- воздуховод -------------------------------------------------------------
inlet_w    = fan_size - 2 * duct_wall;   // 135.2
inlet_h    = inlet_w;
inlet_cz   = fan_center_zl;
outlet_w   = honeycomb_w + 2 * outlet_margin_side;                                    // 140.2
outlet_z1  = device_base_zl + honeycomb_z0 + honeycomb_h + outlet_margin_top;        // 89.2
outlet_seal_z0 = device_base_zl + honeycomb_z0 - outlet_margin_bot;                  // 62.8
outlet_z0  = under_feed ? device_base_zl - under_feed_h : outlet_seal_z0;            // 54.8
outlet_h   = outlet_z1 - outlet_z0;
outlet_cz  = (outlet_z0 + outlet_z1) / 2;
outlet_honeycomb_area = outlet_w * (outlet_z1 - outlet_seal_z0);   // часть выхода напротив сот
outlet_feed_area      = outlet_w * (outlet_seal_z0 - outlet_z0);   // часть под днище
nozzle_trans_len = nozzle_len - duct_flange_t;
// smoothstep: y = Δ(3t²−2t³) → максимальная кривизна y'' = 6Δ/L² → R = L²/(6Δ)
duct_delta_top  = (inlet_cz + inlet_h / 2) - outlet_z1;
duct_delta_bot  = outlet_z0 - (inlet_cz - inlet_h / 2);
duct_delta_side = abs(outlet_w - inlet_w) / 2;
duct_bend_r_min = nozzle_trans_len * nozzle_trans_len /
                  (6 * max(duct_delta_top, duct_delta_bot, duct_delta_side));

out_flange_w  = holder_outer_w;
out_flange_z0 = 0;                                           // до base_plate: закрывает перед подднищевой зоны
out_flange_z1 = outlet_z1 + duct_wall + 8;
out_flange_h  = out_flange_z1 - out_flange_z0;
post_top_z    = out_flange_z1;
guide_top_z   = device_base_zl + guide_wall_extra_h;
duct_bolt_xs  = [front_post_w / 2, holder_outer_w - front_post_w / 2];
duct_bolt_zs  = [15, out_flange_z1 - 8];

// --- holder: опоры под ножки (координаты holder'а) ---------------------------
dev_y = gasket_t;
foot_xs = [dev_x + device_foot_inset_x, dev_x + device_width - device_foot_inset_x];
foot_ys = [dev_y + device_foot_inset_y, dev_y + device_depth - device_foot_inset_y];
// нижняя решётка в координатах holder'а
bvent_x0 = dev_x + bottom_vent_x0;
bvent_y0 = dev_y + bottom_vent_y0;
function pedestal_overlaps_vent(fx, fy) =
    (fx + pedestal_size / 2 > bvent_x0) && (fx - pedestal_size / 2 < bvent_x0 + bottom_vent_w) &&
    (fy + pedestal_size / 2 > bvent_y0) && (fy - pedestal_size / 2 < bvent_y0 + bottom_vent_d);
holder_mount_holes = [for (sx = [-1, 1], sy = [-1, 1])
    [holder_outer_w / 2 + sx * holder_mount_pitch_x / 2, dev_y + device_depth / 2 + sy * holder_mount_pitch_y / 2]];
function mount_hits_pedestal(h) = len([for (fx = foot_xs, fy = foot_ys)
    if (abs(h[0] - fx) < pedestal_size / 2 + holder_mount_cbore_d / 2 &&
        abs(h[1] - fy) < pedestal_size / 2 + holder_mount_slot_l / 2) 1]) > 0;
baffle_y_local = dev_y + baffle_y_body;
baffle_h = bypass_block * (device_base_zl - holder_floor_t - 1);

// --- панель ------------------------------------------------------------------
fan_cx_from_center = [-track_pitch / 2, track_pitch / 2];     // ±98
fan_center_z_panel = shelf_top_z + fan_center_z;              // 118 от нижнего края
fan_center_z_panel_min = panel_edge_keepout + in_flange_w / 2;             // 90
fan_center_z_panel_max = panel_h - panel_edge_keepout - in_flange_w / 2;   // 131.5
shelf_top_z_min = fan_center_z_panel_min - fan_center_z;
shelf_top_z_max = fan_center_z_panel_max - fan_center_z;
// угловые позиции пазов вентилятора (x, z от центра вентилятора) для pitch
function fan_hole_pos(sx, sz, pitch) = [sx * pitch / 2, sz * pitch / 2];
fan_hole_pitch = (fan_hole_pitch_min + fan_hole_pitch_max) / 2;  // номинал для макетов

// --- уголки и base_plate (x от оси модуля, y от задней плоскости панели) ----
bracket_cx = track_pitch / 2 + in_flange_w / 2 + 5 + bracket_w / 2;     // 193
bracket_hole_zl = [bracket_t + 12, bracket_h - 12];                      // над плитой
base_plate_w = rack_opening_w - 2 * base_plate_side_gap;                 // 444
base_plate_y0 = base_plate_front_gap;
base_plate_d = max(base_plate_depth_min, min(shelf_depth - base_plate_y0, y_track_end + 10)); // 443
ctrl_zone_x_in = track_pitch / 2 + in_flange_w / 2 + ctrl_zone_margin;  // 175
ctrl_zone_y0   = base_plate_front_gap + bracket_d + 7;
ctrl_zone_y1   = y_duct_out - 6;
ctrl_zone_d    = ctrl_zone_y1 - ctrl_zone_y0;
ctrl_zone_w    = base_plate_w / 2 - ctrl_zone_margin - ctrl_zone_x_in;
plate_holder_holes = [for (cx = fan_cx_from_center, h = holder_mount_holes)
    [cx - track_cx + h[0], y_holder_front + h[1]]];
plate_bracket_holes = use_panel_brackets ? [for (sx = [-1, 1], k = [0, 1])
    [sx * bracket_cx, base_plate_y0 + bracket_t + 12 + k * (bracket_d - bracket_t - 24)]] : [];
strip_cx = ctrl_zone_x_in + ctrl_zone_w / 2;
plate_ctrl_holes = [for (sx = [-1, 1], i = [-1, 1], j = [-1, 1])
    [sx * (strip_cx + i * strip_holes_pitch[0] / 2), ctrl_zone_y0 + 25 + j * strip_holes_pitch[1] / 2]];
dc_bracket_pos = [strip_cx, ctrl_zone_y1 - 10];
plate_dc_holes = [for (sx = [-1, 1]) dc_bracket_pos + [sx * 10, 0]];

// --- пакет болта сэндвича ---------------------------------------------------
sandwich_stack = grille_stack_t + panel_t + (known(fan_corner_t) ? fan_corner_t : fan_thickness)
                 + duct_flange_t;                                            // 37.8
sandwich_bolt_l = first_ge(m4_lengths, sandwich_stack + bolt_min_protrusion);
sandwich_protrusion = sandwich_bolt_l - sandwich_stack;

// --- рамка контроллера (только при известных габаритах) --------------------
ctrl_known = known(ctrl_cut_w) && known(ctrl_cut_h) && known(ctrl_w) && known(ctrl_h) && known(ctrl_d)
             && known(ctrl_frame_w) && known(ctrl_frame_h) && known(ctrl_frame_t) && known(ctrl_clip_t);
bezel_w = ctrl_known ? ctrl_w + 2 * (bezel_wall + bezel_clear) : undef;
bezel_h = ctrl_known ? ctrl_h + 2 * (bezel_wall + bezel_clear) : undef;
bezel_front_t = ctrl_known ? ctrl_clip_t : undef;                 // лицевую стенку берут защёлки
bezel_d = ctrl_known ? bezel_back_t + ctrl_d + bezel_clear : undef;  // до лицевой плоскости рамки
ctrl_front = ctrl_known ? panel_t + bezel_d + ctrl_frame_t : undef;  // выступ от передней грани стоек
bezel_z0_panel = fan_center_z_panel + fan_size / 2 + bezel_fan_clearance;   // 190
strip_above_fan = panel_h - bezel_z0_panel;                                  // 31.5
ctrl_h_max = strip_above_fan - 2 * (bezel_wall + bezel_clear);              // 24.7
bezel_cz_panel = ctrl_known ? bezel_z0_panel + bezel_h / 2 : undef;
bezel_lug_dx   = ctrl_known ? bezel_w / 2 + bezel_lug_w / 2 : undef;
cable_hole_dx  = ctrl_known ? bezel_w / 2 + bezel_lug_w + cable_hole_gap : undef;
// ось датчика от лицевой плоскости панели (+ к стеклу): перед решёткой с зазором
probe_known = known(ctrl_probe_d);
probe_y   = probe_known ? grille_depth + front_filter_t + ctrl_probe_gap + ctrl_probe_d / 2 : undef;
probe_r_o = probe_known ? (ctrl_probe_d + ctrl_probe_fit) / 2 + ctrl_probe_wall : undef;

// Макет MSI с измеренной геометрией (начало — левый-передний-нижний угол корпуса).
// Файл-потребитель должен подключать lib/shapes.scad (use).
module msi() {
    device_mockup(device_width, device_depth, device_height,
                  [honeycomb_w, honeycomb_h, honeycomb_z0],
                  [bottom_vent_w, bottom_vent_d, bottom_vent_x0, bottom_vent_y0],
                  [rear_exhaust_w, rear_exhaust_h, rear_exhaust_top],
                  [device_foot_dia, device_foot_height, device_foot_inset_x, device_foot_inset_y]);
}

// ===========================================================================
// ПРОВЕРКИ
// ===========================================================================
module part_checks() {
    assert(holder_outer_w <= print_bed_x && holder_depth <= print_bed_y,
           str("Holder exceeds print bed: ", holder_outer_w, " x ", holder_depth));
    assert(duct_len <= print_bed_z || duct_split, "Duct taller than print bed: set duct_split = true");
    assert(outlet_w * outlet_h < inlet_w * inlet_h, "Outlet area must be smaller than inlet area");
    assert(outlet_w + 2 * duct_wall <= device_width,
           "Outlet wider than MSI front face — gasket would miss the body");
    assert(duct_bend_r_min >= duct_min_bend_r,
           str("Nozzle bend radius ", duct_bend_r_min, " < R", duct_min_bend_r, " → lengthen nozzle_len"));
    assert(outlet_z0 - duct_wall >= 0, "Duct outlet below base plate");
    assert(fan_center_zl - in_flange_w / 2 >= 0, "Inlet flange below base plate (raise fan_axis_above_plate)");
    assert(honeycomb_z0 - outlet_margin_bot >= gasket_w || under_feed,
           "Sealed variant: strip under honeycomb narrower than gasket");
    for (fx = foot_xs, fy = foot_ys)
        assert(!pedestal_overlaps_vent(fx, fy), str("Pedestal at ", fx, ",", fy, " covers the bottom vent"));
    for (h = holder_mount_holes)
        assert(!mount_hits_pedestal(h), str("Holder mount slot ", h, " under a pedestal"));
    assert(baffle_y_local > foot_ys[1] + pedestal_size / 2 && baffle_y_local + baffle_t < dev_y + device_depth + holder_rear_clearance,
           "Baffle groove collides with rear pedestals or rear stops");
}

// Шкаф/полка/панель/плита (всё измерено → должно проходить)
module rack_checks() {
    assert(base_plate_w >= pair_w, str("Base plate too narrow: ", base_plate_w, " < pair ", pair_w));
    assert(!use_panel_brackets || 2 * bracket_cx + bracket_w <= base_plate_w,
           str("Brackets outside base plate: need ", 2 * bracket_cx + bracket_w, " > ", base_plate_w));
    assert(!use_panel_brackets || bracket_cx + bracket_w / 2 <= panel_w / 2 - panel_edge_keepout,
           "Brackets inside panel keep-out");
    assert(ctrl_zone_w >= 30, str("Electronics strip too narrow: ", ctrl_zone_w));
    assert(fan_center_z_panel >= fan_center_z_panel_min && fan_center_z_panel <= fan_center_z_panel_max,
           str("Fan cutouts leave the 15 mm panel margin: axis ", fan_center_z_panel, " not in [",
               fan_center_z_panel_min, ", ", fan_center_z_panel_max, "] → shelf_top_z in [",
               shelf_top_z_min, ", ", shelf_top_z_max, "]"));
    assert(shelf_depth >= base_plate_depth_min, str("Shelf too shallow: ", shelf_depth));
    assert(y_holder_front + holder_depth <= base_plate_y0 + base_plate_d,
           str("Holder overhangs base plate: ends at ", y_holder_front + holder_depth, " > ", base_plate_y0 + base_plate_d));
    assert(y_track_end + 20 <= rack_depth, str("Module deeper than rack: ", y_track_end + 20));
    assert(panel_t + grille_depth <= door_gap - door_margin, "Fan grille touches the glass door");
    assert(is_num(sandwich_bolt_l), str("No standard M4 length for stack ", sandwich_stack));
}

module bezel_checks() {
    assert(ctrl_known, "TO_MEASURE: ctrl_cut_* / ctrl_w / ctrl_h / ctrl_d / ctrl_frame_* / ctrl_clip_t (п.11) — габариты термоконтроллера");
    assert(probe_known, "TO_MEASURE: ctrl_probe_d (п.11f) — диаметр капли NTC-датчика контроллера");
    assert(ctrl_cut_w <= ctrl_w && ctrl_cut_h <= ctrl_h, "ctrl_cut_* (без защёлок) больше ctrl_w/h (по защёлкам)");
    assert(ctrl_frame_w >= ctrl_cut_w + 2 && ctrl_frame_h >= ctrl_cut_h + 2, "Лицевая рамка контроллера не закрывает вырез");
    assert(ctrl_clip_t >= 1.2, str("Стенка под защёлки ", ctrl_clip_t, " мм — тоньше 1.2, не напечатать прочно"));
    assert(bezel_back_t + bezel_clear + 2 <= bezel_d - bezel_front_t, "Нет места в кармане рамки за лицевой стенкой");
    assert(probe_y + probe_r_o <= bezel_d,
           str("Probe boss (front ", probe_y + probe_r_o, ") deeper than bezel ", bezel_d,
               " — reduce ctrl_probe_gap or move the probe"));
    assert(abs(ctrl_probe_dx) + probe_r_o <= bezel_w / 2 - bezel_wall, "Probe boss outside bezel width");
}

module ctrl_checks() {
    bezel_checks();
    assert(bezel_h <= strip_above_fan,
           str("Bezel ", bezel_h, " mm taller than strip above fan ", strip_above_fan,
               " mm (= 221.5 − shelf_top_z − 150; ctrl_h ≤ ", ctrl_h_max,
               "). Options: lower the shelf one rack hole (strip ≈ 44–47), place beside the fan, or behind the panel"));
    assert(bezel_cz_panel <= panel_h - panel_edge_keepout,
           str("Bezel lug holes z=", bezel_cz_panel, " inside top keep-out"));
    assert(ctrl_front <= door_gap - door_margin,
           str("Controller front at ", ctrl_front, " mm > door_gap − ", door_margin, " = ", door_gap - door_margin));
    if (bezel_cz_panel + ctrl_frame_h / 2 > panel_h)
        echo(str("WARN: лицевая рамка контроллера выходит за верх ФП-5 на ", bezel_cz_panel + ctrl_frame_h / 2 - panel_h,
                 " мм (перед заглушкой следующего юнита; не мешает, но заметно)"));
    assert(track_pitch / 2 + cable_hole_dx + cable_hole_d / 2 <= rack_opening_w / 2 - 3,
           "Cable hole outside rack opening (behind the post)");
    assert(bezel_cz_panel - cable_hole_d / 2 >= fan_center_z_panel + in_flange_w / 2 + 1,
           "Cable hole overlaps the duct inlet flange behind the panel");
}

module geo_report() {
    echo(str("[GEO] fan axis ", fan_center_zl, " above plate (", fan_center_z, " above shelf, ",
             fan_center_z_panel, " on panel); MSI body ", device_base_zl, "..", device_top_zl,
             " above plate; foot seat ", foot_seat_zl));
    echo(str("[GEO] duct ", duct_len, " (plenum ", plenum_len, " + nozzle ", nozzle_len, "): inlet ",
             inlet_w, "x", inlet_h, " → outlet ", outlet_w, "x", outlet_h, " (honeycomb part ",
             outlet_z1 - outlet_seal_z0, ", under-feed ", outlet_seal_z0 - outlet_z0, "); area ratio ",
             (inlet_w * inlet_h) / (outlet_w * outlet_h), " (", (inlet_w * inlet_h) / outlet_honeycomb_area,
             " to honeycomb part); min bend R", duct_bend_r_min));
    echo(str("[GEO] y: fan 0..", y_duct_in, "; duct ..", y_duct_out, "; MSI ", y_device_front, "..",
             y_device_rear, "; T_out ", y_t_out, "; holder to ", y_holder_rear, "; exhaust zone to ", y_track_end));
}

module fit_report() {
    rack_checks();
    echo(str("[FIT] base plate ", base_plate_w, " x ", base_plate_d, "; pair ", pair_w,
             "; holder ends at ", y_holder_front + holder_depth, " (plate ends ", base_plate_y0 + base_plate_d, ")"));
    echo(str("[FIT] sandwich: grille ", grille_stack_t, " + panel ", panel_t, " + fan ",
             known(fan_corner_t) ? str(fan_corner_t, " (corner)") : fan_thickness,
             " + flange ", duct_flange_t, " = ", sandwich_stack, " → M4x", sandwich_bolt_l,
             " (protrusion ", sandwich_protrusion, ")"));
    echo(str("[FIT] strip above fan for controller bezel ", strip_above_fan, " mm → ctrl_h ≤ ", ctrl_h_max,
             "; in front of panel ≤ ", door_gap - door_margin - panel_t, " mm"));
}

// Производные для scripts/make_drawings.py (один источник истины)
module export_derived() {
    names = ["fan_center_zl","fan_center_z","device_base_zl","foot_seat_zl","pedestal_top_zl","device_top_zl",
             "t_out_zl","holder_outer_w","track_w","track_cx","dev_x","track_pitch","pair_w","in_flange_w",
             "y_duct_in","duct_len","y_duct_out","y_device_front","y_device_rear","y_back_stop","y_t_out",
             "y_t_out_post","y_holder_rear","holder_depth","y_track_end","inlet_w","inlet_h","outlet_w",
             "outlet_z0","outlet_z1","outlet_seal_z0","outlet_h","duct_bend_r_min","out_flange_z1","post_top_z",
             "guide_top_z","fan_center_z_panel","fan_center_z_panel_min","fan_center_z_panel_max",
             "shelf_top_z_min","shelf_top_z_max","fan_hole_pitch","bracket_cx","base_plate_w","base_plate_y0",
             "base_plate_d","ctrl_zone_x_in","ctrl_zone_y0","ctrl_zone_y1","ctrl_zone_d","ctrl_zone_w",
             "sandwich_stack","sandwich_bolt_l","sandwich_protrusion","strip_above_fan","ctrl_h_max",
             "bezel_z0_panel","ctrl_known","bezel_w","bezel_h","bezel_d","bezel_cz_panel","bezel_lug_dx",
             "cable_hole_dx","baffle_y_local","baffle_h","dev_y","use_panel_brackets"];
    values = [fan_center_zl,fan_center_z,device_base_zl,foot_seat_zl,pedestal_top_zl,device_top_zl,
             t_out_zl,holder_outer_w,track_w,track_cx,dev_x,track_pitch,pair_w,in_flange_w,
             y_duct_in,duct_len,y_duct_out,y_device_front,y_device_rear,y_back_stop,y_t_out,
             y_t_out_post,y_holder_rear,holder_depth,y_track_end,inlet_w,inlet_h,outlet_w,
             outlet_z0,outlet_z1,outlet_seal_z0,outlet_h,duct_bend_r_min,out_flange_z1,post_top_z,
             guide_top_z,fan_center_z_panel,fan_center_z_panel_min,fan_center_z_panel_max,
             shelf_top_z_min,shelf_top_z_max,fan_hole_pitch,bracket_cx,base_plate_w,base_plate_y0,
             base_plate_d,ctrl_zone_x_in,ctrl_zone_y0,ctrl_zone_y1,ctrl_zone_d,ctrl_zone_w,
             sandwich_stack,sandwich_bolt_l,sandwich_protrusion,strip_above_fan,ctrl_h_max,
             bezel_z0_panel,ctrl_known,bezel_w,bezel_h,bezel_d,bezel_cz_panel,bezel_lug_dx,
             cable_hole_dx,baffle_y_local,baffle_h,dev_y,use_panel_brackets];
    for (i = [0 : len(names) - 1]) echo(str("DERIVED|", names[i], "|", values[i]));
    echo(str("DERIVED|foot_xs|", foot_xs));
    echo(str("DERIVED|foot_ys|", foot_ys));
    echo(str("DERIVED|plate_holder_holes|", plate_holder_holes));
    echo(str("DERIVED|plate_bracket_holes|", plate_bracket_holes));
    echo(str("DERIVED|plate_ctrl_holes|", plate_ctrl_holes));
    echo(str("DERIVED|plate_dc_holes|", plate_dc_holes));
}
