import '../../models/ledger_record.dart';
import '../../models/ai_insight_models.dart';

class AiInsightCache {
  static const _cacheSchemaVersion = 2;

  String? _lastKey;
  AiInsightSnapshot? _lastSnapshot;

  AiInsightSnapshot getOrBuild({
    required String ledgerId,
    required List<LedgerRecord> records,
    required double monthlyBudget,
    required AiSuggestionMode mode,
    required DateTime now,
    required AiInsightSnapshot Function() builder,
  }) {
    final key = _cacheKey(
      ledgerId: ledgerId,
      records: records,
      monthlyBudget: monthlyBudget,
      mode: mode,
      now: now,
    );
    if (_lastKey == key && _lastSnapshot != null) {
      return _lastSnapshot!;
    }
    final snapshot = builder();
    _lastKey = key;
    _lastSnapshot = snapshot;
    return snapshot;
  }

  String _cacheKey({
    required String ledgerId,
    required List<LedgerRecord> records,
    required double monthlyBudget,
    required AiSuggestionMode mode,
    required DateTime now,
  }) {
    var sumExpense = 0.0;
    var sumIncome = 0.0;
    var sumMillis = 0;
    for (final record in records) {
      if (record.isIncome) {
        sumIncome += record.amount;
      } else {
        sumExpense += record.amount;
      }
      sumMillis += record.createdAt.millisecondsSinceEpoch;
    }
    final roundedBudget = monthlyBudget.toStringAsFixed(2);
    final signature =
        '${sumExpense.toStringAsFixed(2)}|'
        '${sumIncome.toStringAsFixed(2)}|${records.length}|$sumMillis';
    final dayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'v$_cacheSchemaVersion|$ledgerId|$dayKey|$roundedBudget|${mode.name}|$signature';
  }
}
