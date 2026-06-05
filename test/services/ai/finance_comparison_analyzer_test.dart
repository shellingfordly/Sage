import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ai_insight_scope.dart';
import 'package:ledger_app/models/ledger_record.dart';
import 'package:ledger_app/services/ai/finance_comparison_analyzer.dart';

void main() {
  group('FinanceComparisonAnalyzer', () {
    const analyzer = FinanceComparisonAnalyzer();

    test('compares current scope against previous equal-length period', () {
      final scope = AiInsightScope(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30, 23, 59, 59),
        label: '2026/06/01 - 2026/06/30',
      );
      final result = analyzer.analyze(
        records: <LedgerRecord>[
          _expense('餐饮', 300, DateTime(2026, 6, 5)),
          _expense('餐饮', 200, DateTime(2026, 5, 10)),
        ],
        scope: scope,
      );

      expect(result.currentExpense, 300);
      expect(result.previousExpense, 200);
      expect(result.changeAmount, 100);
      expect(result.categoryChanges.first.category, '餐饮');
    });

    test('excludes transfer records from comparison totals', () {
      final scope = AiInsightScope(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30, 23, 59, 59),
        label: '2026/06/01 - 2026/06/30',
      );
      final result = analyzer.analyze(
        records: <LedgerRecord>[
          _expense('转账', 60000, DateTime(2026, 6, 5), title: '定存开户'),
          _expense('餐饮', 120, DateTime(2026, 6, 6)),
        ],
        scope: scope,
      );

      expect(result.currentExpense, 120);
    });
  });
}

LedgerRecord _expense(
  String category,
  double amount,
  DateTime createdAt, {
  String title = '消费',
}) {
  return LedgerRecord(
    id: '$category-$amount',
    title: title,
    amount: amount,
    type: LedgerRecordType.expense,
    category: category,
    createdAt: createdAt,
  );
}
