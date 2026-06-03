import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ai_insight_models.dart';
import 'package:ledger_app/services/ai/ai_home_alert_service.dart';

void main() {
  group('AiHomeAlertService', () {
    const service = AiHomeAlertService();

    test('shows alert when budget risk is warning', () {
      final alert = service.evaluate(_snapshot(riskLevel: AiRiskLevel.warning));
      expect(alert.show, isTrue);
      expect(alert.hasBudgetWarning, isTrue);
      expect(alert.hasAnomaly, isFalse);
      expect(alert.badgeCount, 1);
    });

    test('shows alert when anomaly exists', () {
      final alert = service.evaluate(
        _snapshot(
          riskLevel: AiRiskLevel.safe,
          anomalyItems: const <AiAnomalyItem>[
            AiAnomalyItem(
              title: '异常',
              category: '餐饮',
              amount: 100,
              reason: '波动',
              severity: AiSeverity.medium,
            ),
          ],
        ),
      );
      expect(alert.show, isTrue);
      expect(alert.hasBudgetWarning, isFalse);
      expect(alert.hasAnomaly, isTrue);
      expect(alert.badgeCount, 1);
    });

    test('does not show alert without warning and anomaly', () {
      final alert = service.evaluate(_snapshot(riskLevel: AiRiskLevel.safe));
      expect(alert.show, isFalse);
      expect(alert.badgeCount, 0);
    });

    test('badge count sums anomaly count and budget warning', () {
      final alert = service.evaluate(
        _snapshot(
          riskLevel: AiRiskLevel.warning,
          anomalyItems: const <AiAnomalyItem>[
            AiAnomalyItem(
              title: '异常1',
              category: '餐饮',
              amount: 100,
              reason: '波动',
              severity: AiSeverity.medium,
            ),
            AiAnomalyItem(
              title: '异常2',
              category: '交通',
              amount: 200,
              reason: '波动',
              severity: AiSeverity.high,
            ),
          ],
        ),
      );

      expect(alert.badgeCount, 3);
    });
  });
}

AiInsightSnapshot _snapshot({
  required AiRiskLevel riskLevel,
  List<AiAnomalyItem> anomalyItems = const <AiAnomalyItem>[],
}) {
  return AiInsightSnapshot(
    overview: const AiOverviewInsight(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
      dailyAvgExpense: 0,
      topCategories: <AiCategoryShare>[],
      summary: '',
    ),
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
    budgetSuggestion: const AiBudgetSuggestionInsight(
      mode: AiSuggestionMode.balanced,
      totalSuggested: 0,
      byCategory: <AiCategoryBudgetSuggestion>[],
      summary: '',
    ),
    generatedAt: DateTime(2026, 6, 1),
  );
}
