# Changelog

> **English** · [简体中文](CHANGELOG.md)

All notable changes to **Sage**（智账）are documented here. Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Added

- **About** page with app description, developer info, and version
- Sage logo (`SageLogo`) and launcher icons for Android, iOS, macOS, Windows, and Web
- English README moved to `README.en.md`; Chinese is the default `README.md`
- English changelog moved to `CHANGELOG.en.md`; Chinese is the default `CHANGELOG.md`
- Shared form bottom sheet `AppFormSheet` for consistent ledger name and category editing
- Refactored ledger name and category editor dialogs to use the form sheet
- **Statistics** tab: time-range filters, folder-style grouped record list, sort options, and summary toolbar
- Rule-based **Analysis** engine: consumption-only filtering (excludes transfers, fixed deposits, repayments)
- Period comparison, headline conclusions, category shift breakdown, and peak-volatility month detection
- Configurable analysis scopes for single month, multi-month, and custom ranges
- Drill-down from Analysis panels to the Statistics tab with pre-filled filters (`AnalysisDrillDown`)
- **Wealth** record type: separate from income/expense cashflow; dedicated categories, metadata (rate, maturity, in-app reminder), and Wealth Management page
- Wealth principal & net-deposit analytics, maturity list, yearly trend chart with amounts, and per-ledger monthly/yearly deposit targets
- Statistics tab **Wealth** filter; home and default statistics exclude wealth from balance
- Record detail sheet delete action; bill import review supports wealth type editing
- Bill import UI redaction for sensitive fields in source lines (`redactBankBillSourceLine`)

### Changed

- App display name unified to **Sage** across Android, iOS, macOS, and Web
- Documentation and changelog naming aligned with **Sage**（智账）branding
- Bottom navigation labels: bill filtering tab renamed to **Statistics**; standalone analysis route titled **Analysis**
- Analysis page rebuilt as a rule-driven layout (conclusions → comparison → categories → volatility → overview → notable items)
- Cross-month scopes show read-only expense reference instead of editable monthly budget apply
- Home spending alerts simplified (budget warning + anomaly count; no unread badge ack flow)
- Legacy income/expense category「理财」 migrated to `wealth` type on load
- Wealth targets simplified to one monthly and one yearly goal per ledger (legacy per-period values migrated on load)
- Wealth management uses current-month/year stats; records open detail sheet on tap; wealth type locked when editing
- Category management type switcher uses compact labels; record detail sheet drops redundant close button
- Profile wealth entry subtitle shortened; README quick-start path corrected to `Sage`

### Removed

- Q&A explanation bottom sheet and preset question panel
- Alert acknowledgement store and batch budget-suggestion apply service
- Unused helpers (`iconForCategory`, `BillImportSource.wechat`)
- Record detail sheet close button (dismiss via drag handle)

### Fixed

- `TimeRangePanel` bottom corner radius and built-in border styling
- Category type segmented control text overflow on narrow screens
- Skipped bank-import rows no longer use full raw line as default record title

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

#### Spending analysis

- Analysis module: spending overview, budget risk, anomaly detection
- Home spending alerts and dedicated analysis page
- Month navigation, budget warning confirmation, batch suggestion apply
- Q&A explanation bottom sheet

#### Theme & settings

- Multiple color palette families
- Appearance: system / light / dark
- Global font scale: small, standard, large, extra large

#### Engineering & UI

- Shared dialogs, pickers, record detail and category picker sheets
- `lib/` restructure: unified paths for analysis, components, ledger, services
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
