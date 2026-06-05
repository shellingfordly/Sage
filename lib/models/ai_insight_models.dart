enum AiRiskLevel { safe, attention, warning }

enum AiSeverity { low, medium, high }

enum AiSuggestionMode { conservative, balanced, aggressive }

class AiCategoryShare {
  const AiCategoryShare({
    required this.category,
    required this.amount,
    required this.percent,
  });

  final String category;
  final double amount;
  final double percent;
}

class AiOverviewInsight {
  const AiOverviewInsight({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.dailyAvgExpense,
    required this.topCategories,
    required this.summary,
  });

  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double dailyAvgExpense;
  final List<AiCategoryShare> topCategories;
  final String summary;
}

class AiBudgetRiskInsight {
  const AiBudgetRiskInsight({
    required this.hasBudget,
    required this.monthlyBudget,
    required this.expense,
    required this.usageRate,
    required this.timeProgress,
    required this.forecastOverrun,
    required this.riskLevel,
    required this.summary,
    required this.suggestion,
  });

  final bool hasBudget;
  final double monthlyBudget;
  final double expense;
  final double usageRate;
  final double timeProgress;
  final double forecastOverrun;
  final AiRiskLevel riskLevel;
  final String summary;
  final String suggestion;
}

class AiAnomalyItem {
  const AiAnomalyItem({
    required this.title,
    required this.category,
    required this.amount,
    required this.reason,
    required this.severity,
    List<AiAnomalyRecord>? records,
  }) : _records = records;

  final String title;
  final String category;
  final double amount;
  final String reason;
  final AiSeverity severity;
  final List<AiAnomalyRecord>? _records;

  List<AiAnomalyRecord> get records => _records ?? const <AiAnomalyRecord>[];
}

class AiAnomalyRecord {
  const AiAnomalyRecord({
    required this.title,
    required this.category,
    required this.amount,
    required this.createdAt,
  });

  final String title;
  final String category;
  final double amount;
  final DateTime createdAt;
}

class AiAnomalyInsight {
  const AiAnomalyInsight({required this.items, required this.summary});

  final List<AiAnomalyItem> items;
  final String summary;
}

class AiCategoryBudgetSuggestion {
  const AiCategoryBudgetSuggestion({
    required this.category,
    required this.currentMonthSpend,
    required this.suggestedBudget,
    required this.delta,
  });

  final String category;
  final double currentMonthSpend;
  final double suggestedBudget;
  final double delta;
}

class AiBudgetSuggestionInsight {
  const AiBudgetSuggestionInsight({
    required this.mode,
    required this.totalSuggested,
    required this.byCategory,
    required this.summary,
    this.actionable = true,
  });

  final AiSuggestionMode mode;
  final double totalSuggested;
  final List<AiCategoryBudgetSuggestion> byCategory;
  final String summary;
  final bool actionable;
}

enum FinanceHeadlineKind {
  comparison,
  categoryShift,
  structure,
  monthlyPeak,
  budget,
  notable,
  tip,
}

class FinanceHeadline {
  const FinanceHeadline({required this.kind, required this.text});

  final FinanceHeadlineKind kind;
  final String text;
}

class FinanceRecordCluster {
  const FinanceRecordCluster({
    required this.start,
    required this.end,
    required this.count,
    required this.total,
  });

  final DateTime start;
  final DateTime end;
  final int count;
  final double total;
}

class FinanceCategoryChange {
  const FinanceCategoryChange({
    required this.category,
    required this.currentAmount,
    required this.previousAmount,
    required this.changeAmount,
    required this.changePercent,
    this.cluster,
  });

  final String category;
  final double currentAmount;
  final double previousAmount;
  final double changeAmount;
  final double changePercent;
  final FinanceRecordCluster? cluster;
}

class FinanceComparisonInsight {
  const FinanceComparisonInsight({
    required this.currentExpense,
    required this.previousExpense,
    required this.changeAmount,
    required this.changePercent,
    required this.previousPeriodLabel,
    required this.categoryChanges,
    required this.summary,
  });

  final double currentExpense;
  final double previousExpense;
  final double changeAmount;
  final double changePercent;
  final String previousPeriodLabel;
  final List<FinanceCategoryChange> categoryChanges;
  final String summary;
}

class FinanceMonthExpense {
  const FinanceMonthExpense({
    required this.month,
    required this.expense,
    required this.deviationFromAverage,
    required this.deviationPercent,
    this.topCategory,
    this.topCategoryAmount = 0,
  });

  final DateTime month;
  final double expense;
  final double deviationFromAverage;
  final double deviationPercent;
  final String? topCategory;
  final double topCategoryAmount;
}

class FinanceMonthlyVolatilityInsight {
  const FinanceMonthlyVolatilityInsight({
    required this.monthlyTotals,
    required this.peakMonth,
    required this.periodAverage,
    required this.summary,
  });

  final List<FinanceMonthExpense> monthlyTotals;
  final FinanceMonthExpense? peakMonth;
  final double periodAverage;
  final String summary;

  bool get hasMultiMonthData => monthlyTotals.length >= 2 && peakMonth != null;
}

class AiInsightSnapshot {
  const AiInsightSnapshot({
    required this.overview,
    required this.budgetRisk,
    required this.anomalies,
    required this.budgetSuggestion,
    required this.comparison,
    required this.monthlyVolatility,
    required this.headlines,
    required this.generatedAt,
  });

  final AiOverviewInsight overview;
  final AiBudgetRiskInsight budgetRisk;
  final AiAnomalyInsight anomalies;
  final AiBudgetSuggestionInsight budgetSuggestion;
  final FinanceComparisonInsight comparison;
  final FinanceMonthlyVolatilityInsight monthlyVolatility;
  final List<FinanceHeadline> headlines;
  final DateTime generatedAt;
}
