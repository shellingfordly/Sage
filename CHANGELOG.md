# Changelog

> **English** · [简体中文](CHANGELOG.zh-CN.md)

All notable changes to Ledger App are documented here. Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Added

- Shared form bottom sheet `AppFormSheet` for consistent ledger name and category editing
- Refactored ledger name and category editor dialogs to use the form sheet

### Changed

- Bottom navigation rework: dedicated **Analysis** and **Charts** tabs
- AI insights exposed via standalone route `AiInsightRoute`

---

## [0.1.0] - 2026-06-03

First feature-complete release (`pubspec.yaml`: `0.1.0+1`).

### Added

#### Ledgers & records

- Multiple ledgers: create, switch, rename, management page
- Income/expense records: add, edit, delete (swipe actions on home)
- Ledger merge: source/target selection, filter by month or custom range, step-by-step review
- Category management: custom name, icon, color
- Drag-to-reorder categories

#### Budgets

- Ledger-wide and per-category budgets
- Budget management UI with overspend-related hints

#### Analytics

- Charts tab: expense trends, category breakdown, liquid disk visualization
- Year/month period selection with dynamic summaries
- Analysis page: filters and record list
- Shared time range and export range components

#### Import & export

- Data backup: Excel export/import with cross-platform local file I/O
- PDF bank statement import: parse, category suggestions, review page batch posting
- Improved export success feedback and preview flow

#### AI insights

- AI module: spending overview, budget risk, anomaly detection
- Home AI alerts and dedicated AI insight page
- Month navigation, budget warning confirmation, batch suggestion apply
- AI Q&A explanation bottom sheet

#### Theme & settings

- Multiple color palette families
- Appearance: system / light / dark
- Global font scale: small, standard, large, extra large

#### Engineering & UI

- Shared dialogs, pickers, record detail and category picker sheets
- `lib/` restructure: unified paths for AI, components, ledger, services
- App init: parallel load of `ledgerStore` and `themeController`

### Changed

- Data backup split into dedicated import/export services
- Statistics moved to standalone charts module (`pages/charts/`)
- Trend bar styling and category disk shadow logic refined

### Fixed

- (This release focused on features; see individual commits for bug fixes.)

---

## [0.0.1] - Initial

### Added

- Flutter project bootstrap (`chore: init`)
- Basic home page with month switching

---

## Versioning

- Version numbers follow `pubspec.yaml`: `MAJOR.MINOR.PATCH+BUILD`.
- **Unreleased**: changes on the main branch not yet tagged.
- Change types: **Added** · **Changed** · **Fixed** · **Removed** · **Deprecated**
