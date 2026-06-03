import '../../models/ledger_record.dart';
import '../../models/ai_insight_models.dart';

class AiBudgetRiskAnalyzer {
  const AiBudgetRiskAnalyzer();

  AiBudgetRiskInsight analyze({
    required List<LedgerRecord> records,
    required double budget,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final monthExpenseRecords = records.where((record) {
      return !record.isIncome &&
          record.createdAt.year == current.year &&
          record.createdAt.month == current.month;
    }).toList();
    final expense = monthExpenseRecords.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final hasBudget = budget > 0;
    if (!hasBudget) {
      return const AiBudgetRiskInsight(
        hasBudget: false,
        monthlyBudget: 0,
        expense: 0,
        usageRate: 0,
        timeProgress: 0,
        forecastOverrun: 0,
        riskLevel: AiRiskLevel.attention,
        summary: '当前账本还没有设置预算，先设置预算才能计算超支风险。',
        suggestion: '到“我的-预算管理”设置本月预算后，AI可提供更精准控支建议。',
      );
    }

    final totalDays = DateTime(current.year, current.month + 1, 0).day;
    final usageRate = (expense / budget).clamp(0.0, 3.0);
    final timeProgress = (current.day / totalDays).clamp(0.0, 1.0);
    final dailyPace = expense / current.day.clamp(1, totalDays);
    final forecastOverrun = dailyPace * totalDays - budget;
    final offset = usageRate - timeProgress;
    final riskLevel = _riskLevel(
      expense: expense,
      budget: budget,
      offset: offset,
    );

    final topCategory = _topCategory(monthExpenseRecords);
    final summary = _summary(
      expense: expense,
      budget: budget,
      forecastOverrun: forecastOverrun,
      riskLevel: riskLevel,
    );
    final suggestion = _suggestion(
      level: riskLevel,
      topCategory: topCategory,
      forecastOverrun: forecastOverrun,
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
  }) {
    if (expense >= budget || offset >= 0.2) {
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
  }) {
    if (riskLevel == AiRiskLevel.safe) {
      return '当前支出 ¥${expense.toStringAsFixed(0)}，预算使用节奏健康。';
    }
    if (forecastOverrun > 0) {
      return '按当前节奏，月末预计超支 ¥${forecastOverrun.toStringAsFixed(0)}。';
    }
    final remaining = budget - expense;
    return '当前已支出 ¥${expense.toStringAsFixed(0)}，预算剩余 ¥${remaining.toStringAsFixed(0)}，建议关注后续大额开销。';
  }

  String _suggestion({
    required AiRiskLevel level,
    required String? topCategory,
    required double forecastOverrun,
  }) {
    final categoryTip = topCategory == null
        ? '优先检查本周最高支出分类'
        : '优先控制“$topCategory”分类';
    return switch (level) {
      AiRiskLevel.safe => '预算节奏良好，继续保持当前记账与复盘频率。',
      AiRiskLevel.attention => '$categoryTip，建议把日预算下调 10%-15%。',
      AiRiskLevel.warning =>
        '$categoryTip，并在剩余天数内把可变支出压缩约 ¥${forecastOverrun.abs().toStringAsFixed(0)}。',
    };
  }
}
