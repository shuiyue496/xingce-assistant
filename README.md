# 行测速算 (Xingce Speed Math Trainer)

A local-only speed-math trainer for civil-service exam (行测) mental calculation practice. No accounts, no network, no ads — all questions are generated on-device.

## Features

- **基础计算练习 (Basic Arithmetic)** — 15 drill types: two/three-digit add-sub, make-to-100/1000, multi-add, mixed add-sub, multiplication (incl. ×11, ×15), division with ±3% estimation tolerance, multiplication estimation with ±5% tolerance.
- **资料分析专项 (Data Analysis)** — 10 drills modeled on real statistics-bureau data: base-period estimation, growth estimation, increment/base comparison (greater/less), average annual growth rate with bar chart, fraction-to-decimal (±2%), base-period ratio, close-fraction comparison, average annual value.
- **数字推理训练 (Number Sequences)** — 10 sequence families (arithmetic/geometric, multi-level, powers, recurrence, factorization, fractions, mechanical split, multi-interleaved, 3×3 grids, periodic), 4-option multiple choice.
- **练习记录 (History)** — every session saved with per-question details, grouped by day, overall stats, delete individual records.
- Custom draggable numeric keypad with per-question timer and brief right/wrong feedback.

## Tech

Flutter (Dart), SQLite via sqflite, Material 3. Android only (arm64).

## Build

```sh
flutter build apk --release --target-platform android-arm64
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

## Notes

- All questions are procedurally generated — no question bank, no copyright issues.
- Data is stored locally in the app's private directory (SQLite); uninstalling the app removes it.
- Released under the MIT License.
