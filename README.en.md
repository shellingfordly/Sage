<p align="center">
  <img src="docs/assets/sage_logo.svg" alt="Sage logo" width="96" height="96" />
</p>

# Sage（智账）

> **English** · [简体中文](README.md)

**Sage**（智账）is a Flutter-based, **local-first** personal ledger app. Track income, expenses, and wealth across multiple ledgers, set budgets, visualize spending, filter transactions on the **Statistics** tab, and get on-device **Analysis** (rule-based spending insights)—no account sign-up or cloud sync required.

---

## Features at a Glance

| Tab | Description |
|-----|-------------|
| **Home** | Monthly cashflow list (income/expense), swipe actions, quick add, spending alert shortcuts |
| **Statistics** | Filter bills by time range, category, and type (including wealth); inspect line items with summaries |
| **Charts** | Trends, category breakdown, liquid disk visualization; year/month periods |
| **Profile** | Ledgers, categories, budgets, wealth, backup, theme & font scale |

### Highlights

- **Multiple ledgers** with merge workflow (month, custom range, or all records)
- **Categories** for income, expense, and wealth with icons, colors, and reordering
- **Budgets** at ledger and per-category level (expense consumption only), with suggestions and risk hints
- **Wealth** as a separate record type from cashflow balance: rate, maturity date, in-app reminders; Wealth Management page with principal, net deposits, targets, maturity list, and yearly trend
- **Records** add/edit flow for expense, income, and wealth; date picker and detail bottom sheet
- **Bank statement import** from PDF (and Alipay CSV / WeChat xlsx); review before posting; wealth detection when summary mentions fixed deposits or investments
- **Backup** Excel/PDF import & export via platform file APIs; global custom import category rules (keyword matching)
- **Analysis** (standalone route): spending overview, period comparison, category shifts, monthly volatility, budget risk, anomalies, and budget suggestions
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
cd Sage
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
├── ai/                      # Rule-based analysis engine, cache, services
├── components/              # Dialogs, sheets, charts, time range pickers
├── data/                    # LedgerStore, LedgerRepository persistence
├── models/                  # Books, records, categories, wealth metadata
├── pages/                   # Home, statistics, charts, add record, profile, analysis
├── services/                # Bank bills, wealth, merge, analysis, backup
├── theme/                   # Theme, palettes, font scale, styles
└── utils/                   # Formatters, file I/O, Excel parsing
```

---

## Changelog

See [CHANGELOG.en.md](CHANGELOG.en.md) ([中文](CHANGELOG.md)).

Current version: `1.1.1+3` (see `pubspec.yaml`).

---

## Development Notes

- Default app locale is Simplified Chinese (`zh_CN`); `en_US` is also declared.
- When changing data models or storage, update `LedgerRepository` and backup import paths together.
- Before submitting changes, run `flutter analyze` and `flutter test`.
- Regenerate launcher icons: `flutter test test/tool/generate_app_icon_test.dart && dart run flutter_launcher_icons`.

---

## Contributing

Issues and pull requests are welcome. Please keep changes focused and consistent with existing patterns under `lib/components/` and `lib/theme/`.
