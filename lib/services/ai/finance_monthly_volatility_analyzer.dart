import '../../models/ai_insight_models.dart';
import '../../models/ai_insight_scope.dart';
import '../../models/ledger_record.dart';
import '../../utils/ledger_formatters.dart';
import 'consumption_record_filter.dart';

class FinanceMonthlyVolatilityAnalyzer {
  const FinanceMonthlyVolatilityAnalyzer();

  FinanceMonthlyVolatilityInsight analyze({
    required List<LedgerRecord> records,
    required AiInsightScope scope,
  }) {
    if (scope.isSingleMonth) {
      return const FinanceMonthlyVolatilityInsight(
        monthlyTotals: <FinanceMonthExpense>[],
        peakMonth: null,
        periodAverage: 0,
        summary: '',
      );
    }

    final scopeRecords = consumptionExpenses(filterRecordsInScope(records, scope));
    if (scopeRecords.isEmpty) {
      return const FinanceMonthlyVolatilityInsight(
        monthlyTotals: <FinanceMonthExpense>[],
        peakMonth: null,
        periodAverage: 0,
        summary: '所选时段暂无消费支出，无法分析月度波动。',
      );
    }

    final totalsByMonth = <DateTime, double>{};
    final categoriesByMonth = <DateTime, Map<String, double>>{};
    for (final record in scopeRecords) {
      final month = DateTime(record.createdAt.year, record.createdAt.month, 1);
      totalsByMonth.update(
        month,
        (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
      final categoryTotals = categoriesByMonth.putIfAbsent(month, () => {});
      categoryTotals.update(
        record.category,
        (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
    }

    if (totalsByMonth.length < 2) {
      final onlyMonth = totalsByMonth.entries.first;
      final monthExpense = _buildMonthExpense(
        month: onlyMonth.key,
        expense: onlyMonth.value,
        periodAverage: onlyMonth.value,
        categoryTotals: categoriesByMonth[onlyMonth.key] ?? {},
      );
      return FinanceMonthlyVolatilityInsight(
        monthlyTotals: <FinanceMonthExpense>[monthExpense],
        peakMonth: null,
        periodAverage: onlyMonth.value,
        summary: '时段内仅 ${onlyMonth.key.month} 月有消费记录，暂无月度波动对比。',
      );
    }

    final monthSpan = scope.monthSpanCount();
    final totalExpense = totalsByMonth.values.fold<double>(0, (a, b) => a + b);
    final periodAverage = totalExpense / monthSpan;

    final monthlyTotals = totalsByMonth.entries.map((entry) {
      return _buildMonthExpense(
        month: entry.key,
        expense: entry.value,
        periodAverage: periodAverage,
        categoryTotals: categoriesByMonth[entry.key] ?? {},
      );
    }).toList()..sort((a, b) => b.expense.compareTo(a.expense));

    FinanceMonthExpense? peakMonth;
    for (final month in monthlyTotals) {
      if (peakMonth == null ||
          month.deviationFromAverage.abs() >
              peakMonth.deviationFromAverage.abs()) {
        peakMonth = month;
      }
    }

    return FinanceMonthlyVolatilityInsight(
      monthlyTotals: monthlyTotals,
      peakMonth: peakMonth,
      periodAverage: periodAverage,
      summary: _buildSummary(peakMonth: peakMonth, periodAverage: periodAverage),
    );
  }

  FinanceMonthExpense _buildMonthExpense({
    required DateTime month,
    required double expense,
    required double periodAverage,
    required Map<String, double> categoryTotals,
  }) {
    final deviation = expense - periodAverage;
    final deviationPercent = periodAverage <= 0
        ? 0.0
        : deviation / periodAverage;
    String? topCategory;
    double topAmount = 0;
    for (final entry in categoryTotals.entries) {
      if (entry.value > topAmount) {
        topCategory = entry.key;
        topAmount = entry.value;
      }
    }
    return FinanceMonthExpense(
      month: month,
      expense: expense,
      deviationFromAverage: deviation,
      deviationPercent: deviationPercent,
      topCategory: topCategory,
      topCategoryAmount: topAmount,
    );
  }

  String _buildSummary({
    required FinanceMonthExpense? peakMonth,
    required double periodAverage,
  }) {
    if (peakMonth == null) {
      return '';
    }
    final monthLabel = '${peakMonth.month.year}年${peakMonth.month.month}月';
    final percent = (peakMonth.deviationPercent.abs() * 100).toStringAsFixed(0);
    final direction = peakMonth.deviationFromAverage >= 0 ? '高于' : '低于';
    var summary =
        '$monthLabel 波动最大，消费 ${formatCurrency(peakMonth.expense)}，'
        '$direction时段月均 ${formatCurrency(periodAverage)} 约 $percent%。';
    if (peakMonth.topCategory != null) {
      summary +=
          ' 该月 ${peakMonth.topCategory} 支出最高（${formatCurrency(peakMonth.topCategoryAmount)}）。';
    }
    return summary;
  }
}
