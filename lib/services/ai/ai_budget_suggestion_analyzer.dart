import '../../models/ai_insight_scope.dart';
import '../../models/ledger_record.dart';
import '../../models/ai_insight_models.dart';

import 'consumption_record_filter.dart';

class AiBudgetSuggestionAnalyzer {
  const AiBudgetSuggestionAnalyzer();

  AiBudgetSuggestionInsight analyze({
    required List<LedgerRecord> records,
    required AiSuggestionMode mode,
    required AiInsightScope scope,
    DateTime? now,
  }) {
    if (scope.isSingleMonth) {
      return _analyzeForNextMonth(
        records: records,
        mode: mode,
        scope: scope,
        now: now,
      );
    }
    return _analyzePeriodReference(
      records: records,
      scope: scope,
    );
  }

  AiBudgetSuggestionInsight _analyzeForNextMonth({
    required List<LedgerRecord> records,
    required AiSuggestionMode mode,
    required AiInsightScope scope,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final anchorMonth = scope.suggestionAnchorMonth(reference);
    final recentMonths = <DateTime>[
      for (var i = 0; i < 3; i++)
        DateTime(anchorMonth.year, anchorMonth.month - i, 1),
    ];

    final weightedByCategory = <String, double>{};
    var hasRecentData = false;
    for (var i = 0; i < recentMonths.length; i++) {
      final month = recentMonths[i];
      final weight = switch (i) {
        0 => 1.0,
        1 => 0.75,
        _ => 0.55,
      };
      final monthExpenses = records.where(
        (record) =>
            isConsumptionExpense(record) &&
            record.createdAt.year == month.year &&
            record.createdAt.month == month.month,
      );
      for (final record in monthExpenses) {
        hasRecentData = true;
        weightedByCategory.update(
          record.category,
          (value) => value + record.amount * weight,
          ifAbsent: () => record.amount * weight,
        );
      }
    }

    if (!hasRecentData || weightedByCategory.isEmpty) {
      return AiBudgetSuggestionInsight(
        mode: mode,
        totalSuggested: 0,
        byCategory: const <AiCategoryBudgetSuggestion>[],
        summary: '近期支出数据不足，暂无法生成下月预算建议。',
        actionable: true,
      );
    }

    final referenceMonthTotals = _categoryTotalsForMonth(records, anchorMonth);
    final modeFactor = _modeFactor(mode);
    final suggestions = _buildNextMonthSuggestions(
      weightedByCategory: weightedByCategory,
      referenceMonthTotals: referenceMonthTotals,
      modeFactor: modeFactor,
    );

    final top = suggestions.take(5).toList();
    final totalSuggested = top.fold<double>(
      0,
      (sum, item) => sum + item.suggestedBudget,
    );

    return AiBudgetSuggestionInsight(
      mode: mode,
      totalSuggested: totalSuggested,
      byCategory: top,
      summary:
          '已按近 3 个月趋势生成${_modeText(mode)}预算建议，可先采用后微调。',
      actionable: true,
    );
  }

  AiBudgetSuggestionInsight _analyzePeriodReference({
    required List<LedgerRecord> records,
    required AiInsightScope scope,
  }) {
    final scopeRecords = filterRecordsInScope(records, scope);
    final expenseRecords = consumptionExpenses(scopeRecords);
    if (expenseRecords.isEmpty) {
      return const AiBudgetSuggestionInsight(
        mode: AiSuggestionMode.balanced,
        totalSuggested: 0,
        byCategory: <AiCategoryBudgetSuggestion>[],
        summary: '所选时段暂无支出记录，暂无法统计分类月均支出。',
        actionable: false,
      );
    }

    final monthCount = scope.monthSpanCount().clamp(1, 999);
    final categoryTotals = <String, double>{};
    for (final record in expenseRecords) {
      categoryTotals.update(
        record.category,
        (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
    }

    final suggestions = categoryTotals.entries.map((entry) {
      final monthlyAverage = entry.value / monthCount;
      return AiCategoryBudgetSuggestion(
        category: entry.key,
        currentMonthSpend: entry.value,
        suggestedBudget: _roundToTen(monthlyAverage),
        delta: 0,
      );
    }).toList()..sort((a, b) => b.currentMonthSpend.compareTo(a.currentMonthSpend));

    final top = suggestions.take(5).toList();
    final totalMonthlyAverage = top.fold<double>(
      0,
      (sum, item) => sum + item.suggestedBudget,
    );

    return AiBudgetSuggestionInsight(
      mode: AiSuggestionMode.balanced,
      totalSuggested: totalMonthlyAverage,
      byCategory: top,
      summary:
          '基于${scope.label}（$monthCount 个月）统计，以下为各分类月均支出参考，仅供复盘。',
      actionable: false,
    );
  }

  List<AiCategoryBudgetSuggestion> _buildNextMonthSuggestions({
    required Map<String, double> weightedByCategory,
    required Map<String, double> referenceMonthTotals,
    required double modeFactor,
  }) {
    return weightedByCategory.entries.map((entry) {
      final base = entry.value / 2.3;
      final suggested = _roundToTen(
        (base * modeFactor).clamp(0, 999999).toDouble(),
      );
      final referenceSpend = referenceMonthTotals[entry.key] ?? 0;
      return AiCategoryBudgetSuggestion(
        category: entry.key,
        currentMonthSpend: referenceSpend,
        suggestedBudget: suggested,
        delta: suggested - referenceSpend,
      );
    }).toList()..sort((a, b) => b.suggestedBudget.compareTo(a.suggestedBudget));
  }

  Map<String, double> _categoryTotalsForMonth(
    List<LedgerRecord> records,
    DateTime month,
  ) {
    final totals = <String, double>{};
    for (final record in records) {
      if (!isConsumptionExpense(record)) {
        continue;
      }
      if (record.createdAt.year != month.year ||
          record.createdAt.month != month.month) {
        continue;
      }
      totals.update(
        record.category,
        (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
    }
    return totals;
  }

  double _modeFactor(AiSuggestionMode mode) {
    return switch (mode) {
      AiSuggestionMode.conservative => 0.9,
      AiSuggestionMode.balanced => 1.0,
      AiSuggestionMode.aggressive => 1.1,
    };
  }

  double _roundToTen(double value) {
    if (value <= 0) {
      return 0;
    }
    return (value / 10).roundToDouble() * 10;
  }

  String _modeText(AiSuggestionMode mode) {
    return switch (mode) {
      AiSuggestionMode.conservative => '保守',
      AiSuggestionMode.balanced => '平衡',
      AiSuggestionMode.aggressive => '激进',
    };
  }
}
