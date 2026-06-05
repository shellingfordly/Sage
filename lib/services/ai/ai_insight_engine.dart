import '../../models/ai_insight_scope.dart';
import '../../models/ledger_record.dart';
import '../../models/ai_insight_models.dart';
import 'ai_anomaly_analyzer.dart';
import 'ai_budget_risk_analyzer.dart';
import 'ai_budget_suggestion_analyzer.dart';
import 'ai_overview_analyzer.dart';
import 'finance_comparison_analyzer.dart';
import 'finance_headline_analyzer.dart';
import 'finance_monthly_volatility_analyzer.dart';

class AiInsightEngine {
  const AiInsightEngine({
    this.overviewAnalyzer = const AiOverviewAnalyzer(),
    this.comparisonAnalyzer = const FinanceComparisonAnalyzer(),
    this.monthlyVolatilityAnalyzer = const FinanceMonthlyVolatilityAnalyzer(),
    this.headlineAnalyzer = const FinanceHeadlineAnalyzer(),
    this.budgetRiskAnalyzer = const AiBudgetRiskAnalyzer(),
    this.anomalyAnalyzer = const AiAnomalyAnalyzer(),
    this.budgetSuggestionAnalyzer = const AiBudgetSuggestionAnalyzer(),
  });

  final AiOverviewAnalyzer overviewAnalyzer;
  final FinanceComparisonAnalyzer comparisonAnalyzer;
  final FinanceMonthlyVolatilityAnalyzer monthlyVolatilityAnalyzer;
  final FinanceHeadlineAnalyzer headlineAnalyzer;
  final AiBudgetRiskAnalyzer budgetRiskAnalyzer;
  final AiAnomalyAnalyzer anomalyAnalyzer;
  final AiBudgetSuggestionAnalyzer budgetSuggestionAnalyzer;

  AiInsightSnapshot buildSnapshot({
    required List<LedgerRecord> records,
    required AiInsightScope scope,
    required double budget,
    AiSuggestionMode mode = AiSuggestionMode.balanced,
    DateTime? now,
  }) {
    final reference = scope.referenceDate(now ?? DateTime.now());
    final overview = overviewAnalyzer.analyze(
      records: records,
      scope: scope,
      now: reference,
    );
    final comparison = comparisonAnalyzer.analyze(
      records: records,
      scope: scope,
    );
    final monthlyVolatility = monthlyVolatilityAnalyzer.analyze(
      records: records,
      scope: scope,
    );
    final budgetRisk = budgetRiskAnalyzer.analyze(
      records: records,
      budget: budget,
      scope: scope,
      now: reference,
    );
    final anomalies = anomalyAnalyzer.analyze(
      records: records,
      scope: scope,
      now: reference,
    );
    final budgetSuggestion = budgetSuggestionAnalyzer.analyze(
      records: records,
      mode: mode,
      scope: scope,
      now: reference,
    );
    final headlines = headlineAnalyzer.analyze(
      scope: scope,
      comparison: comparison,
      monthlyVolatility: monthlyVolatility,
      overview: overview,
      budgetRisk: budgetRisk,
      anomalies: anomalies,
    );

    return AiInsightSnapshot(
      overview: overview,
      budgetRisk: budgetRisk,
      anomalies: anomalies,
      budgetSuggestion: budgetSuggestion,
      comparison: comparison,
      monthlyVolatility: monthlyVolatility,
      headlines: headlines,
      generatedAt: reference,
    );
  }
}
