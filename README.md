# dual-spark-4u — 2 × MSI EdgeXpert AI (DGX Spark-class) в одном 4U с раздельным принудительным охлаждением

Параметрический OpenSCAD-проект внутренней механики для **существующего**
19" 4U-корпуса: два holder'а на дне, два 140-мм PWM-вентилятора, два
независимых воздуховода 140 → передняя решётка MSI, свободная выхлопная зона
сзади. Основа holder'а — `spark-rack-10/dgx_spark_rack_mount.scad` из
[alexliesenfeld/dgx-spark-printables](https://github.com/alexliesenfeld/dgx-spark-printables)
(CC BY-NC 4.0, автор Alexander Liesenfeld); передняя 10" панель, rack-ears и
отверстия 2×80 не используются.

```
[фасад 4U] → [рамка + 140 FAN] → [duct 120: plenum 50 + сопло 70] → [EPDM 5] → [MSI 151] → [≥ 90 выхлоп] → [задние 80-мм + проёмы]
      ×2 рядом, в одном слое, оси x ≈ 117 и 313 от левой стенки
```

## Статус: предварительная модель (этапы 1–5 выполнены, финальная STL — после замеров)

| Этап | Результат | Где |
|------|-----------|-----|
| 1. Анализ | MSI EdgeXpert, исходник holder'а, 2 фото корпуса, опыт сообщества | `docs/01_analysis.md` |
| 2. Размерная схема | вид сверху / сбоку / спереди с размерами, пресеты по глубине | `docs/02_layout.md`, `docs/drawings/` |
| 3. Holder | адаптация под MSI и крепление к дну 4U | `scad/edgexpert_holder.scad` → `stl/edgexpert_holder.stl` |
| 4. Воздуховод | 140 → 145×57, smoothstep-конфузор, разрезной вариант, рамка вентилятора | `scad/duct.scad`, `scad/fan_bracket.scad` → `stl/` |
| 5. Файлы | сборка, exploded, рендеры, крепёж, таблица размеров | `scad/assembly.scad`, `docs/renders/`, `docs/05_bom_hardware.md`, `docs/06_dimensions.md` |
| Аэродинамика | инженерная оценка расхода, сечений, потерь, проблемных мест | `docs/04_aero_estimate.md` |
| **Замеры** | **26 пунктов TO_MEASURE — без них STL не финальные** | `docs/03_measure_checklist.md` |

Что уже установлено (с источниками в `docs/01_analysis.md`): MSI 151×151×52,
1.2 кг, вход — соты во всю переднюю грань, выход — зад и бока, ножки
повышенные, низ почти глухой с полем щелей у переднего края; > 200 Вт под
нагрузкой.

Что видно по фото корпуса и подлежит демонтажу: HDD-корзина за дверцей,
перфорированный кронштейн за щелевой решёткой, ATX-БП. Задние 2 × 80 мм
остаются как вытяжка. Правый вентилятор оказывается за дверцей — нужно
подтвердить, что её треугольные окна открыты (сетка), иначе переделка
вставки (`docs/02_layout.md` §5).

## Ключевые размеры (по умолчанию)

| | мм |
|---|---|
| Трак (ширина × длина) | 181 × 396 |
| Пара траков | 377 (+ зазор 15 внутри) |
| Нужная внутренняя глубина 4U: default / compact | 441 / 388 |
| Нужная внутренняя высота | 150 |
| Ось вентилятора / дно MSI / верх MSI | z = 75 / 49 / 101 |
| Выход воздуховода | 145 × 57 (вход 135 × 135, отношение площадей 2.2) |

## Файлы

```
scad/params.scad          все параметры (секции 1–7) + производные + fit_report()
scad/lib/shapes.scad      примитивы, лофт, макеты вентилятора и устройства
scad/edgexpert_holder.scad  holder (part=holder | holder_with_device)
scad/duct.scad            воздуховод (part=duct | duct_a | duct_b | duct_section)
scad/fan_bracket.scad     рамка вентилятора (part=bracket | bracket_with_fan)
scad/assembly.scad        сборка (part=assembly | track | exploded | printables)
stl/                      экспорт: holder, duct, duct_part_a/b, fan_bracket
docs/drawings/            top/side/front view (SVG + PNG), генерируются скриптом
docs/renders/             PNG-превью из OpenSCAD
scripts/export_all.sh     пересборка STL, рендеров и чертежей
scripts/make_drawings.py  размерные схемы из params.scad
```

## Как пользоваться

1. Снять размеры по `docs/03_measure_checklist.md`, внести в `scad/params.scad`.
2. `./scripts/export_all.sh` (OpenSCAD ≥ 2021.01, xvfb-run для PNG, python3).
3. Проверить строки `[FIT] ... -> OK` в выводе `assembly.scad`.
4. Печать: PETG для прототипа, ASA для постоянной версии; настройки и
   ориентация — в `docs/05_bom_hardware.md`.

Экспорт отдельной детали вручную:

```sh
openscad -o stl/edgexpert_holder.stl scad/edgexpert_holder.scad
openscad -o stl/duct.stl scad/duct.scad
openscad -o stl/duct_part_a_plenum.stl -D 'duct_split=true' -D 'part="duct_a"' scad/duct.scad
openscad -o stl/fan_bracket.stl scad/fan_bracket.scad
```

Параметры корпуса можно переопределять без правки файла:
`openscad -o /dev/null -D chassis_inner_depth=400 -D plenum_len=40 -D nozzle_len=60 -D rear_free_zone=70 -D chassis_front_dead_zone=12 scad/assembly.scad`.

## Модульность и сервис

Рамка вентилятора — вентилятор — воздуховод — holder соединяются болтами
(M4 сэндвич, M3 в heat-set), holder и рамка — к дну на M4 (rivnut/гайки).
Каждое устройство вынимается вверх независимо (верх открыт, стопоры низкие),
вентилятор меняется без снятия воздуховода, воздуховод снимается с holder'а
по 4 винтам M3.

## Лицензия

Производная работа от dgx-spark-printables (CC BY-NC 4.0) — распространяется
на тех же условиях, некоммерчески, с указанием автора исходника.
