import '../models/ledger_record.dart';

String formatCompactCurrency(double amount, {bool signed = false}) {
  final absAmount = amount.abs();
  final prefix = signed ? (amount >= 0 ? '+' : '-') : (amount < 0 ? '-' : '');

  if (absAmount >= 100000000) {
    return '$prefix${(absAmount / 100000000).toStringAsFixed(1)}亿';
  }
  if (absAmount >= 10000) {
    return '$prefix${(absAmount / 10000).toStringAsFixed(absAmount >= 100000 ? 0 : 1)}万';
  }
  if (absAmount >= 1000) {
    return '$prefix${absAmount.toStringAsFixed(0)}';
  }
  if (absAmount == 0) {
    return signed ? '+0' : '0';
  }
  return '$prefix${absAmount.toStringAsFixed(absAmount >= 100 ? 0 : 2)}';
}

String formatCurrency(double amount, {bool signed = false}) {
  final absAmount = amount.abs();
  final fixed = absAmount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final integer = parts.first;
  final decimal = parts.last;
  final buffer = StringBuffer();

  for (var index = 0; index < integer.length; index++) {
    final positionFromEnd = integer.length - index;
    buffer.write(integer[index]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }

  final prefix = signed
      ? (amount >= 0 ? '+¥ ' : '-¥ ')
      : (amount < 0 ? '-¥ ' : '¥ ');
  return '$prefix$buffer.$decimal';
}

String formatRecordAmount(LedgerRecord record) {
  if (record.isWealth) {
    return formatCurrency(record.amount, signed: true);
  }
  final amount = record.isIncome ? record.amount : -record.amount;
  return formatCurrency(amount, signed: true);
}

String formatMonthTitle(
  DateTime date, {
  DateTime? now,
  bool includeLedgerSuffix = true,
}) {
  final current = now ?? DateTime.now();
  final label = date.year == current.year
      ? '${date.month}月'
      : '${date.year}年${date.month}月';
  return includeLedgerSuffix ? '$label账本' : label;
}

DateTime monthStart(DateTime date) => DateTime(date.year, date.month, 1);

DateTime monthReferenceDate(DateTime month, {DateTime? now}) {
  final current = now ?? DateTime.now();
  if (monthStart(month) == monthStart(current)) {
    return current;
  }
  return DateTime(month.year, month.month + 1, 0);
}

bool isCurrentMonth(DateTime month, {DateTime? now}) {
  final current = now ?? DateTime.now();
  return month.year == current.year && month.month == current.month;
}

String monthBillSectionTitle(DateTime month, {DateTime? now}) {
  if (isCurrentMonth(month, now: now)) {
    return '本月账单';
  }
  return '${month.month}月账单';
}

String monthBalanceLabel(DateTime month, {DateTime? now}) {
  if (isCurrentMonth(month, now: now)) {
    return '本月结余';
  }
  return '${month.month}月结余';
}

String monthBudgetLabel(DateTime month, {DateTime? now}) {
  if (isCurrentMonth(month, now: now)) {
    return '本月预算';
  }
  return '${month.month}月预算';
}

String homeSubtitleForMonth(DateTime month, {DateTime? now}) {
  return '查看${month.month}月账单与预算情况';
}

String formatRecordDate(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final recordDay = DateTime(date.year, date.month, date.day);
  final time =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  if (recordDay == today) {
    return '今天 $time';
  }
  if (recordDay == today.subtract(const Duration(days: 1))) {
    return '昨天 $time';
  }
  if (date.year == current.year) {
    return '${date.month}月${date.day}日';
  }
  return '${date.year}年${date.month}月${date.day}日';
}

String monthlyComparisonText(double currentBalance, double previousBalance) {
  final delta = currentBalance - previousBalance;
  if (delta == 0) {
    return '和上月结余持平';
  }

  final direction = delta > 0 ? '多存' : '少存';
  return '比上月$direction ${formatCurrency(delta.abs())}';
}
