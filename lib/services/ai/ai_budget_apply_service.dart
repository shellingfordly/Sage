class AiBudgetApplyService {
  const AiBudgetApplyService();

  Future<bool> applySuggestionToNextMonth({
    required double suggestedBudget,
    required Future<void> Function({
      required DateTime month,
      required double amount,
    })
    onApply,
    DateTime? now,
  }) async {
    if (suggestedBudget <= 0) {
      return false;
    }
    final current = now ?? DateTime.now();
    final targetMonth = DateTime(current.year, current.month + 1, 1);
    await onApply(month: targetMonth, amount: suggestedBudget);
    return true;
  }
}
