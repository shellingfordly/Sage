import '../../models/ai_insight_scope.dart';
import '../../models/ledger_record.dart';
import '../../models/ai_insight_models.dart';

class AiInsightCache {
  static const _cacheSchemaVersion = 5;

  String? _lastKey;
  AiInsightSnapshot? _lastSnapshot;

  AiInsightSnapshot getOrBuild({
    required String ledgerId,
    required AiInsightScope scope,
    required List<LedgerRecord> records,
    required double budget,
    required AiSuggestionMode mode,
    required DateTime reference,
    required AiInsightSnapshot Function() builder,
  }) {
    final key = _cacheKey(
      ledgerId: ledgerId,
      scope: scope,
      records: records,
      budget: budget,
      mode: mode,
      reference: reference,
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
    required AiInsightScope scope,
    required List<LedgerRecord> records,
    required double budget,
    required AiSuggestionMode mode,
    required DateTime reference,
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
    final roundedBudget = budget.toStringAsFixed(2);
    final signature =
        '${sumExpense.toStringAsFixed(2)}|'
        '${sumIncome.toStringAsFixed(2)}|${records.length}|$sumMillis';
    final scopeKey =
        '${scope.start.toIso8601String()}|${scope.end.toIso8601String()}|${scope.label}';
    final dayKey =
        '${reference.year}-${reference.month.toString().padLeft(2, '0')}-${reference.day.toString().padLeft(2, '0')}';
    return 'v$_cacheSchemaVersion|$ledgerId|$scopeKey|$dayKey|$roundedBudget|${mode.name}|$signature';
  }
}
