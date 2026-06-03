import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ai_insight_models.dart';
import 'package:ledger_app/services/ai/ai_alert_ack_store.dart';
import 'package:ledger_app/services/ai/ai_home_alert_service.dart';

void main() {
  group('AiHomeAlertService visibleBadgeCount', () {
    const service = AiHomeAlertService();

    test('returns full count when nothing acknowledged', () {
      final alert = service.evaluate(
        _snapshot(
          riskLevel: AiRiskLevel.warning,
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

      expect(
        service.visibleBadgeCount(
          alert: alert,
          budgetAcknowledged: false,
          anomalyAcknowledged: false,
        ),
        2,
      );
    });

    test('hides budget warning after budget acknowledged', () {
      final alert = service.evaluate(_snapshot(riskLevel: AiRiskLevel.warning));

      expect(
        service.visibleBadgeCount(
          alert: alert,
          budgetAcknowledged: true,
          anomalyAcknowledged: false,
        ),
        0,
      );
    });

    test('hides anomalies after anomaly acknowledged', () {
      final alert = service.evaluate(
        _snapshot(
          riskLevel: AiRiskLevel.safe,
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

      expect(
        service.visibleBadgeCount(
          alert: alert,
          budgetAcknowledged: false,
          anomalyAcknowledged: true,
        ),
        0,
      );
    });
  });

  group('AiAlertAckStore', () {
    test('acknowledges budget and anomaly independently', () {
      final store = AiAlertAckStore();
      final snapshot = _snapshot(
        riskLevel: AiRiskLevel.warning,
        anomalyItems: const <AiAnomalyItem>[
          AiAnomalyItem(
            title: '异常',
            category: '餐饮',
            amount: 100,
            reason: '波动',
            severity: AiSeverity.medium,
          ),
        ],
      );

      expect(
        store.isBudgetAcknowledged(ledgerId: 'main', snapshot: snapshot),
        isFalse,
      );
      expect(
        store.isAnomalyAcknowledged(ledgerId: 'main', snapshot: snapshot),
        isFalse,
      );

      store.acknowledgeBudget(ledgerId: 'main', snapshot: snapshot);
      expect(
        store.isBudgetAcknowledged(ledgerId: 'main', snapshot: snapshot),
        isTrue,
      );
      expect(
        store.isAnomalyAcknowledged(ledgerId: 'main', snapshot: snapshot),
        isFalse,
      );

      store.acknowledgeAnomaly(ledgerId: 'main', snapshot: snapshot);
      expect(
        store.isAnomalyAcknowledged(ledgerId: 'main', snapshot: snapshot),
        isTrue,
      );
    });

    test('resets acknowledgement when alert content changes', () {
      final store = AiAlertAckStore();
      final original = _snapshot(
        riskLevel: AiRiskLevel.warning,
        anomalyItems: const <AiAnomalyItem>[
          AiAnomalyItem(
            title: '异常',
            category: '餐饮',
            amount: 100,
            reason: '波动',
            severity: AiSeverity.medium,
          ),
        ],
      );
      store.acknowledgeBudget(ledgerId: 'main', snapshot: original);
      store.acknowledgeAnomaly(ledgerId: 'main', snapshot: original);

      final changed = _snapshot(
        riskLevel: AiRiskLevel.safe,
        anomalyItems: const <AiAnomalyItem>[
          AiAnomalyItem(
            title: '新异常',
            category: '交通',
            amount: 300,
            reason: '波动',
            severity: AiSeverity.high,
          ),
        ],
      );

      expect(
        store.isBudgetAcknowledged(ledgerId: 'main', snapshot: changed),
        isFalse,
      );
      expect(
        store.isAnomalyAcknowledged(ledgerId: 'main', snapshot: changed),
        isFalse,
      );
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
