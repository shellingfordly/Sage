import 'package:flutter/foundation.dart';

import '../models/ai_insight_models.dart';

class AiAlertAckStore extends ChangeNotifier {
  final Map<String, String> _budgetAckSignatures = <String, String>{};
  final Map<String, String> _anomalyAckSignatures = <String, String>{};

  void acknowledgeBudget({
    required String ledgerId,
    required AiInsightSnapshot snapshot,
  }) {
    _budgetAckSignatures[ledgerId] = _budgetSignature(snapshot);
    notifyListeners();
  }

  void acknowledgeAnomaly({
    required String ledgerId,
    required AiInsightSnapshot snapshot,
  }) {
    _anomalyAckSignatures[ledgerId] = _anomalySignature(snapshot);
    notifyListeners();
  }

  bool isBudgetAcknowledged({
    required String ledgerId,
    required AiInsightSnapshot snapshot,
  }) {
    return _budgetAckSignatures[ledgerId] == _budgetSignature(snapshot);
  }

  bool isAnomalyAcknowledged({
    required String ledgerId,
    required AiInsightSnapshot snapshot,
  }) {
    return _anomalyAckSignatures[ledgerId] == _anomalySignature(snapshot);
  }

  String _budgetSignature(AiInsightSnapshot snapshot) {
    final risk = snapshot.budgetRisk;
    return '${risk.riskLevel.name}:${risk.monthlyBudget}:${risk.expense}';
  }

  String _anomalySignature(AiInsightSnapshot snapshot) {
    final items = snapshot.anomalies.items;
    if (items.isEmpty) {
      return 'none';
    }
    return items
        .map((item) => '${item.title}:${item.category}:${item.amount}')
        .join('|');
  }
}

final aiAlertAckStore = AiAlertAckStore();
