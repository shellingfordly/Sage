import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ledger_record.dart';

class LedgerRepository {
  LedgerRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _recordsKey = 'ledger_records_v1';

  final SharedPreferencesAsync _preferences;

  Future<List<LedgerRecord>> loadRecords() async {
    final rawRecords = await _preferences.getString(_recordsKey);
    if (rawRecords == null || rawRecords.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawRecords);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => LedgerRecord.fromJson(Map<String, Object?>.from(item)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> saveRecords(List<LedgerRecord> records) {
    final encoded = jsonEncode(
      records.map((record) => record.toJson()).toList(),
    );
    return _preferences.setString(_recordsKey, encoded);
  }
}
