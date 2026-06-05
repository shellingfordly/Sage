import '../../models/ai_insight_scope.dart';
import '../../models/ledger_record.dart';
import '../../models/ai_insight_models.dart';

import 'consumption_record_filter.dart';

class AiBudgetRiskAnalyzer {
  const AiBudgetRiskAnalyzer();

  AiBudgetRiskInsight analyze({
    required List<LedgerRecord> records,
    required double budget,
    required AiInsightScope scope,
    DateTime? now,
  }) {
    final clock = DateTime.now();
    final reference = now ?? clock;
    final scopeRecords = filterRecordsInScope(records, scope);
    final expenseRecords = consumptionExpenses(scopeRecords);
    final expense = expenseRecords.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final hasBudget = budget > 0;
    if (!hasBudget) {
      return AiBudgetRiskInsight(
        hasBudget: false,
        monthlyBudget: 0,
        expense: 0,
        usageRate: 0,
        timeProgress: 0,
        forecastOverrun: 0,
        riskLevel: AiRiskLevel.attention,
        summary: '当前账本还没有设置预算，先设置预算才能计算超支风险。',
        suggestion: scope.isSingleMonth
            ? '到“我的-预算管理”设置本月预算后，AI 可提供更精准控支建议。'
            : '到“我的-预算管理”为时段内各月设置预算后，AI 可提供更精准控支建议。',
      );
    }

    final isPastRange = scope.isPastRange(clock);
    final totalDays = scope.totalDays();
    final elapsedDays = scope.elapsedDays(reference).clamp(1, totalDays);
    final usageRate = (expense / budget).clamp(0.0, 3.0);
    final timeProgress = isPastRange
        ? 1.0
        : (elapsedDays / totalDays).clamp(0.0, 1.0);
    final forecastOverrun = isPastRange
        ? expense - budget
        : (expense / elapsedDays) * totalDays - budget;
    final offset = usageRate - timeProgress;
    final riskLevel = _riskLevel(
      expense: expense,
      budget: budget,
      offset: offset,
      isPastRange: isPastRange,
    );

    final topCategory = _topCategory(expenseRecords);
    final summary = _summary(
      expense: expense,
      budget: budget,
      forecastOverrun: forecastOverrun,
      riskLevel: riskLevel,
      isPastRange: isPastRange,
      scope: scope,
    );
    final suggestion = _suggestion(
      level: riskLevel,
      topCategory: topCategory,
      forecastOverrun: forecastOverrun,
      isPastRange: isPastRange,
      scope: scope,
    );

    return AiBudgetRiskInsight(
      hasBudget: true,
      monthlyBudget: budget,
      expense: expense,
      usageRate: usageRate,
      timeProgress: timeProgress,
      forecastOverrun: forecastOverrun,
      riskLevel: riskLevel,
      summary: summary,
      suggestion: suggestion,
    );
  }

  AiRiskLevel _riskLevel({
    required double expense,
    required double budget,
    required double offset,
    required bool isPastRange,
  }) {
    if (expense >= budget) {
      return AiRiskLevel.warning;
    }
    if (isPastRange) {
      return offset >= 0.08 ? AiRiskLevel.attention : AiRiskLevel.safe;
    }
    if (offset >= 0.2) {
      return AiRiskLevel.warning;
    }
    if (offset >= 0.08) {
      return AiRiskLevel.attention;
    }
    return AiRiskLevel.safe;
  }

  String? _topCategory(List<LedgerRecord> expenseRecords) {
    if (expenseRecords.isEmpty) {
      return null;
    }
    final totals = <String, double>{};
    for (final record in expenseRecords) {
      totals.update(
        record.category,
        (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String _summary({
    required double expense,
    required double budget,
    required double forecastOverrun,
    required AiRiskLevel riskLevel,
    required bool isPastRange,
    required AiInsightScope scope,
  }) {
    final budgetLabel = scope.periodBudgetLabel();
    if (isPastRange) {
      final overrun = expense - budget;
      if (overrun > 0) {
        return '${scope.label} 最终超出$budgetLabel ¥${overrun.toStringAsFixed(0)}。';
      }
      if (riskLevel == AiRiskLevel.safe) {
        return '${scope.label} 支出 ¥${expense.toStringAsFixed(0)}，$budgetLabel 内，节奏健康。';
      }
      final remaining = budget - expense;
      return '${scope.label} 已支出 ¥${expense.toStringAsFixed(0)}，$budgetLabel 剩余 ¥${remaining.toStringAsFixed(0)}。';
    }
    if (riskLevel == AiRiskLevel.safe) {
      return '当前支出 ¥${expense.toStringAsFixed(0)}，$budgetLabel 使用节奏健康。';
    }
    if (forecastOverrun > 0) {
      return '按当前节奏，时段末预计超出$budgetLabel ¥${forecastOverrun.toStringAsFixed(0)}。';
    }
    final remaining = budget - expense;
    return '当前已支出 ¥${expense.toStringAsFixed(0)}，$budgetLabel 剩余 ¥${remaining.toStringAsFixed(0)}，建议关注后续大额开销。';
  }

  String _suggestion({
    required AiRiskLevel level,
    required String? topCategory,
    required double forecastOverrun,
    required bool isPastRange,
    required AiInsightScope scope,
  }) {
    final categoryTip = topCategory == null
        ? '优先检查最高支出分类'
        : '优先控制“$topCategory”分类';
    if (isPastRange) {
      return switch (level) {
        AiRiskLevel.safe => '该时段预算执行良好，可将经验沿用到下一周期。',
        AiRiskLevel.attention =>
          '$categoryTip，下一周期可为该分类预留更充足预算。',
        AiRiskLevel.warning =>
          '$categoryTip，下一周期建议下调可变支出并设置分类上限。',
      };
    }
    return switch (level) {
      AiRiskLevel.safe => '预算节奏良好，继续保持当前记账与复盘频率。',
      AiRiskLevel.attention => '$categoryTip，建议把日预算下调 10%-15%。',
      AiRiskLevel.warning =>
        '$categoryTip，并在剩余天数内把可变支出压缩约 ¥${forecastOverrun.abs().toStringAsFixed(0)}。',
    };
  }
}
