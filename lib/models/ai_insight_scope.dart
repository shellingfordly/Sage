import 'package:flutter/material.dart';

import '../components/time_range/export_range.dart';
import '../models/ledger_record.dart';
import '../utils/ledger_formatters.dart';

class AiInsightScope {
  const AiInsightScope({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AiInsightScope &&
            start == other.start &&
            end == other.end &&
            label == other.label;
  }

  @override
  int get hashCode => Object.hash(start, end, label);

  bool get isSingleMonth =>
      start.year == end.year && start.month == end.month;

  bool isPastRange(DateTime now) {
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return now.isAfter(endDay);
  }

  int monthSpanCount() {
    return (end.year - start.year) * 12 + end.month - start.month + 1;
  }

  DateTime suggestionAnchorMonth(DateTime now) {
    return monthStart(referenceDate(now));
  }

  String periodIncomeLabel() => isSingleMonth ? '本月收入' : '时段收入';

  String periodExpenseLabel() => isSingleMonth ? '本月支出' : '时段支出';

  String periodBalanceLabel() => isSingleMonth ? '本月结余' : '时段结余';

  String periodBudgetLabel() => isSingleMonth ? '本月预算' : '时段预算';

  bool get supportsBudgetApply => isSingleMonth;

  DateTime referenceDate(DateTime now) {
    if (now.isBefore(start)) {
      return end;
    }
    if (now.isAfter(end)) {
      return end;
    }
    return now;
  }

  int totalDays() {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return endDay.difference(startDay).inDays + 1;
  }

  int elapsedDays(DateTime reference) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final refDay = DateTime(reference.year, reference.month, reference.day);
    final effectiveEnd = refDay.isBefore(endDay) ? refDay : endDay;
    if (effectiveEnd.isBefore(startDay)) {
      return 1;
    }
    return effectiveEnd.difference(startDay).inDays + 1;
  }

  factory AiInsightScope.fromMonth(DateTime month, {DateTime? now}) {
    final normalized = monthStart(month);
    final reference = now ?? DateTime.now();
    final bounds = exportRangeBounds(
      range: ExportRange.month,
      now: DateTime(normalized.year, normalized.month, reference.day),
    );
    return AiInsightScope(
      start: bounds!.start,
      end: bounds.end,
      label: formatMonthTitle(normalized, now: reference, includeLedgerSuffix: false),
    );
  }

  factory AiInsightScope.fromExportRange({
    required ExportRange range,
    DateTimeRange? customRange,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final bounds = exportRangeBounds(
      range: range,
      customRange: customRange,
      now: reference,
    );
    if (bounds == null) {
      throw ArgumentError('无法解析时间范围');
    }

    final label = switch (range) {
      ExportRange.week ||
      ExportRange.month ||
      ExportRange.lastMonth =>
        exportRangeLabel(range),
      ExportRange.custom ||
      ExportRange.year ||
      ExportRange.lastYear =>
        currentExportRangeText(
          range: range,
          customRange: customRange,
          now: reference,
        ),
    };

    return AiInsightScope(
      start: bounds.start,
      end: bounds.end,
      label: label,
    );
  }
}

List<LedgerRecord> filterRecordsInScope(
  List<LedgerRecord> records,
  AiInsightScope scope,
) {
  return records
      .where(
        (record) =>
            !record.createdAt.isBefore(scope.start) &&
            !record.createdAt.isAfter(scope.end),
      )
      .toList();
}

double budgetForScope(
  AiInsightScope scope,
  double Function(DateTime month) monthlyBudgetFor,
) {
  if (scope.isSingleMonth) {
    return monthlyBudgetFor(monthStart(scope.start));
  }

  var total = 0.0;
  var cursor = monthStart(scope.start);
  final endMonth = monthStart(scope.end);
  while (!cursor.isAfter(endMonth)) {
    total += monthlyBudgetFor(cursor);
    cursor = DateTime(cursor.year, cursor.month + 1, 1);
  }
  return total;
}
