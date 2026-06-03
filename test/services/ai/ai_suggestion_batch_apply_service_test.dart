import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ai_insight_models.dart';
import 'package:ledger_app/services/ai/ai_suggestion_batch_apply_service.dart';

void main() {
  group('AiSuggestionBatchApplyService', () {
    const service = AiSuggestionBatchApplyService();

    test('returns false when category suggestions are empty', () async {
      DateTime? appliedMonth;
      double? appliedAmount;
      Map<String, double>? appliedCategoryBudgets;
      final applied = await service.applyCategorySuggestionsToNextMonth(
        suggestions: const <AiCategoryBudgetSuggestion>[],
        now: DateTime(2026, 6, 1),
        onApply:
            ({
              required month,
              required amount,
              required categoryBudgets,
            }) async {
              appliedMonth = month;
              appliedAmount = amount;
              appliedCategoryBudgets = categoryBudgets;
            },
      );

      expect(applied, isFalse);
      expect(appliedMonth, isNull);
      expect(appliedAmount, isNull);
      expect(appliedCategoryBudgets, isNull);
    });

    test('applies sum of category budgets to next month', () async {
      DateTime? appliedMonth;
      double? appliedAmount;
      Map<String, double>? appliedCategoryBudgets;
      final applied = await service.applyCategorySuggestionsToNextMonth(
        suggestions: const <AiCategoryBudgetSuggestion>[
          AiCategoryBudgetSuggestion(
            category: '餐饮',
            currentMonthSpend: 1200,
            suggestedBudget: 1000,
            delta: -200,
          ),
          AiCategoryBudgetSuggestion(
            category: '交通',
            currentMonthSpend: 400,
            suggestedBudget: 300,
            delta: -100,
          ),
        ],
        now: DateTime(2026, 12, 10),
        onApply:
            ({
              required month,
              required amount,
              required categoryBudgets,
            }) async {
              appliedMonth = month;
              appliedAmount = amount;
              appliedCategoryBudgets = categoryBudgets;
            },
      );

      expect(applied, isTrue);
      expect(appliedMonth, DateTime(2027, 1, 1));
      expect(appliedAmount, 1300);
      expect(appliedCategoryBudgets, <String, double>{'餐饮': 1000, '交通': 300});
    });
  });
}
