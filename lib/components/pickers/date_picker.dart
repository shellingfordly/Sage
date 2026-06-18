import 'package:flutter/material.dart';

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
