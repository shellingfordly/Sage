class CategoryBudgetFormService {
  const CategoryBudgetFormService();

  Map<String, double> parseBudgets(Map<String, String> inputs) {
    final result = <String, double>{};
    for (final entry in inputs.entries) {
      final category = entry.key.trim();
      if (category.isEmpty) {
        continue;
      }
      final amount = double.tryParse(entry.value.trim());
      if (amount == null || amount <= 0) {
        continue;
      }
      result[category] = amount;
    }
    return result;
  }

  double sumBudgets(Map<String, double> budgets) {
    return budgets.values.fold<double>(0, (sum, amount) => sum + amount);
  }

  Map<String, double> createDraftFromSpending(
    Map<String, double> spendingByCategory,
  ) {
    final result = <String, double>{};
    for (final entry in spendingByCategory.entries) {
      final category = entry.key.trim();
      final amount = entry.value;
      if (category.isEmpty || amount <= 0) {
        continue;
      }
      result[category] = amount;
    }
    return result;
  }

  Map<String, double> createDraftFromPreviousBudgets(
    Map<String, double> previousBudgets,
  ) {
    final result = <String, double>{};
    for (final entry in previousBudgets.entries) {
      final category = entry.key.trim();
      final amount = entry.value;
      if (category.isEmpty || amount <= 0) {
        continue;
      }
      result[category] = amount;
    }
    return result;
  }
}
