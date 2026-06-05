import '../../models/ai_insight_scope.dart';
import '../../models/ledger_record.dart';
import '../../models/ai_insight_models.dart';
import 'consumption_record_filter.dart';

class AiOverviewAnalyzer {
  const AiOverviewAnalyzer();

  AiOverviewInsight analyze({
    required List<LedgerRecord> records,
    required AiInsightScope scope,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final scopeRecords = filterRecordsInScope(records, scope);
    final income = scopeRecords
        .where((record) => record.isIncome)
        .fold<double>(0, (sum, record) => sum + record.amount);
    final expenseRecords = consumptionExpenses(scopeRecords);
    final expense = expenseRecords.fold<double>(
      0,
      (sum, record) => sum + record.amount,
    );
    final balance = income - expense;
    final elapsedDays = scope.elapsedDays(reference).clamp(1, scope.totalDays());
    final dailyAvg = expense / elapsedDays;

    final expenseByCategory = <String, double>{};
    for (final record in expenseRecords) {
      expenseByCategory.update(
        record.category,
        (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
    }
    final top = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = top.take(3).map((entry) {
      final percent = expense <= 0 ? 0.0 : (entry.value / expense);
      return AiCategoryShare(
        category: entry.key,
        amount: entry.value,
        percent: percent,
      );
    }).toList();

    final summary = _buildSummary(
      isSingleMonth: scope.isSingleMonth,
      totalExpense: expense,
      topCategories: topCategories,
      dailyAvg: dailyAvg,
    );

    return AiOverviewInsight(
      totalIncome: income,
      totalExpense: expense,
      balance: balance,
      dailyAvgExpense: dailyAvg,
      topCategories: topCategories,
      summary: summary,
    );
  }

  String _buildSummary({
    required bool isSingleMonth,
    required double totalExpense,
    required List<AiCategoryShare> topCategories,
    required double dailyAvg,
  }) {
    final periodLabel = isSingleMonth ? '本月' : '所选时段';
    if (totalExpense <= 0) {
      return '$periodLabel暂无消费支出（已排除转账等非消费项）。';
    }
    if (topCategories.isEmpty) {
      return '$periodLabel消费支出已统计，建议继续补充分类。';
    }
    final top = topCategories.first;
    final topPercent = (top.percent * 100).toStringAsFixed(0);
    return '$periodLabel消费支出最高的是${top.category}，占比约$topPercent%，日均约 ¥${dailyAvg.toStringAsFixed(0)}。';
  }
}
