import '../../models/ledger_record.dart';
import '../models/ai_insight_models.dart';

class AiBudgetSuggestionAnalyzer {
  const AiBudgetSuggestionAnalyzer();

  AiBudgetSuggestionInsight analyze({
    required List<LedgerRecord> records,
    required AiSuggestionMode mode,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final monthStart = DateTime(current.year, current.month, 1);
    final recent = records.where((record) {
      if (record.isIncome) {
        return false;
      }
      final monthsDiff = _monthDiff(current, record.createdAt);
      return monthsDiff >= 0 && monthsDiff <= 2;
    }).toList();
    if (recent.isEmpty) {
      return AiBudgetSuggestionInsight(
        mode: mode,
        totalSuggested: 0,
        byCategory: const <AiCategoryBudgetSuggestion>[],
        summary: '近期支出数据不足，暂无法生成下月预算建议。',
      );
    }

    final weightedByCategory = <String, double>{};
    for (final record in recent) {
      final diff = _monthDiff(current, record.createdAt);
      final weight = switch (diff) {
        0 => 1.0,
        1 => 0.75,
        _ => 0.55,
      };
      weightedByCategory.update(
        record.category,
        (value) => value + record.amount * weight,
        ifAbsent: () => record.amount * weight,
      );
    }

    final currentMonthTotals = <String, double>{};
    for (final record in recent) {
      if (record.createdAt.year != monthStart.year ||
          record.createdAt.month != monthStart.month) {
        continue;
      }
      currentMonthTotals.update(
        record.category,
        (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
    }

    final modeFactor = switch (mode) {
      AiSuggestionMode.conservative => 0.9,
      AiSuggestionMode.balanced => 1.0,
      AiSuggestionMode.aggressive => 1.1,
    };

    final suggestions = weightedByCategory.entries.map((entry) {
      final base = entry.value / 2.3;
      final suggested = _roundToTen(
        (base * modeFactor).clamp(0, 999999).toDouble(),
      );
      final currentSpend = currentMonthTotals[entry.key] ?? 0;
      return AiCategoryBudgetSuggestion(
        category: entry.key,
        currentMonthSpend: currentSpend,
        suggestedBudget: suggested,
        delta: suggested - currentSpend,
      );
    }).toList()..sort((a, b) => b.suggestedBudget.compareTo(a.suggestedBudget));

    final top = suggestions.take(5).toList();
    final totalSuggested = top.fold<double>(
      0,
      (sum, item) => sum + item.suggestedBudget,
    );
    final summary = top.isEmpty
        ? '暂无可用建议。'
        : '已按近 3 个月趋势生成${_modeText(mode)}预算建议，可先采用后微调。';

    return AiBudgetSuggestionInsight(
      mode: mode,
      totalSuggested: totalSuggested,
      byCategory: top,
      summary: summary,
    );
  }

  int _monthDiff(DateTime current, DateTime target) {
    return (current.year - target.year) * 12 + current.month - target.month;
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
