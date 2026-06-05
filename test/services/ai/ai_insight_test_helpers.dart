import 'package:ledger_app/models/ai_insight_models.dart';

FinanceComparisonInsight testComparison({
  double currentExpense = 0,
  double previousExpense = 0,
}) {
  final changeAmount = currentExpense - previousExpense;
  final changePercent = previousExpense <= 0
      ? 0.0
      : changeAmount / previousExpense;
  return FinanceComparisonInsight(
    currentExpense: currentExpense,
    previousExpense: previousExpense,
    changeAmount: changeAmount,
    changePercent: changePercent,
    previousPeriodLabel: '上一时段',
    categoryChanges: const <FinanceCategoryChange>[],
    summary: 'summary',
  );
}

const FinanceMonthlyVolatilityInsight _emptyMonthlyVolatility =
    FinanceMonthlyVolatilityInsight(
  monthlyTotals: <FinanceMonthExpense>[],
  peakMonth: null,
  periodAverage: 0,
  summary: '',
);

FinanceMonthlyVolatilityInsight testMonthlyVolatility({
  FinanceMonthExpense? peakMonth,
  List<FinanceMonthExpense>? monthlyTotals,
  double periodAverage = 1000,
  String summary = 'monthly summary',
}) {
  return FinanceMonthlyVolatilityInsight(
    monthlyTotals: monthlyTotals ??
        (peakMonth == null
            ? const <FinanceMonthExpense>[]
            : <FinanceMonthExpense>[peakMonth]),
    peakMonth: peakMonth,
    periodAverage: periodAverage,
    summary: summary,
  );
}

AiInsightSnapshot testInsightSnapshot({
  DateTime? generatedAt,
  AiBudgetRiskInsight? budgetRisk,
  AiAnomalyInsight? anomalies,
  FinanceComparisonInsight? comparison,
  FinanceMonthlyVolatilityInsight? monthlyVolatility,
  List<FinanceHeadline>? headlines,
}) {
  return AiInsightSnapshot(
    overview: const AiOverviewInsight(
      totalIncome: 5000,
      totalExpense: 1200,
      balance: 3800,
      dailyAvgExpense: 60,
      topCategories: <AiCategoryShare>[
        AiCategoryShare(category: '餐饮', amount: 600, percent: 0.5),
      ],
      summary: 'summary',
    ),
    budgetRisk: budgetRisk ??
        const AiBudgetRiskInsight(
          hasBudget: false,
          monthlyBudget: 0,
          expense: 1200,
          usageRate: 0,
          timeProgress: 0.5,
          forecastOverrun: 0,
          riskLevel: AiRiskLevel.attention,
          summary: 'risk summary',
          suggestion: 'risk suggestion',
        ),
    anomalies: anomalies ??
        const AiAnomalyInsight(
          items: <AiAnomalyItem>[],
          summary: 'anomaly summary',
        ),
    budgetSuggestion: const AiBudgetSuggestionInsight(
      mode: AiSuggestionMode.balanced,
      totalSuggested: 3000,
      byCategory: <AiCategoryBudgetSuggestion>[
        AiCategoryBudgetSuggestion(
          category: '餐饮',
          currentMonthSpend: 1000,
          suggestedBudget: 900,
          delta: -100,
        ),
      ],
      summary: 'suggestion summary',
    ),
    comparison: comparison ?? testComparison(currentExpense: 1200),
    monthlyVolatility: monthlyVolatility ?? _emptyMonthlyVolatility,
    headlines: headlines ??
        const <FinanceHeadline>[
          FinanceHeadline(
            kind: FinanceHeadlineKind.comparison,
            text: '消费支出较上一时段增加 10%。',
          ),
        ],
    generatedAt: generatedAt ?? DateTime(2026, 6, 1),
  );
}

AiInsightSnapshot testAlertInsightSnapshot({
  required AiRiskLevel riskLevel,
  List<AiAnomalyItem> anomalyItems = const <AiAnomalyItem>[],
}) {
  return testInsightSnapshot(
    budgetRisk: AiBudgetRiskInsight(
      hasBudget: true,
      monthlyBudget: 2000,
      expense: 1000,
      usageRate: 0.5,
      timeProgress: 0.5,
      forecastOverrun: 0,
      riskLevel: riskLevel,
      summary: '',
      suggestion: '',
    ),
    anomalies: AiAnomalyInsight(items: anomalyItems, summary: ''),
  );
}
