import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ledger_book.dart';
import '../models/ledger_category.dart';
import '../models/ledger_record.dart';

class LedgerRepository {
  LedgerRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _recordsKey = 'ledger_records_v1';
  static const _defaultLedgerId = 'default-ledger';

  final SharedPreferencesAsync _preferences;

  Future<LedgerRepositoryData> loadData() async {
    final rawRecords = await _preferences.getString(_recordsKey);
    if (rawRecords == null || rawRecords.isEmpty) {
      return LedgerRepositoryData.empty();
    }

    try {
      final decoded = jsonDecode(rawRecords);
      if (decoded is List) {
        final migratedRecords =
            decoded
                .whereType<Map>()
                .map(
                  (item) =>
                      LedgerRecord.fromJson(Map<String, Object?>.from(item)),
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return LedgerRepositoryData(
          ledgers: [
            LedgerBook(
              id: _defaultLedgerId,
              name: '默认账本',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          ],
          currentLedgerId: _defaultLedgerId,
          recordsByLedger: {_defaultLedgerId: migratedRecords},
          budgetsByLedger: const {},
          categoryBudgetsByLedger: const {},
          categoriesByLedger: const {},
        );
      }
      if (decoded is! Map) {
        return LedgerRepositoryData.empty();
      }

      final payload = Map<String, Object?>.from(decoded);
      final ledgersRaw = payload['ledgers'];
      final currentLedgerId = payload['currentLedgerId'] as String?;
      final recordsByLedgerRaw = payload['recordsByLedger'];
      final budgetsByLedgerRaw = payload['budgetsByLedger'];
      final categoryBudgetsByLedgerRaw = payload['categoryBudgetsByLedger'];
      final categoriesByLedgerRaw = payload['categoriesByLedger'];
      final wealthMonthlyTargetRaw = payload['wealthMonthlyTargetByLedger'];
      final wealthYearlyTargetRaw = payload['wealthYearlyTargetByLedger'];
      final legacyWealthMonthlyTargetsRaw =
          payload['wealthMonthlyTargetsByLedger'];
      final legacyWealthYearlyTargetsRaw =
          payload['wealthYearlyTargetsByLedger'];

      final ledgers = ledgersRaw is List
          ? ledgersRaw
                .whereType<Map>()
                .map(
                  (item) =>
                      LedgerBook.fromJson(Map<String, Object?>.from(item)),
                )
                .toList()
          : <LedgerBook>[];

      final recordsByLedger = <String, List<LedgerRecord>>{};
      if (recordsByLedgerRaw is Map) {
        for (final entry in recordsByLedgerRaw.entries) {
          final key = entry.key.toString();
          final value = entry.value;
          if (value is List) {
            final records =
                value
                    .whereType<Map>()
                    .map(
                      (item) => LedgerRecord.fromJson(
                        Map<String, Object?>.from(item),
                      ),
                    )
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            recordsByLedger[key] = records;
          }
        }
      }

      final budgetsByLedger = <String, Map<String, double>>{};
      if (budgetsByLedgerRaw is Map) {
        for (final entry in budgetsByLedgerRaw.entries) {
          final ledgerId = entry.key.toString();
          final value = entry.value;
          if (value is Map) {
            final monthly = <String, double>{};
            for (final monthEntry in value.entries) {
              final monthKey = monthEntry.key.toString();
              final amountRaw = monthEntry.value;
              if (amountRaw is num) {
                monthly[monthKey] = amountRaw.toDouble();
              }
            }
            budgetsByLedger[ledgerId] = monthly;
          }
        }
      }

      final categoriesByLedger = <String, List<LedgerCategory>>{};
      if (categoriesByLedgerRaw is Map) {
        for (final entry in categoriesByLedgerRaw.entries) {
          final ledgerId = entry.key.toString();
          final value = entry.value;
          if (value is List) {
            categoriesByLedger[ledgerId] = value
                .whereType<Map>()
                .map(
                  (item) =>
                      LedgerCategory.fromJson(Map<String, Object?>.from(item)),
                )
                .toList();
          }
        }
      }

      final categoryBudgetsByLedger =
          <String, Map<String, Map<String, double>>>{};
      if (categoryBudgetsByLedgerRaw is Map) {
        for (final ledgerEntry in categoryBudgetsByLedgerRaw.entries) {
          final ledgerId = ledgerEntry.key.toString();
          final rawMonthly = ledgerEntry.value;
          if (rawMonthly is! Map) {
            continue;
          }
          final monthly = <String, Map<String, double>>{};
          for (final monthEntry in rawMonthly.entries) {
            final monthKey = monthEntry.key.toString();
            final rawCategoryMap = monthEntry.value;
            if (rawCategoryMap is! Map) {
              continue;
            }
            final categoryMap = <String, double>{};
            for (final categoryEntry in rawCategoryMap.entries) {
              final categoryName = categoryEntry.key.toString().trim();
              final amountRaw = categoryEntry.value;
              if (categoryName.isEmpty || amountRaw is! num || amountRaw <= 0) {
                continue;
              }
              categoryMap[categoryName] = amountRaw.toDouble();
            }
            if (categoryMap.isNotEmpty) {
              monthly[monthKey] = categoryMap;
            }
          }
          if (monthly.isNotEmpty) {
            categoryBudgetsByLedger[ledgerId] = monthly;
          }
        }
      }

      if (ledgers.isEmpty) {
        return LedgerRepositoryData.empty();
      }

      var wealthMonthlyTargetByLedger = _parseSingleTargets(wealthMonthlyTargetRaw);
      var wealthYearlyTargetByLedger = _parseSingleTargets(wealthYearlyTargetRaw);
      if (wealthMonthlyTargetByLedger.isEmpty) {
        wealthMonthlyTargetByLedger = _migrateLegacyTargets(
          _parseMonthlyTargets(legacyWealthMonthlyTargetsRaw),
        );
      }
      if (wealthYearlyTargetByLedger.isEmpty) {
        wealthYearlyTargetByLedger = _migrateLegacyTargets(
          _parseMonthlyTargets(legacyWealthYearlyTargetsRaw),
        );
      }

      final fallbackLedgerId = ledgers.first.id;
      return LedgerRepositoryData(
        ledgers: ledgers,
        currentLedgerId: currentLedgerId ?? fallbackLedgerId,
        recordsByLedger: recordsByLedger,
        budgetsByLedger: budgetsByLedger,
        categoryBudgetsByLedger: categoryBudgetsByLedger,
        categoriesByLedger: categoriesByLedger,
        wealthMonthlyTargetByLedger: wealthMonthlyTargetByLedger,
        wealthYearlyTargetByLedger: wealthYearlyTargetByLedger,
      );
    } on FormatException {
      return LedgerRepositoryData.empty();
    } on TypeError {
      return LedgerRepositoryData.empty();
    }
  }

  Future<void> saveData(LedgerRepositoryData data) {
    final encoded = jsonEncode({
      'ledgers': data.ledgers.map((ledger) => ledger.toJson()).toList(),
      'currentLedgerId': data.currentLedgerId,
      'recordsByLedger': {
        for (final entry in data.recordsByLedger.entries)
          entry.key: entry.value.map((record) => record.toJson()).toList(),
      },
      'budgetsByLedger': {
        for (final entry in data.budgetsByLedger.entries)
          entry.key: entry.value,
      },
      'categoryBudgetsByLedger': {
        for (final entry in data.categoryBudgetsByLedger.entries)
          entry.key: {
            for (final monthEntry in entry.value.entries)
              monthEntry.key: monthEntry.value,
          },
      },
      'categoriesByLedger': {
        for (final entry in data.categoriesByLedger.entries)
          entry.key: entry.value.map((category) => category.toJson()).toList(),
      },
      'wealthMonthlyTargetByLedger': data.wealthMonthlyTargetByLedger,
      'wealthYearlyTargetByLedger': data.wealthYearlyTargetByLedger,
    });
    return _preferences.setString(_recordsKey, encoded);
  }
}

Map<String, double> _parseSingleTargets(Object? raw) {
  final result = <String, double>{};
  if (raw is! Map) {
    return result;
  }
  for (final entry in raw.entries) {
    final ledgerId = entry.key.toString();
    final amountRaw = entry.value;
    if (amountRaw is num && amountRaw > 0) {
      result[ledgerId] = amountRaw.toDouble();
    }
  }
  return result;
}

Map<String, double> _migrateLegacyTargets(
  Map<String, Map<String, double>> legacy,
) {
  final result = <String, double>{};
  for (final entry in legacy.entries) {
    final amount = entry.value.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    if (amount > 0) {
      result[entry.key] = amount;
    }
  }
  return result;
}

Map<String, Map<String, double>> _parseMonthlyTargets(Object? raw) {
  final result = <String, Map<String, double>>{};
  if (raw is! Map) {
    return result;
  }
  for (final entry in raw.entries) {
    final ledgerId = entry.key.toString();
    final value = entry.value;
    if (value is! Map) {
      continue;
    }
    final targets = <String, double>{};
    for (final targetEntry in value.entries) {
      final key = targetEntry.key.toString();
      final amountRaw = targetEntry.value;
      if (amountRaw is num && amountRaw > 0) {
        targets[key] = amountRaw.toDouble();
      }
    }
    if (targets.isNotEmpty) {
      result[ledgerId] = targets;
    }
  }
  return result;
}

class LedgerRepositoryData {
  const LedgerRepositoryData({
    required this.ledgers,
    required this.currentLedgerId,
    required this.recordsByLedger,
    required this.budgetsByLedger,
    required this.categoryBudgetsByLedger,
    required this.categoriesByLedger,
    this.wealthMonthlyTargetByLedger = const {},
    this.wealthYearlyTargetByLedger = const {},
  });

  final List<LedgerBook> ledgers;
  final String currentLedgerId;
  final Map<String, List<LedgerRecord>> recordsByLedger;
  final Map<String, Map<String, double>> budgetsByLedger;
  final Map<String, Map<String, Map<String, double>>> categoryBudgetsByLedger;
  final Map<String, List<LedgerCategory>> categoriesByLedger;
  final Map<String, double> wealthMonthlyTargetByLedger;
  final Map<String, double> wealthYearlyTargetByLedger;

  factory LedgerRepositoryData.empty() {
    final defaultLedger = LedgerBook(
      id: 'default-ledger',
      name: '默认账本',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    return LedgerRepositoryData(
      ledgers: [defaultLedger],
      currentLedgerId: defaultLedger.id,
      recordsByLedger: {defaultLedger.id: const <LedgerRecord>[]},
      budgetsByLedger: const {},
      categoryBudgetsByLedger: const {},
      categoriesByLedger: const {},
    );
  }
}
