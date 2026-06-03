import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/services/ai/ai_budget_apply_service.dart';

void main() {
  group('AiBudgetApplyService', () {
    test('returns false when suggested budget is invalid', () async {
      final service = AiBudgetApplyService();
      DateTime? appliedMonth;
      double? appliedAmount;
      final applied = await service.applySuggestionToNextMonth(
        suggestedBudget: 0,
        now: DateTime(2026, 6, 1),
        onApply: ({required month, required amount}) async {
          appliedMonth = month;
          appliedAmount = amount;
        },
      );

      expect(applied, isFalse);
      expect(appliedMonth, isNull);
      expect(appliedAmount, isNull);
    });

    test('applies suggested budget to next month start date', () async {
      final service = AiBudgetApplyService();
      DateTime? appliedMonth;
      double? appliedAmount;

      final applied = await service.applySuggestionToNextMonth(
        suggestedBudget: 3200,
        now: DateTime(2026, 12, 20),
        onApply: ({required month, required amount}) async {
          appliedMonth = month;
          appliedAmount = amount;
        },
      );

      expect(applied, isTrue);
      expect(appliedMonth, DateTime(2027, 1, 1));
      expect(appliedAmount, 3200);
    });
  });
}
