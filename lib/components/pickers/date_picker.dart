import 'package:flutter/material.dart';

import '../../models/ledger_record.dart';
import '../time_range/export_range.dart';

Future<DateTime?> pickDate(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? helpText,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2020),
    lastDate: lastDate ?? DateTime(2100, 12, 31),
    helpText: helpText,
    locale: const Locale('zh', 'CN'),
    cancelText: '取消',
    confirmText: '确定',
  );
}

Future<DateTimeRange?> pickCustomDateRange(
  BuildContext context, {
  required DateTime initialStart,
  required DateTime initialEnd,
  DateTime? firstDate,
  DateTime? lastDate,
  String helpText = '选择日期范围',
}) {
  return showDateRangePicker(
    context: context,
    initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    firstDate: firstDate ?? DateTime(2020),
    lastDate: lastDate ?? DateTime.now(),
    helpText: helpText,
    locale: const Locale('zh', 'CN'),
    cancelText: '取消',
    confirmText: '确定',
    saveText: '确定',
  );
}

/// 自定义范围默认取账单最早/最晚日期，并将可选范围限制在该区间内。
Future<DateTimeRange?> pickRecordBoundedCustomDateRange(
  BuildContext context, {
  required Iterable<LedgerRecord> records,
  DateTimeRange? currentRange,
  required String helpText,
}) async {
  final bounds = recordDateBounds(records);
  if (bounds == null) {
    return null;
  }

  final initialRange = clampDateRange(currentRange ?? bounds, bounds);
  final picked = await pickCustomDateRange(
    context,
    initialStart: initialRange.start,
    initialEnd: initialRange.end,
    firstDate: bounds.start,
    lastDate: bounds.end,
    helpText: helpText,
  );
  if (picked == null) {
    return null;
  }
  return clampDateRange(picked, bounds);
}
