# dual-spark-4u — 5U-модуль с 2 × MSI EdgeXpert AI (DGX Spark-class) и раздельным охлаждением для 18U шкафа

Параметрический OpenSCAD-проект самостоятельного 5U-узла: фронтальная панель
ЦМО ФП-5 с двумя вырезами под 140-мм вентиляторы, алюминиевая base_plate на
полке шкафа, два holder'а (адаптация
[alexliesenfeld/dgx-spark-printables](https://github.com/alexliesenfeld/dgx-spark-printables),
CC BY-NC 4.0), два независимых воздуховода 140 → передняя решётка MSI, свободный
выхлоп в горячую зону шкафа. Имя репозитория историческое: v1 проектировалась
под 4U-корпус (`docs/TZ_v1_chassis.md`), v2 — модуль в шкафу (`docs/TZ.md`).

```
[решётка ARCTIC 140] → [ФП-5] → [Arctic P14 Pro PST 27] → [duct 120] → [EPDM 5] → [MSI 151] → [выхлоп ≥ 90]
                                   × 2 трака, оси x = ±98 от центра панели
```

## Статус: PREVIEW — ждёт пять замеров шкафа

Сборка модуля, base_plate и вертикальная разметка панели **не собираются**, пока
в `scad/params.scad` стоят `undef` для `rack_opening_w`, `shelf_top_z`,
`shelf_depth`, `panel_t`, `panel_hole_pitch_v` (`docs/03_measure_checklist.md`,
п.1–5). Детали, не зависящие от шкафа (holder, воздуховод, заслонка, уголок,
стойка DC), собираются и лежат в `stl/*_PREVIEW.stl`; рендеры сборки сделаны на
подстановочных значениях, перечисленных в `scripts/export_all.sh` и
`docs/02_layout.md` §7.

| Документ | Что |
|----------|-----|
| `docs/TZ.md` | ТЗ v2 (принятые решения) |
| `CLAUDE.md` | решения, открытые вопросы, журнал |
| `docs/01_analysis.md` | MSI EdgeXpert, исходник holder'а, опыт сообщества (+архив анализа 4U) |
| `docs/02_layout.md` | размерная схема модуля, координаты, проверки |
| `docs/03_measure_checklist.md` | что измерить (шкаф, панель, MSI, покупные) |
| `docs/04_aero_estimate.md` | расход, характеристика P14 Pro PST, рабочая точка, байпас, дверь шкафа |
| `docs/05_bom_hardware.md` | печатные/покупные части, крепёж, длина болтов |
| `docs/06_dimensions.md` | таблица размеров |
| `docs/07_rack_layout.md` | раскладка 18U, холодная/горячая зона, датчики, установка/снятие |
| `docs/drawings/` | `panel_fp5`, `base_plate`, `side_view`, `top_view` (SVG + PNG) |
| `docs/renders/` | 3D-превью (`*_PREVIEW.png`) |

## Ключевые размеры

| | мм |
|---|---|
| Трак / шаг / пара | 181 / 196 / 377 |
| Длина модуля от задней плоскости панели | 393 (шкаф 600) |
| Ось вентилятора над полкой / над плитой | 78 / 75 (= ось MSI) |
| Вырезы панели | 2 × Ø138 на 143.3 и 339.3 от левого края; ось по вертикали = `shelf_top_z` + 78 ∈ [90; 131.5] |
| Воздуховод | 135×135 → 145×57, plenum 50 + nozzle 70, стенка 2.4 |
| Болт сэндвича | M4×40 при panel_t 1.0–2.0 |

## Файлы

```
scad/params.scad          все параметры [SRC]/[ASSM]/TO_MEASURE(undef), производные, part_checks()/rack_checks()
scad/lib/shapes.scad      примитивы, лофт, макеты
scad/edgexpert_holder.scad  holder (part=holder|holder_with_device|baffle|holder_with_baffle)
scad/duct.scad            воздуховод (part=duct|duct_a|duct_b|duct_section)
scad/front_panel.scad     ФП-5 с вырезами (part=panel|panel_2d) — требует TO_MEASURE
scad/base_plate.scad      base_plate (требует TO_MEASURE), panel_bracket, dc_jack_bracket
scad/assembly.scad        модуль (part=module|exploded|track|printables)
scad/fan_bracket.scad     ОПЦИЯ: рамка для настольного стенда
stl/                      *_PREVIEW.stl до заполнения TO_MEASURE
scripts/export_all.sh     пересборка STL, рендеров, чертежей (суффикс PREVIEW автоматически)
scripts/make_drawings.py  чертежи из params.scad
```

## Как пользоваться

1. Измерить п.1–5 (и по возможности B/C) из `docs/03_measure_checklist.md`,
   вписать в `scad/params.scad` вместо `undef`.
2. `./scripts/export_all.sh` — при полных параметрах суффикс `_PREVIEW`
   исчезает, рендеры и чертежи пересчитываются на реальных размерах; в выводе не
   должно быть `ERROR: Assertion`.
3. Резать панель и сверлить плиту по `docs/drawings/panel_fp5.svg` и
   `base_plate.svg`; печатать по `docs/05_bom_hardware.md` (PETG прототип, ASA
   финал); собирать по `docs/07_rack_layout.md` §5.

Ручной экспорт одной детали:

```sh
openscad -o stl/edgexpert_holder.stl scad/edgexpert_holder.scad
openscad -o stl/bypass_baffle_050.stl -D 'part="baffle"' -D bypass_block=0.5 scad/edgexpert_holder.scad
openscad -o stl/duct.stl scad/duct.scad
openscad -o stl/panel_bracket.stl -D 'part="panel_bracket"' scad/base_plate.scad
```

## Лицензия

Производная работа от dgx-spark-printables (CC BY-NC 4.0, Alexander Liesenfeld) —
на тех же условиях, некоммерчески, с указанием автора исходника.
