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
        );
      }
      if (decoded is! Map) {
        return LedgerRepositoryData.empty();
      }

      final payload = Map<String, Object?>.from(decoded);
      final ledgersRaw = payload['ledgers'];
      final currentLedgerId = payload['currentLedgerId'] as String?;
      final recordsByLedgerRaw = payload['recordsByLedger'];

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

      if (ledgers.isEmpty) {
        return LedgerRepositoryData.empty();
      }

      final fallbackLedgerId = ledgers.first.id;
      return LedgerRepositoryData(
        ledgers: ledgers,
        currentLedgerId: currentLedgerId ?? fallbackLedgerId,
        recordsByLedger: recordsByLedger,
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
  });

  final List<LedgerBook> ledgers;
  final String currentLedgerId;
  final Map<String, List<LedgerRecord>> recordsByLedger;

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
    );
  }
}
