import 'package:ledger_app/components/time_range/export_range.dart';
import '../../data/ledger_store.dart';
import '../../models/ledger_record.dart';
import 'statistics_period.dart';

StatisticsDateRange statisticsDateRangeFromBounds(ExportRangeBounds bounds) {
  final start = DateTime(bounds.start.year, bounds.start.month, bounds.start.day);
  final endDay = DateTime(bounds.end.year, bounds.end.month, bounds.end.day);
  return StatisticsDateRange(
    start: start,
    endExclusive: endDay.add(const Duration(days: 1)),
  );
}

String timeRangeChartLabel(ExportRange range) {
  return exportRangeLabel(range);
}

int elapsedDaysInBounds(ExportRangeBounds bounds, DateTime today) {
  final startDay = DateTime(bounds.start.year, bounds.start.month, bounds.start.day);
  final endDay = DateTime(bounds.end.year, bounds.end.month, bounds.end.day);
  final todayDate = DateTime(today.year, today.month, today.day);
  final effectiveEnd = todayDate.isBefore(endDay) ? todayDate : endDay;
  if (effectiveEnd.isBefore(startDay)) {
    return 0;
  }
  return effectiveEnd.difference(startDay).inDays + 1;
}

bool isCurrentTimeRange(ExportRange range) {
  return switch (range) {
    ExportRange.week || ExportRange.month || ExportRange.year => true,
    ExportRange.lastMonth ||
    ExportRange.lastYear ||
    ExportRange.custom => false,
  };
}

String formatTimeRangeBoundsText(
  ExportRangeBounds bounds,
  DateTime today, {
  required bool isCurrentRange,
}) {
  final todayDate = DateTime(today.year, today.month, today.day);
  final endDay = DateTime(bounds.end.year, bounds.end.month, bounds.end.day);
  final displayEnd =
      isCurrentRange && todayDate.isBefore(endDay) ? todayDate : endDay;
  return '${formatStatisticsDate(bounds.start)} - ${formatStatisticsDate(displayEnd)}';
}

List<TrendBucket> trendBucketsForTimeRange({
  required ExportRange range,
  required ExportRangeBounds bounds,
  required List<LedgerRecord> expenseRecords,
  required DateTime today,
}) {
  final startDay = DateTime(bounds.start.year, bounds.start.month, bounds.start.day);
  final endDay = DateTime(bounds.end.year, bounds.end.month, bounds.end.day);
  final dayCount = endDay.difference(startDay).inDays + 1;

  if (range == ExportRange.year ||
      range == ExportRange.lastYear ||
      dayCount > 62) {
    return monthlyTrendBucketsInBounds(expenseRecords, bounds, today);
  }
  return dailyTrendBucketsInBounds(expenseRecords, bounds, today);
}

List<TrendBucket> dailyTrendBucketsInBounds(
  List<LedgerRecord> expenseRecords,
  ExportRangeBounds bounds,
  DateTime today,
) {
  final totalsByDay = _dailyTotalsMap(expenseRecords);
  final startDay = DateTime(bounds.start.year, bounds.start.month, bounds.start.day);
  final endDay = DateTime(bounds.end.year, bounds.end.month, bounds.end.day);
  final todayDate = DateTime(today.year, today.month, today.day);
  final buckets = <TrendBucket>[];
  var cursor = startDay;
  while (!cursor.isAfter(endDay)) {
    buckets.add(
      TrendBucket(
        label: '${cursor.day}日',
        summaryLabel: '${cursor.month}月${cursor.day}日',
        amount: totalsByDay[cursor] ?? 0,
        isToday: cursor == todayDate,
      ),
    );
    cursor = cursor.add(const Duration(days: 1));
  }
  return buckets;
}

List<TrendBucket> monthlyTrendBucketsInBounds(
  List<LedgerRecord> expenseRecords,
  ExportRangeBounds bounds,
  DateTime today,
) {
  final monthlyTotals = <int, double>{};
  for (final record in expenseRecords) {
    final key = record.createdAt.year * 100 + record.createdAt.month;
    monthlyTotals.update(
      key,
      (value) => value + record.amount,
      ifAbsent: () => record.amount,
    );
  }

  final startMonth = DateTime(bounds.start.year, bounds.start.month, 1);
  final endMonth = DateTime(bounds.end.year, bounds.end.month, 1);
  final buckets = <TrendBucket>[];
  var cursor = startMonth;
  while (!cursor.isAfter(endMonth)) {
    final key = cursor.year * 100 + cursor.month;
    final isCurrentMonth =
        cursor.year == today.year && cursor.month == today.month;
    buckets.add(
      TrendBucket(
        label: '${cursor.month}月',
        summaryLabel: cursor.year == today.year
            ? '${cursor.month}月'
            : '${cursor.year}年${cursor.month}月',
        amount: monthlyTotals[key] ?? 0,
        isToday: isCurrentMonth,
      ),
    );
    cursor = DateTime(cursor.year, cursor.month + 1, 1);
  }
  return buckets;
}

bool isCurrentStatisticsPeriod(
  StatisticsPeriod period,
  DateTime anchor,
  DateTime today,
) {
  switch (period) {
    case StatisticsPeriod.month:
      return anchor.year == today.year && anchor.month == today.month;
    case StatisticsPeriod.year:
      return anchor.year == today.year;
  }
}

String statisticsPeriodLabel(
  StatisticsPeriod period,
  DateTime anchor,
  DateTime today,
) {
  if (isCurrentStatisticsPeriod(period, anchor, today)) {
    return switch (period) {
      StatisticsPeriod.month => '本月',
      StatisticsPeriod.year => '本年',
    };
  }
  return switch (period) {
    StatisticsPeriod.month => anchor.year == today.year
        ? '${anchor.month}月'
        : '${anchor.year}年${anchor.month}月',
    StatisticsPeriod.year => '${anchor.year}年',
  };
}

int statisticsFirstYear(DateTime today) {
  var firstYear = today.year;
  for (final record in ledgerStore.records) {
    if (record.createdAt.year < firstYear) {
      firstYear = record.createdAt.year;
    }
  }
  return firstYear;
}

String formatStatisticsDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

String formatStatisticsPeriodRangeText(
  StatisticsDateRange range,
  DateTime today, {
  required bool isCurrentPeriod,
}) {
  final todayDate = DateTime(today.year, today.month, today.day);
  final rangeEnd = range.endExclusive.subtract(const Duration(days: 1));
  final displayEnd =
      isCurrentPeriod && todayDate.isBefore(rangeEnd) ? todayDate : rangeEnd;
  return '${formatStatisticsDate(range.start)} - ${formatStatisticsDate(displayEnd)}';
}

StatisticsDateRange statisticsPeriodRange(StatisticsPeriod period, DateTime anchor) {
  switch (period) {
    case StatisticsPeriod.month:
      final monthStartDate = DateTime(anchor.year, anchor.month, 1);
      return StatisticsDateRange(
        start: monthStartDate,
        endExclusive: DateTime(anchor.year, anchor.month + 1, 1),
      );
    case StatisticsPeriod.year:
      return StatisticsDateRange(
        start: DateTime(anchor.year, 1, 1),
        endExclusive: DateTime(anchor.year + 1, 1, 1),
      );
  }
}

DateTime statisticsAnchorDate(StatisticsPeriod period, int year, int month) {
  return switch (period) {
    StatisticsPeriod.year => DateTime(year, 1, 1),
    StatisticsPeriod.month => DateTime(year, month, 1),
  };
}

int elapsedDaysForStatisticsPeriod(
  StatisticsPeriod period,
  DateTime anchor,
  DateTime today,
) {
  final range = statisticsPeriodRange(period, anchor);
  if (!isCurrentStatisticsPeriod(period, anchor, today)) {
    return range.endExclusive.difference(range.start).inDays;
  }

  return switch (period) {
    StatisticsPeriod.month => today.day,
    StatisticsPeriod.year => today.difference(DateTime(today.year, 1, 1)).inDays + 1,
  };
}

List<LedgerRecord> expenseRecordsInRange(
  List<LedgerRecord> records,
  StatisticsDateRange range,
) {
  return records.where((record) {
    return record.type == LedgerRecordType.expense &&
        !record.createdAt.isBefore(range.start) &&
        record.createdAt.isBefore(range.endExclusive);
  }).toList();
}

LedgerRecord? largestExpenseRecord(List<LedgerRecord> expenseRecords) {
  if (expenseRecords.isEmpty) {
    return null;
  }
  return expenseRecords.reduce(
    (largest, record) => record.amount > largest.amount ? record : largest,
  );
}

List<CategoryTotal> categoryTotalsForRecords(List<LedgerRecord> expenseRecords) {
  final totals = <String, double>{};
  for (final record in expenseRecords) {
    totals.update(
      record.category,
      (value) => value + record.amount,
      ifAbsent: () => record.amount,
    );
  }

  final totalExpense = totals.values.fold<double>(0, (sum, item) => sum + item);
  return totals.entries.map((entry) {
    final percent = totalExpense == 0 ? 0.0 : entry.value / totalExpense;
    return CategoryTotal(
      category: entry.key,
      amount: entry.value,
      percent: percent,
    );
  }).toList()..sort((a, b) => b.amount.compareTo(a.amount));
}

List<TrendBucket> trendBucketsForPeriod({
  required StatisticsPeriod period,
  required List<LedgerRecord> expenseRecords,
  required StatisticsDateRange range,
  required DateTime anchor,
  required DateTime today,
}) {
  return switch (period) {
    StatisticsPeriod.month => monthlyTrendBuckets(expenseRecords, range, today),
    StatisticsPeriod.year => yearlyTrendBuckets(expenseRecords, anchor, today),
  };
}

Map<DateTime, double> _dailyTotalsMap(List<LedgerRecord> expenseRecords) {
  final totalsByDay = <DateTime, double>{};
  for (final record in expenseRecords) {
    final day = DateTime(
      record.createdAt.year,
      record.createdAt.month,
      record.createdAt.day,
    );
    totalsByDay.update(
      day,
      (value) => value + record.amount,
      ifAbsent: () => record.amount,
    );
  }
  return totalsByDay;
}

List<TrendBucket> monthlyTrendBuckets(
  List<LedgerRecord> expenseRecords,
  StatisticsDateRange range,
  DateTime now,
) {
  final totalsByDay = _dailyTotalsMap(expenseRecords);
  final daysInMonth = range.endExclusive.difference(range.start).inDays;
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(daysInMonth, (index) => index + 1).map((day) {
    final date = DateTime(range.start.year, range.start.month, day);
    return TrendBucket(
      label: '$day日',
      summaryLabel: '${date.month}月$day日',
      amount: totalsByDay[date] ?? 0,
      isToday: date == today,
    );
  }).toList();
}

List<TrendBucket> yearlyTrendBuckets(
  List<LedgerRecord> expenseRecords,
  DateTime anchor,
  DateTime today,
) {
  final monthlyTotals = List<double>.filled(12, 0);

  for (final record in expenseRecords) {
    monthlyTotals[record.createdAt.month - 1] += record.amount;
  }

  final highlightMonth = anchor.year == today.year ? today.month : null;
  return [
    for (var index = 0; index < monthlyTotals.length; index++)
      TrendBucket(
        label: '${index + 1}月',
        summaryLabel: '${index + 1}月',
        amount: monthlyTotals[index],
        isToday: highlightMonth != null && index + 1 == highlightMonth,
      ),
  ];
}
