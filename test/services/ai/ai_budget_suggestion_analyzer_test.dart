import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ai_insight_models.dart';
import 'package:ledger_app/models/ai_insight_scope.dart';
import 'package:ledger_app/services/ai/ai_budget_suggestion_analyzer.dart';
import 'package:ledger_app/models/ledger_record.dart';

void main() {
  group('AiBudgetSuggestionAnalyzer', () {
    const analyzer = AiBudgetSuggestionAnalyzer();

    test('returns empty suggestion when recent records are unavailable', () {
      final now = DateTime(2026, 6, 10);
      final result = analyzer.analyze(
        records: <LedgerRecord>[
          _expense('餐饮', 200, DateTime(2026, 2, 1)),
        ],
        mode: AiSuggestionMode.balanced,
        scope: AiInsightScope.fromMonth(now, now: now),
        now: now,
      );

      expect(result.byCategory, isEmpty);
      expect(result.totalSuggested, 0);
      expect(result.summary, contains('数据不足'));
    });

    test('generates positive category suggestions for recent three months', () {
      final now = DateTime(2026, 6, 20);
      final result = analyzer.analyze(
        records: <LedgerRecord>[
          _expense('餐饮', 900, DateTime(2026, 6, 3)),
          _expense('餐饮', 600, DateTime(2026, 5, 4)),
          _expense('餐饮', 500, DateTime(2026, 4, 6)),
          _expense('交通', 300, DateTime(2026, 6, 8)),
          _expense('交通', 200, DateTime(2026, 5, 7)),
        ],
        mode: AiSuggestionMode.balanced,
        scope: AiInsightScope.fromMonth(now, now: now),
        now: now,
      );

      expect(result.byCategory, isNotEmpty);
      expect(result.totalSuggested, greaterThan(0));
      expect(result.byCategory.first.category, '餐饮');
      expect(result.byCategory.first.suggestedBudget, greaterThan(0));
    });

    test('summarizes period monthly averages for long scopes', () {
      final scope = AiInsightScope(
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 12, 31, 23, 59, 59),
        label: '2025/01/01 - 2025/12/31',
      );
      final records = <LedgerRecord>[
        for (var month = 1; month <= 9; month++)
          _expense('餐饮', 10000, DateTime(2025, month, 5)),
        _expense('餐饮', 900, DateTime(2025, 12, 3)),
        _expense('餐饮', 600, DateTime(2025, 11, 4)),
        _expense('餐饮', 500, DateTime(2025, 10, 6)),
      ];

      final result = analyzer.analyze(
        records: records,
        mode: AiSuggestionMode.balanced,
        scope: scope,
        now: DateTime(2025, 12, 20),
      );

      expect(result.actionable, isFalse);
      expect(result.byCategory, isNotEmpty);
      expect(result.byCategory.first.suggestedBudget, closeTo(7670, 20));
      expect(result.summary, contains('月均支出参考'));
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
