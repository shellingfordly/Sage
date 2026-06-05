import '../../models/ai_insight_models.dart';

class AiHomeAlert {
  const AiHomeAlert({
    required this.hasBudgetWarning,
    required this.hasAnomaly,
    required this.anomalyCount,
  });

  final bool hasBudgetWarning;
  final bool hasAnomaly;
  final int anomalyCount;

  bool get show => hasBudgetWarning || hasAnomaly;
}

class AiHomeAlertService {
  const AiHomeAlertService();

  AiHomeAlert evaluate(AiInsightSnapshot snapshot) {
    final hasBudgetWarning =
        snapshot.budgetRisk.riskLevel == AiRiskLevel.warning;
    final anomalyCount = snapshot.anomalies.items.length;
    return AiHomeAlert(
      hasBudgetWarning: hasBudgetWarning,
      hasAnomaly: anomalyCount > 0,
      anomalyCount: anomalyCount,
    );
  }
}
