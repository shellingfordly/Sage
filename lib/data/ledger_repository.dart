import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ledger_book.dart';
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
        final migratedRecords = decoded
            .whereType<Map>()
            .map((item) => LedgerRecord.fromJson(Map<String, Object?>.from(item)))
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

      final ledgers = ledgersRaw is List
          ? ledgersRaw
                .whereType<Map>()
                .map((item) => LedgerBook.fromJson(Map<String, Object?>.from(item)))
                .toList()
          : <LedgerBook>[];

      final recordsByLedger = <String, List<LedgerRecord>>{};
      if (recordsByLedgerRaw is Map) {
        for (final entry in recordsByLedgerRaw.entries) {
          final key = entry.key.toString();
          final value = entry.value;
          if (value is List) {
            final records = value
                .whereType<Map>()
                .map((item) => LedgerRecord.fromJson(Map<String, Object?>.from(item)))
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

      if (ledgers.isEmpty) {
        return LedgerRepositoryData.empty();
      }

      final fallbackLedgerId = ledgers.first.id;
      return LedgerRepositoryData(
        ledgers: ledgers,
        currentLedgerId: currentLedgerId ?? fallbackLedgerId,
        recordsByLedger: recordsByLedger,
        budgetsByLedger: budgetsByLedger,
      );
    } on FormatException {
      return LedgerRepositoryData.empty();
    } on TypeError {
      return LedgerRepositoryData.empty();
    }
  }

  Future<void> saveData(LedgerRepositoryData data) {
    final encoded = jsonEncode(
      {
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
      },
    );
    return _preferences.setString(_recordsKey, encoded);
  }
}

class LedgerRepositoryData {
  const LedgerRepositoryData({
    required this.ledgers,
    required this.currentLedgerId,
    required this.recordsByLedger,
    required this.budgetsByLedger,
  });

  final List<LedgerBook> ledgers;
  final String currentLedgerId;
  final Map<String, List<LedgerRecord>> recordsByLedger;
  final Map<String, Map<String, double>> budgetsByLedger;

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
    );
  }
}
