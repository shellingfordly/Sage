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

  int get badgeCount {
    var count = anomalyCount;
    if (hasBudgetWarning) {
      count += 1;
    }
    return count;
  }
}

class AiHomeAlertService {
  const AiHomeAlertService();

  int visibleBadgeCount({
    required AiHomeAlert alert,
    required bool budgetAcknowledged,
    required bool anomalyAcknowledged,
  }) {
    var count = alert.badgeCount;
    if (budgetAcknowledged && alert.hasBudgetWarning) {
      count -= 1;
    }
    if (anomalyAcknowledged && alert.hasAnomaly) {
      count -= alert.anomalyCount;
    }
    if (count < 0) {
      return 0;
    }
    return count;
  }

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
