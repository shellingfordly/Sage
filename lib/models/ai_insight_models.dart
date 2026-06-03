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
  });

  final AiSuggestionMode mode;
  final double totalSuggested;
  final List<AiCategoryBudgetSuggestion> byCategory;
  final String summary;
}

class AiInsightSnapshot {
  const AiInsightSnapshot({
    required this.overview,
    required this.budgetRisk,
    required this.anomalies,
    required this.budgetSuggestion,
    required this.generatedAt,
  });

  final AiOverviewInsight overview;
  final AiBudgetRiskInsight budgetRisk;
  final AiAnomalyInsight anomalies;
  final AiBudgetSuggestionInsight budgetSuggestion;
  final DateTime generatedAt;
}

class AiQuestionOption {
  const AiQuestionOption({required this.id, required this.label});

  final String id;
  final String label;
}

class AiInsightAnswer {
  const AiInsightAnswer({
    required this.questionId,
    required this.title,
    required this.summary,
    required this.suggestions,
    this.relatedMetrics = const <String, String>{},
  });

  final String questionId;
  final String title;
  final String summary;
  final List<String> suggestions;
  final Map<String, String> relatedMetrics;
}
