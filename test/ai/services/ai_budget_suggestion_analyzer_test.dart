import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/ai/models/ai_insight_models.dart';
import 'package:ledger_app/ai/services/ai_budget_suggestion_analyzer.dart';
import 'package:ledger_app/models/ledger_record.dart';

void main() {
  group('AiBudgetSuggestionAnalyzer', () {
    const analyzer = AiBudgetSuggestionAnalyzer();

    test('returns empty suggestion when recent records are unavailable', () {
      final result = analyzer.analyze(
        records: <LedgerRecord>[
          _expense('餐饮', 200, DateTime(2026, 2, 1)),
        ],
        mode: AiSuggestionMode.balanced,
        now: DateTime(2026, 6, 10),
      );

      expect(result.byCategory, isEmpty);
      expect(result.totalSuggested, 0);
      expect(result.summary, contains('数据不足'));
    });

    test('generates positive category suggestions for recent three months', () {
      final result = analyzer.analyze(
        records: <LedgerRecord>[
          _expense('餐饮', 900, DateTime(2026, 6, 3)),
          _expense('餐饮', 600, DateTime(2026, 5, 4)),
          _expense('餐饮', 500, DateTime(2026, 4, 6)),
          _expense('交通', 300, DateTime(2026, 6, 8)),
          _expense('交通', 200, DateTime(2026, 5, 7)),
        ],
        mode: AiSuggestionMode.balanced,
        now: DateTime(2026, 6, 20),
      );

      expect(result.byCategory, isNotEmpty);
      expect(result.totalSuggested, greaterThan(0));
      expect(result.byCategory.first.category, '餐饮');
      expect(result.byCategory.first.suggestedBudget, greaterThan(0));
    });
  });
}

LedgerRecord _expense(String category, double amount, DateTime createdAt) {
  return LedgerRecord(
    id: '$category-${createdAt.microsecondsSinceEpoch}',
    title: category,
    amount: amount,
    type: LedgerRecordType.expense,
    category: category,
    createdAt: createdAt,
  );
}
