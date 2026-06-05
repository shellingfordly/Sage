import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ai_insight_models.dart';
import 'package:ledger_app/models/ai_insight_scope.dart';
import 'package:ledger_app/services/ai/ai_budget_risk_analyzer.dart';
import 'package:ledger_app/models/ledger_record.dart';

void main() {
  group('AiBudgetRiskAnalyzer', () {
    const analyzer = AiBudgetRiskAnalyzer();

    test('returns no-budget guidance when budget is missing', () {
      final now = DateTime(2026, 6, 10);
      final result = analyzer.analyze(
        records: const <LedgerRecord>[],
        budget: 0,
        scope: AiInsightScope.fromMonth(now, now: now),
        now: now,
      );

      expect(result.hasBudget, isFalse);
      expect(result.summary, contains('没有设置预算'));
    });

    test('marks warning when pace indicates overrun', () {
      final now = DateTime(2026, 6, 10);
      final result = analyzer.analyze(
        records: <LedgerRecord>[
          _expense('餐饮', 800, DateTime(2026, 6, 5)),
          _expense('餐饮', 700, DateTime(2026, 6, 8)),
        ],
        budget: 2000,
        scope: AiInsightScope.fromMonth(now, now: now),
        now: now,
      );

      expect(result.hasBudget, isTrue);
      expect(result.riskLevel, AiRiskLevel.warning);
      expect(result.forecastOverrun, greaterThan(0));
      expect(result.summary, contains('预计超出'));
    });

    test('marks safe when usage is below time progress', () {
      final now = DateTime(2026, 6, 20);
      final result = analyzer.analyze(
        records: <LedgerRecord>[
          _expense('餐饮', 200, DateTime(2026, 6, 3)),
          _expense('交通', 100, DateTime(2026, 6, 5)),
        ],
        budget: 3000,
        scope: AiInsightScope.fromMonth(now, now: now),
        now: now,
      );

      expect(result.riskLevel, AiRiskLevel.safe);
      expect(result.forecastOverrun, lessThan(0));
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
