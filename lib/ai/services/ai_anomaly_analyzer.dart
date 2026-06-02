import '../../models/ledger_record.dart';
import '../models/ai_insight_models.dart';

class AiAnomalyAnalyzer {
  const AiAnomalyAnalyzer();

  AiAnomalyInsight analyze({
    required List<LedgerRecord> records,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final expenseRecords = records.where((record) => !record.isIncome).toList();
    if (expenseRecords.length < 10) {
      return const AiAnomalyInsight(
        items: <AiAnomalyItem>[],
        summary: '当前样本较少，继续记录 10 笔以上后可获得更稳定的异常检测结果。',
      );
    }

    final items = <AiAnomalyItem>[
      ..._largeSingleExpense(expenseRecords),
      ..._categorySpike(expenseRecords, current),
      ..._denseSmallExpenses(expenseRecords, current),
    ];
    items.sort(_sortBySeverityThenAmount);
    final topItems = items.take(3).toList();
    final summary = topItems.isEmpty
        ? '最近消费波动较平稳，未发现明显异常。'
        : '识别到 ${topItems.length} 条异常消费，建议优先处理高风险项。';
    return AiAnomalyInsight(items: topItems, summary: summary);
  }

  List<AiAnomalyItem> _largeSingleExpense(List<LedgerRecord> expenseRecords) {
    final amounts = expenseRecords.map((record) => record.amount).toList();
    final avg = amounts.reduce((a, b) => a + b) / amounts.length;
    final threshold = avg * 2;
    final large =
        expenseRecords
            .where(
              (record) => record.amount >= threshold && record.amount >= 100,
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
    if (large.isEmpty) {
      return const <AiAnomalyItem>[];
    }
    final target = large.first;
    return <AiAnomalyItem>[
      AiAnomalyItem(
        title: target.title,
        category: target.category,
        amount: target.amount,
        reason: '单笔金额明显高于历史均值（约 ${threshold.toStringAsFixed(0)} 元）。',
        severity: AiSeverity.high,
        records: <AiAnomalyRecord>[_toAnomalyRecord(target)],
      ),
    ];
  }

  List<AiAnomalyItem> _categorySpike(
    List<LedgerRecord> expenseRecords,
    DateTime now,
  ) {
    final thisMonth = _monthStart(now);
    final previous1 = DateTime(thisMonth.year, thisMonth.month - 1, 1);
    final previous2 = DateTime(thisMonth.year, thisMonth.month - 2, 1);
    final thisMonthTotals = _categoryTotalsForMonth(expenseRecords, thisMonth);
    if (thisMonthTotals.isEmpty) {
      return const <AiAnomalyItem>[];
    }
    final prev1Totals = _categoryTotalsForMonth(expenseRecords, previous1);
    final prev2Totals = _categoryTotalsForMonth(expenseRecords, previous2);
    final thisMonthRecords = expenseRecords.where(
      (record) =>
          record.createdAt.year == thisMonth.year &&
          record.createdAt.month == thisMonth.month,
    );

    AiAnomalyItem? strongest;
    for (final entry in thisMonthTotals.entries) {
      final baseline =
          ((prev1Totals[entry.key] ?? 0) + (prev2Totals[entry.key] ?? 0)) / 2;
      if (baseline <= 0) {
        continue;
      }
      final ratio = entry.value / baseline;
      if (ratio < 1.5 || (entry.value - baseline) < 80) {
        continue;
      }
      final item = AiAnomalyItem(
        title: '${entry.key}类支出激增',
        category: entry.key,
        amount: entry.value,
        reason: '本月较近两月均值上升 ${(ratio * 100 - 100).toStringAsFixed(0)}%。',
        severity: ratio > 2.0 ? AiSeverity.high : AiSeverity.medium,
        records:
            ((thisMonthRecords
                      .where((record) => record.category == entry.key)
                      .toList())
                  ..sort((a, b) => b.amount.compareTo(a.amount)))
                .take(3)
                .map(_toAnomalyRecord)
                .toList(),
      );
      if (strongest == null || item.amount > strongest.amount) {
        strongest = item;
      }
    }
    return strongest == null
        ? const <AiAnomalyItem>[]
        : <AiAnomalyItem>[strongest];
  }

  List<AiAnomalyItem> _denseSmallExpenses(
    List<LedgerRecord> expenseRecords,
    DateTime now,
  ) {
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentSmall = expenseRecords
        .where(
          (record) =>
              record.createdAt.isAfter(sevenDaysAgo) &&
              record.amount > 0 &&
              record.amount <= 50,
        )
        .toList();
    if (recentSmall.length < 8) {
      return const <AiAnomalyItem>[];
    }
    final total = recentSmall.fold<double>(0, (sum, item) => sum + item.amount);
    return <AiAnomalyItem>[
      AiAnomalyItem(
        title: '小额高频消费偏多',
        category: '多分类',
        amount: total,
        reason: '近 7 天共有 ${recentSmall.length} 笔小额支出，累计金额较高。',
        severity: AiSeverity.medium,
        records:
            (recentSmall.toList()..sort((a, b) => b.amount.compareTo(a.amount)))
                .take(5)
                .map(_toAnomalyRecord)
                .toList(),
      ),
    ];
  }

  Map<String, double> _categoryTotalsForMonth(
    List<LedgerRecord> records,
    DateTime month,
  ) {
    final totals = <String, double>{};
    for (final record in records) {
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

  DateTime _monthStart(DateTime date) => DateTime(date.year, date.month, 1);

  int _sortBySeverityThenAmount(AiAnomalyItem a, AiAnomalyItem b) {
    final severityCompare = _severityWeight(
      b.severity,
    ).compareTo(_severityWeight(a.severity));
    if (severityCompare != 0) {
      return severityCompare;
    }
    return b.amount.compareTo(a.amount);
  }

  int _severityWeight(AiSeverity severity) {
    return switch (severity) {
      AiSeverity.high => 3,
      AiSeverity.medium => 2,
      AiSeverity.low => 1,
    };
  }

  AiAnomalyRecord _toAnomalyRecord(LedgerRecord record) {
    return AiAnomalyRecord(
      title: record.title,
      category: record.category,
      amount: record.amount,
      createdAt: record.createdAt,
    );
  }
}

String anomalyRecordKey({
  required String title,
  required String category,
  required double amount,
  required DateTime createdAt,
}) {
  return '$title|$category|$amount|${createdAt.toIso8601String()}';
}

Set<String> anomalyRecordKeys(AiAnomalyInsight insight) {
  final keys = <String>{};
  for (final item in insight.items) {
    for (final record in item.records) {
      keys.add(
        anomalyRecordKey(
          title: record.title,
          category: record.category,
          amount: record.amount,
          createdAt: record.createdAt,
        ),
      );
    }
  }
  return keys;
}

bool isAnomalyLedgerRecord(LedgerRecord record, Set<String> keys) {
  if (record.isIncome || keys.isEmpty) {
    return false;
  }
  return keys.contains(
    anomalyRecordKey(
      title: record.title,
      category: record.category,
      amount: record.amount,
      createdAt: record.createdAt,
    ),
  );
}
