import '../../models/ai_insight_models.dart';

class AiSuggestionBatchApplyService {
  const AiSuggestionBatchApplyService();

  Future<bool> applyCategorySuggestionsToNextMonth({
    required List<AiCategoryBudgetSuggestion> suggestions,
    required Future<void> Function({
      required DateTime month,
      required double amount,
      required Map<String, double> categoryBudgets,
    })
    onApply,
    DateTime? now,
  }) async {
    if (suggestions.isEmpty) {
      return false;
    }
    final categoryBudgets = <String, double>{};
    for (final suggestion in suggestions) {
      final category = suggestion.category.trim();
      final budget = suggestion.suggestedBudget;
      if (category.isEmpty || budget <= 0) {
        continue;
      }
      categoryBudgets.update(
        category,
        (value) => value + budget,
        ifAbsent: () => budget,
      );
    }
    final sum = categoryBudgets.values.fold<double>(
      0,
      (total, budget) => total + budget,
    );
    if (sum <= 0) {
      return false;
    }
    final current = now ?? DateTime.now();
    final month = DateTime(current.year, current.month + 1, 1);
    await onApply(month: month, amount: sum, categoryBudgets: categoryBudgets);
    return true;
  }
}
