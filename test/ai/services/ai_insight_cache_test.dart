import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/ai/models/ai_insight_models.dart';
import 'package:ledger_app/ai/services/ai_insight_cache.dart';
import 'package:ledger_app/models/ledger_record.dart';

void main() {
  group('AiInsightCache', () {
    test('returns cached snapshot when key inputs are unchanged', () {
      final cache = AiInsightCache();
      var buildCount = 0;
      final records = <LedgerRecord>[_expense('餐饮', 100, DateTime(2026, 6, 1))];

      final first = cache.getOrBuild(
        ledgerId: 'ledger-1',
        records: records,
        monthlyBudget: 2000,
        mode: AiSuggestionMode.balanced,
        now: DateTime(2026, 6, 10),
        builder: () {
          buildCount++;
          return _snapshot(DateTime(2026, 6, 10, 10, 0, 0));
        },
      );

      final second = cache.getOrBuild(
        ledgerId: 'ledger-1',
        records: records,
        monthlyBudget: 2000,
        mode: AiSuggestionMode.balanced,
        now: DateTime(2026, 6, 10),
        builder: () {
          buildCount++;
          return _snapshot(DateTime(2026, 6, 10, 10, 0, 1));
        },
      );

      expect(identical(first, second), isTrue);
      expect(buildCount, 1);
    });

    test('rebuilds snapshot when budget changes', () {
      final cache = AiInsightCache();
      var buildCount = 0;
      final records = <LedgerRecord>[_expense('餐饮', 100, DateTime(2026, 6, 1))];

      cache.getOrBuild(
        ledgerId: 'ledger-1',
        records: records,
        monthlyBudget: 2000,
        mode: AiSuggestionMode.balanced,
        now: DateTime(2026, 6, 10),
        builder: () {
          buildCount++;
          return _snapshot(DateTime(2026, 6, 10, 10, 0, 0));
        },
      );

      cache.getOrBuild(
        ledgerId: 'ledger-1',
        records: records,
        monthlyBudget: 2500,
        mode: AiSuggestionMode.balanced,
        now: DateTime(2026, 6, 10),
        builder: () {
          buildCount++;
          return _snapshot(DateTime(2026, 6, 10, 10, 0, 1));
        },
      );

      expect(buildCount, 2);
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

AiInsightSnapshot _snapshot(DateTime generatedAt) {
  return AiInsightSnapshot(
    overview: const AiOverviewInsight(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
      dailyAvgExpense: 0,
      topCategories: <AiCategoryShare>[],
      summary: 'ok',
    ),
    budgetRisk: const AiBudgetRiskInsight(
      hasBudget: false,
      monthlyBudget: 0,
      expense: 0,
      usageRate: 0,
      timeProgress: 0,
      forecastOverrun: 0,
      riskLevel: AiRiskLevel.attention,
      summary: 'ok',
      suggestion: 'ok',
    ),
    anomalies: const AiAnomalyInsight(items: <AiAnomalyItem>[], summary: 'ok'),
    budgetSuggestion: const AiBudgetSuggestionInsight(
      mode: AiSuggestionMode.balanced,
      totalSuggested: 0,
      byCategory: <AiCategoryBudgetSuggestion>[],
      summary: 'ok',
    ),
    generatedAt: generatedAt,
  );
}
