import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ai_insight_models.dart';
import 'package:ledger_app/services/ai/ai_home_alert_service.dart';

import 'ai_insight_test_helpers.dart';

void main() {
  group('AiHomeAlertService', () {
    const service = AiHomeAlertService();

    test('shows alert when budget risk is warning', () {
      final alert = service.evaluate(
        testAlertInsightSnapshot(riskLevel: AiRiskLevel.warning),
      );
      expect(alert.show, isTrue);
      expect(alert.hasBudgetWarning, isTrue);
      expect(alert.hasAnomaly, isFalse);
      expect(alert.anomalyCount, 0);
    });

    test('shows alert when anomaly exists', () {
      final alert = service.evaluate(
        testAlertInsightSnapshot(
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
      expect(alert.anomalyCount, 1);
    });

    test('does not show alert without warning and anomaly', () {
      final alert = service.evaluate(
        testAlertInsightSnapshot(riskLevel: AiRiskLevel.safe),
      );
      expect(alert.show, isFalse);
      expect(alert.anomalyCount, 0);
    });

    test('anomaly count reflects item count', () {
      final alert = service.evaluate(
        testAlertInsightSnapshot(
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

      expect(alert.show, isTrue);
      expect(alert.hasBudgetWarning, isTrue);
      expect(alert.hasAnomaly, isTrue);
      expect(alert.anomalyCount, 2);
    });
  });
}
