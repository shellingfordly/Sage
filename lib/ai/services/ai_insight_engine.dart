import '../../models/ledger_record.dart';
import '../models/ai_insight_models.dart';
import 'ai_anomaly_analyzer.dart';
import 'ai_budget_risk_analyzer.dart';
import 'ai_budget_suggestion_analyzer.dart';
import 'ai_overview_analyzer.dart';

class AiInsightEngine {
  const AiInsightEngine({
    this.overviewAnalyzer = const AiOverviewAnalyzer(),
    this.budgetRiskAnalyzer = const AiBudgetRiskAnalyzer(),
    this.anomalyAnalyzer = const AiAnomalyAnalyzer(),
    this.budgetSuggestionAnalyzer = const AiBudgetSuggestionAnalyzer(),
  });

  final AiOverviewAnalyzer overviewAnalyzer;
  final AiBudgetRiskAnalyzer budgetRiskAnalyzer;
  final AiAnomalyAnalyzer anomalyAnalyzer;
  final AiBudgetSuggestionAnalyzer budgetSuggestionAnalyzer;

  AiInsightSnapshot buildSnapshot({
    required List<LedgerRecord> records,
    required double monthlyBudget,
    AiSuggestionMode mode = AiSuggestionMode.balanced,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    return AiInsightSnapshot(
      overview: overviewAnalyzer.analyze(records: records, now: current),
      budgetRisk: budgetRiskAnalyzer.analyze(
        records: records,
        budget: monthlyBudget,
        now: current,
      ),
      anomalies: anomalyAnalyzer.analyze(records: records, now: current),
      budgetSuggestion: budgetSuggestionAnalyzer.analyze(
        records: records,
        mode: mode,
        now: current,
      ),
      generatedAt: current,
    );
  }
}
