import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ai_insight_scope.dart';
import 'package:ledger_app/models/ledger_record.dart';
import 'package:ledger_app/services/ai/finance_monthly_volatility_analyzer.dart';

void main() {
  group('FinanceMonthlyVolatilityAnalyzer', () {
    const analyzer = FinanceMonthlyVolatilityAnalyzer();

    test('returns empty insight for single month scope', () {
      final scope = AiInsightScope.fromMonth(DateTime(2026, 6, 1));
      final result = analyzer.analyze(
        records: <LedgerRecord>[
          _expense('餐饮', 100, DateTime(2026, 6, 3)),
        ],
        scope: scope,
      );

      expect(result.hasMultiMonthData, isFalse);
      expect(result.summary, isEmpty);
    });

    test('finds month with largest deviation from period average', () {
      final scope = AiInsightScope(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 6, 30, 23, 59, 59),
        label: '2026/01/01 - 2026/06/30',
      );
      final result = analyzer.analyze(
        records: <LedgerRecord>[
          _expense('餐饮', 500, DateTime(2026, 1, 5)),
          _expense('餐饮', 600, DateTime(2026, 2, 5)),
          _expense('餐饮', 550, DateTime(2026, 3, 5)),
          _expense('餐饮', 520, DateTime(2026, 4, 5)),
          _expense('餐饮', 480, DateTime(2026, 5, 5)),
          _expense('餐饮', 3000, DateTime(2026, 6, 5)),
        ],
        scope: scope,
      );

      expect(result.hasMultiMonthData, isTrue);
      expect(result.peakMonth?.month.month, 6);
      expect(result.peakMonth?.expense, 3000);
      expect(result.summary, contains('6月'));
    });
  });
}

LedgerRecord _expense(String category, double amount, DateTime createdAt) {
  return LedgerRecord(
    id: '$category-$amount',
    title: category,
    amount: amount,
    type: LedgerRecordType.expense,
    category: category,
    createdAt: createdAt,
  );
}
