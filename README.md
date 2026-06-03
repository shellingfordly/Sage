# Ledger App

> **English** · [简体中文](README.zh-CN.md)

A Flutter-based **local-first** personal ledger app. Track income and expenses across multiple books, set budgets, visualize spending, filter transactions, and get on-device AI insights—without requiring a cloud account.

---

## Features at a Glance

| Tab | Description |
|-----|-------------|
| **Home** | Monthly transaction list, swipe actions, quick add, AI alert shortcuts |
| **Analysis** | Filter bills and inspect line items with summaries |
| **Charts** | Trends, category breakdown, liquid disk visualization; year/month periods |
| **Profile** | Ledgers, categories, budgets, backup, theme & font scale |

### Highlights

- **Multiple ledgers** with merge workflow (month, custom range, or all records)
- **Categories** for income/expense with icons, colors, and reordering
- **Budgets** at ledger and per-category level, with AI suggestions and risk hints
- **Records** add/edit flow with date picker and detail bottom sheet
- **Bank statement import** from PDF, review before posting
- **Backup** Excel/PDF import & export via platform file APIs
- **AI insights** overview, budget risk, anomaly detection, Q&A explanations
- **Theming** palette families, system/light/dark mode, four font scale steps

---

## Tech Stack

- **Framework**: Flutter 3.11+ (Dart SDK ^3.11.5)
- **State & storage**: `ChangeNotifier` + `shared_preferences`
- **Files**: `file_picker`, `excel`, `pdfrx`, `archive`, `xml`
- **UI**: Material-style widgets, `flutter_slidable`

---

## Requirements

- Flutter SDK matching `pubspec.yaml`
- Platform toolchain for your target (Android, iOS, desktop, or web)

---

## Getting Started

```bash
cd f_app
flutter pub get
flutter run

# Android release APK
flutter build apk
```

Data and preferences load on startup; the app works offline.

---

## Project Layout

```
lib/
├── app.dart                 # App shell, bottom navigation, routes
├── main.dart                # Initializes ledgerStore / themeController
├── ai/                      # AI analysis engine, cache, services
├── components/              # Dialogs, sheets, charts, time range pickers
├── data/                    # LedgerStore, LedgerRepository persistence
├── models/                  # Books, records, categories, import models
├── pages/                   # Home, analysis, charts, add record, profile, AI
├── services/                # Bank bills, merge, AI, backup services
├── theme/                   # Theme, palettes, font scale, styles
└── utils/                   # Formatters, file I/O, Excel parsing
```

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) ([中文](CHANGELOG.zh-CN.md)).

Current version: `0.1.0+1` (see `pubspec.yaml`).

---

## Development Notes

- Default app locale is Simplified Chinese (`zh_CN`); `en_US` is also declared.
- When changing data models or storage, update `LedgerRepository` and backup import paths together.
- Before submitting changes, run `flutter analyze` and `flutter test` (if tests exist).

---

## Contributing

Issues and pull requests are welcome. Please keep changes focused and consistent with existing patterns under `lib/components/` and `lib/theme/`.
