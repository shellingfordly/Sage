import '../../models/ledger_record.dart';
import '../../models/ai_insight_models.dart';

class AiOverviewAnalyzer {
  const AiOverviewAnalyzer();

  AiOverviewInsight analyze({
    required List<LedgerRecord> records,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final monthRecords = records
        .where(
          (record) =>
              record.createdAt.year == current.year &&
              record.createdAt.month == current.month,
        )
        .toList();
    final income = monthRecords
        .where((record) => record.isIncome)
        .fold<double>(0, (sum, record) => sum + record.amount);
    final expense = monthRecords
        .where((record) => !record.isIncome)
        .fold<double>(0, (sum, record) => sum + record.amount);
    final balance = income - expense;
    final dailyAvg = expense / current.day.clamp(1, 31);

    final expenseByCategory = <String, double>{};
    for (final record in monthRecords) {
      if (record.isIncome) {
        continue;
      }
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
    required double totalExpense,
    required List<AiCategoryShare> topCategories,
    required double dailyAvg,
  }) {
    if (totalExpense <= 0) {
      return '本月暂未记录支出，继续保持记账习惯即可获得更准确洞察。';
    }
    if (topCategories.isEmpty) {
      return '本月总支出已生成，建议继续补充分类，获取更具体分析。';
    }
    final top = topCategories.first;
    final topPercent = (top.percent * 100).toStringAsFixed(0);
    return '本月支出最高的是${top.category}，占比约$topPercent%，日均支出约 ¥${dailyAvg.toStringAsFixed(0)}。';
  }
}
