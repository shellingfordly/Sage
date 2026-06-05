import '../../models/ai_insight_models.dart';
import '../../models/ai_insight_scope.dart';
import '../../models/ledger_record.dart';
import '../../utils/ledger_formatters.dart';
import 'consumption_record_filter.dart';

class FinanceComparisonAnalyzer {
  const FinanceComparisonAnalyzer();

  FinanceComparisonInsight analyze({
    required List<LedgerRecord> records,
    required AiInsightScope scope,
  }) {
    final currentRecords = consumptionExpenses(filterRecordsInScope(records, scope));
    final previousScope = _previousScope(scope);
    final previousRecords = consumptionExpenses(
      filterRecordsInScope(records, previousScope),
    );

    final currentExpense = _sum(currentRecords);
    final previousExpense = _sum(previousRecords);
    final changeAmount = currentExpense - previousExpense;
    final changePercent = previousExpense <= 0
        ? (currentExpense > 0 ? 1.0 : 0.0)
        : changeAmount / previousExpense;

    final categoryChanges = _categoryChanges(
      currentRecords: currentRecords,
      previousRecords: previousRecords,
    );

    return FinanceComparisonInsight(
      currentExpense: currentExpense,
      previousExpense: previousExpense,
      changeAmount: changeAmount,
      changePercent: changePercent,
      previousPeriodLabel: previousScope.label,
      categoryChanges: categoryChanges,
      summary: _buildSummary(
        scope: scope,
        currentExpense: currentExpense,
        previousExpense: previousExpense,
        changePercent: changePercent,
        topChange: categoryChanges.isEmpty ? null : categoryChanges.first,
      ),
    );
  }

  List<FinanceCategoryChange> _categoryChanges({
    required List<LedgerRecord> currentRecords,
    required List<LedgerRecord> previousRecords,
  }) {
    final currentTotals = _categoryTotals(currentRecords);
    final previousTotals = _categoryTotals(previousRecords);
    final categories = <String>{
      ...currentTotals.keys,
      ...previousTotals.keys,
    };

    final changes = <FinanceCategoryChange>[];
    for (final category in categories) {
      final currentAmount = currentTotals[category] ?? 0;
      final previousAmount = previousTotals[category] ?? 0;
      final delta = currentAmount - previousAmount;
      if (delta.abs() < 1) {
        continue;
      }
      final changePercent = previousAmount <= 0
          ? (currentAmount > 0 ? 1.0 : 0.0)
          : delta / previousAmount;
      changes.add(
        FinanceCategoryChange(
          category: category,
          currentAmount: currentAmount,
          previousAmount: previousAmount,
          changeAmount: delta,
          changePercent: changePercent,
          cluster: _findDenseCluster(
            currentRecords
                .where((record) => record.category == category)
                .toList(),
          ),
        ),
      );
    }

    changes.sort((a, b) => b.changeAmount.abs().compareTo(a.changeAmount.abs()));
    return changes.take(5).toList();
  }

  FinanceRecordCluster? _findDenseCluster(List<LedgerRecord> records) {
    if (records.length < 2) {
      return null;
    }
    final sorted = records.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    FinanceRecordCluster? best;
    for (var i = 0; i < sorted.length; i++) {
      var total = sorted[i].amount;
      var count = 1;
      var endIndex = i;
      final windowStart = sorted[i].createdAt;
      for (var j = i + 1; j < sorted.length; j++) {
        if (sorted[j].createdAt.difference(windowStart).inDays > 7) {
          break;
        }
        total += sorted[j].amount;
        count++;
        endIndex = j;
      }
      if (count < 2) {
        continue;
      }
      final cluster = FinanceRecordCluster(
        start: DateTime(
          windowStart.year,
          windowStart.month,
          windowStart.day,
        ),
        end: DateTime(
          sorted[endIndex].createdAt.year,
          sorted[endIndex].createdAt.month,
          sorted[endIndex].createdAt.day,
        ),
        count: count,
        total: total,
      );
      if (best == null || cluster.total > best.total) {
        best = cluster;
      }
    }
    return best;
  }

  Map<String, double> _categoryTotals(List<LedgerRecord> records) {
    final totals = <String, double>{};
    for (final record in records) {
      totals.update(
        record.category,
        (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
    }
    return totals;
  }

  double _sum(List<LedgerRecord> records) {
    return records.fold<double>(0, (sum, record) => sum + record.amount);
  }

  AiInsightScope _previousScope(AiInsightScope scope) {
    final startDay = DateTime(scope.start.year, scope.start.month, scope.start.day);
    final endDay = DateTime(scope.end.year, scope.end.month, scope.end.day);
    final dayCount = endDay.difference(startDay).inDays + 1;
    final previousEnd = startDay.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: dayCount - 1));
    return AiInsightScope(
      start: DateTime(
        previousStart.year,
        previousStart.month,
        previousStart.day,
      ),
      end: DateTime(
        previousEnd.year,
        previousEnd.month,
        previousEnd.day,
        23,
        59,
        59,
      ),
      label: '上一时段',
    );
  }

  String _buildSummary({
    required AiInsightScope scope,
    required double currentExpense,
    required double previousExpense,
    required double changePercent,
    required FinanceCategoryChange? topChange,
  }) {
    if (currentExpense <= 0 && previousExpense <= 0) {
      return '${scope.label} 与上一时段均无消费支出记录。';
    }
    if (previousExpense <= 0) {
      return '${scope.label} 消费支出 ${formatCurrency(currentExpense)}，上一时段无对比数据。';
    }
    final percentText = (changePercent.abs() * 100).toStringAsFixed(0);
    final direction = changePercent >= 0 ? '增加' : '减少';
    var summary =
        '${scope.label} 消费支出 ${formatCurrency(currentExpense)}，较上一时段$direction $percentText%。';
    if (topChange != null && topChange.changeAmount.abs() >= 80) {
      final catDirection = topChange.changeAmount >= 0 ? '上升' : '下降';
      final catPercent = (topChange.changePercent.abs() * 100).toStringAsFixed(0);
      summary += ' ${topChange.category} $catDirection $catPercent%。';
    }
    return summary;
  }
}
