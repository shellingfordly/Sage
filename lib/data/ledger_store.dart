import 'package:flutter/foundation.dart';

import '../models/ledger_record.dart';
import 'ledger_repository.dart';

final ledgerStore = LedgerStore(LedgerRepository());

class LedgerStore extends ChangeNotifier {
  LedgerStore(this._repository);

  final LedgerRepository _repository;
  final List<LedgerRecord> _records = [];

  bool _loaded = false;
  bool _saving = false;

  bool get loaded => _loaded;
  bool get saving => _saving;
  List<LedgerRecord> get records => List.unmodifiable(_records);

  Future<void> load() async {
    final loadedRecords = await _repository.loadRecords();
    _records
      ..clear()
      ..addAll(loadedRecords);
    _loaded = true;
    notifyListeners();
  }

  Future<void> addRecord({
    required String title,
    required double amount,
    required LedgerRecordType type,
    required String category,
    required DateTime createdAt,
  }) async {
    final record = LedgerRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      amount: amount,
      type: type,
      category: category,
      createdAt: createdAt,
    );

    _records.insert(0, record);
    _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _save();
  }

  List<LedgerRecord> recordsForMonth(DateTime month) {
    return _records
        .where((record) => _isSameMonth(record.createdAt, month))
        .toList();
  }

  List<LedgerRecord> recentRecords({int limit = 5}) {
    return _records.take(limit).toList();
  }

  double incomeForMonth(DateTime month) {
    return _sumForMonth(month, LedgerRecordType.income);
  }

  double expenseForMonth(DateTime month) {
    return _sumForMonth(month, LedgerRecordType.expense);
  }

  double balanceForMonth(DateTime month) {
    return incomeForMonth(month) - expenseForMonth(month);
  }

  LedgerRecord? largestExpenseForMonth(DateTime month) {
    final expenses =
        recordsForMonth(
            month,
          ).where((record) => record.type == LedgerRecordType.expense).toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return expenses.isEmpty ? null : expenses.first;
  }

  List<CategoryTotal> expenseCategoryTotalsForMonth(DateTime month) {
    final totals = <String, double>{};
    for (final record in recordsForMonth(month)) {
      if (record.type == LedgerRecordType.expense) {
        totals.update(
          record.category,
          (value) => value + record.amount,
          ifAbsent: () => record.amount,
        );
      }
    }

    final totalExpense = totals.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );
    final categories = totals.entries.map((entry) {
      final percent = totalExpense == 0 ? 0.0 : entry.value / totalExpense;
      return CategoryTotal(
        category: entry.key,
        amount: entry.value,
        percent: percent,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    return categories;
  }

  List<DailyExpenseTotal> dailyExpenseTotalsForMonth(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totals = List<double>.filled(daysInMonth, 0);

    for (final record in recordsForMonth(month)) {
      if (record.type == LedgerRecordType.expense) {
        totals[record.createdAt.day - 1] += record.amount;
      }
    }

    return [
      for (var index = 0; index < totals.length; index++)
        DailyExpenseTotal(day: index + 1, amount: totals[index]),
    ];
  }

  double _sumForMonth(DateTime month, LedgerRecordType type) {
    return recordsForMonth(month)
        .where((record) => record.type == type)
        .fold<double>(0, (sum, record) => sum + record.amount);
  }

  Future<void> _save() async {
    _saving = true;
    notifyListeners();
    await _repository.saveRecords(_records);
    _saving = false;
    notifyListeners();
  }
}

bool _isSameMonth(DateTime date, DateTime month) {
  return date.year == month.year && date.month == month.month;
}
