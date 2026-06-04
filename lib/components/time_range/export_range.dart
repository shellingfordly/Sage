import 'package:flutter/material.dart';

import '../../../models/ledger_record.dart';
import '../../../utils/record_import_parser.dart';

enum ExportRange {
  custom,
  week,
  month,
  lastMonth,
  year,
  lastYear,
}

const defaultExportRangePresets = [
  ExportRange.custom,
  ExportRange.week,
  ExportRange.month,
  ExportRange.lastMonth,
  ExportRange.year,
  ExportRange.lastYear,
];

const exportPreviewColumns = ['日期', '类型', '分类', '名称', '金额', '备注', '方式'];

String exportRangeLabel(ExportRange range) {
  return switch (range) {
    ExportRange.custom => '自定义',
    ExportRange.week => '本周',
    ExportRange.month => '本月',
    ExportRange.lastMonth => '上月',
    ExportRange.year => '本年',
    ExportRange.lastYear => '去年',
  };
}

class ExportRangeBounds {
  const ExportRangeBounds({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

ExportRangeBounds? exportRangeBounds({
  required ExportRange range,
  DateTimeRange? customRange,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  return switch (range) {
    ExportRange.custom => _customRangeBounds(customRange),
    ExportRange.week => _weekBounds(reference),
    ExportRange.month => _monthBounds(reference.year, reference.month),
    ExportRange.lastMonth => _lastMonthBounds(reference),
    ExportRange.year => _yearBounds(reference.year),
    ExportRange.lastYear => _yearBounds(reference.year - 1),
  };
}

List<LedgerRecord> filterRecordsByExportRange({
  required List<LedgerRecord> allRecords,
  required ExportRange range,
  DateTimeRange? customRange,
  DateTime? now,
}) {
  final bounds = exportRangeBounds(
    range: range,
    customRange: customRange,
    now: now,
  );
  if (bounds == null) {
    return const [];
  }
  return allRecords
      .where(
        (record) => _isWithinBounds(record.createdAt, bounds.start, bounds.end),
      )
      .toList();
}

ExportRangeBounds? _customRangeBounds(DateTimeRange? range) {
  if (range == null) {
    return null;
  }
  return ExportRangeBounds(
    start: DateTime(range.start.year, range.start.month, range.start.day),
    end: DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    ),
  );
}

ExportRangeBounds _weekBounds(DateTime reference) {
  final dayStart = DateTime(reference.year, reference.month, reference.day);
  final start = dayStart.subtract(Duration(days: reference.weekday - 1));
  final end = DateTime(
    start.year,
    start.month,
    start.day + 6,
    23,
    59,
    59,
  );
  return ExportRangeBounds(start: start, end: end);
}

ExportRangeBounds _monthBounds(int year, int month) {
  return ExportRangeBounds(
    start: DateTime(year, month, 1),
    end: DateTime(year, month + 1, 0, 23, 59, 59),
  );
}

ExportRangeBounds _lastMonthBounds(DateTime reference) {
  final month = reference.month == 1 ? 12 : reference.month - 1;
  final year = reference.month == 1 ? reference.year - 1 : reference.year;
  return _monthBounds(year, month);
}

ExportRangeBounds _yearBounds(int year) {
  return ExportRangeBounds(
    start: DateTime(year, 1, 1),
    end: DateTime(year, 12, 31, 23, 59, 59),
  );
}

bool _isWithinBounds(DateTime value, DateTime start, DateTime end) {
  return !value.isBefore(start) && !value.isAfter(end);
}

String currentExportRangeText({
  required ExportRange range,
  DateTimeRange? customRange,
  DateTime? now,
}) {
  final bounds = exportRangeBounds(
    range: range,
    customRange: customRange,
    now: now,
  );
  if (bounds == null) {
    return '未设置';
  }
  return '${formatDateSlash(bounds.start)} - ${formatDateSlash(bounds.end)}';
}

String buildExportFileName({
  required ExportRange range,
  DateTimeRange? customRange,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  return switch (range) {
    ExportRange.custom => _buildCustomRangeFileName(customRange),
    ExportRange.week => _buildWeekFileName(reference),
    ExportRange.month =>
      'ledger_${reference.year}_${reference.month.toString().padLeft(2, '0')}.xlsx',
    ExportRange.lastMonth => _buildLastMonthFileName(reference),
    ExportRange.year => 'ledger_${reference.year}.xlsx',
    ExportRange.lastYear => 'ledger_${reference.year - 1}.xlsx',
  };
}

String _buildWeekFileName(DateTime reference) {
  final bounds = _weekBounds(reference);
  return 'ledger_week_${bounds.start.year}${bounds.start.month.toString().padLeft(2, '0')}${bounds.start.day.toString().padLeft(2, '0')}.xlsx';
}

String _buildLastMonthFileName(DateTime reference) {
  final bounds = _lastMonthBounds(reference);
  return 'ledger_${bounds.start.year}_${bounds.start.month.toString().padLeft(2, '0')}.xlsx';
}

String _buildCustomRangeFileName(DateTimeRange? range) {
  if (range == null) {
    return 'ledger_custom.xlsx';
  }
  final start = range.start;
  final end = range.end;
  return 'ledger_${start.year}${start.month.toString().padLeft(2, '0')}${start.day.toString().padLeft(2, '0')}_'
      '${end.year}${end.month.toString().padLeft(2, '0')}${end.day.toString().padLeft(2, '0')}.xlsx';
}
