import 'package:flutter/foundation.dart';

import '../models/ledger_book.dart';
import '../models/ledger_record.dart';
import 'ledger_repository.dart';

final ledgerStore = LedgerStore(LedgerRepository());

class LedgerStore extends ChangeNotifier {
  LedgerStore(this._repository);

  static const defaultLedgerId = 'default-ledger';

  final LedgerRepository _repository;
  final List<LedgerBook> _ledgers = [];
  final Map<String, List<LedgerRecord>> _recordsByLedger = {};
  final Map<String, Map<String, double>> _budgetsByLedger = {};
  String? _currentLedgerId;

  bool _loaded = false;
  bool _saving = false;

  bool get loaded => _loaded;
  bool get saving => _saving;
  List<LedgerBook> get ledgers => List.unmodifiable(_ledgers);
  LedgerBook get currentLedger => _currentLedger;
  List<LedgerRecord> get records => List.unmodifiable(_currentRecords);

  LedgerBook get _currentLedger {
    final id = _currentLedgerId;
    if (id != null) {
      for (final ledger in _ledgers) {
        if (ledger.id == id) {
          return ledger;
        }
      }
    }
    return _ledgers.first;
  }

  List<LedgerRecord> get _currentRecords {
    final ledgerId = _currentLedger.id;
    return _recordsByLedger.putIfAbsent(ledgerId, () => []);
  }

  Future<void> load() async {
    final snapshot = await _repository.loadData();
    _ledgers
      ..clear()
      ..addAll(snapshot.ledgers);
    _recordsByLedger
      ..clear()
      ..addAll({
        for (final ledger in _ledgers)
          ledger.id: List<LedgerRecord>.from(
            snapshot.recordsByLedger[ledger.id] ?? const <LedgerRecord>[],
          )..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      });
    _budgetsByLedger
      ..clear()
      ..addAll({
        for (final ledger in _ledgers)
          ledger.id: Map<String, double>.from(
            snapshot.budgetsByLedger[ledger.id] ?? const <String, double>{},
          ),
      });
    final hasCurrent = _ledgers.any((ledger) => ledger.id == snapshot.currentLedgerId);
    _currentLedgerId = hasCurrent ? snapshot.currentLedgerId : _ledgers.first.id;
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

    _currentRecords.insert(0, record);
    _currentRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _save();
  }

  Future<void> updateRecord({
    required String recordId,
    required String title,
    required double amount,
    required LedgerRecordType type,
    required String category,
    required DateTime createdAt,
  }) async {
    final records = _currentRecords;
    final index = records.indexWhere((record) => record.id == recordId);
    if (index == -1) {
      return;
    }

    records[index] = LedgerRecord(
      id: recordId,
      title: title.trim(),
      amount: amount,
      type: type,
      category: category,
      createdAt: createdAt,
    );
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _save();
  }

  Future<void> deleteRecord(String recordId) async {
    final records = _currentRecords;
    final before = records.length;
    records.removeWhere((record) => record.id == recordId);
    if (records.length == before) {
      return;
    }
    await _save();
  }

  Future<void> createLedger(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final ledger = LedgerBook(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      createdAt: DateTime.now(),
    );
    _ledgers.add(ledger);
    _recordsByLedger[ledger.id] = [];
    _budgetsByLedger[ledger.id] = {};
    _currentLedgerId = ledger.id;
    await _save();
  }

  Future<void> renameLedger({
    required String ledgerId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final index = _ledgers.indexWhere((ledger) => ledger.id == ledgerId);
    if (index == -1) {
      return;
    }
    _ledgers[index] = _ledgers[index].copyWith(name: trimmed);
    await _save();
  }

  Future<void> switchLedger(String ledgerId) async {
    if (!_ledgers.any((ledger) => ledger.id == ledgerId)) {
      return;
    }
    if (_currentLedgerId == ledgerId) {
      return;
    }
    _currentLedgerId = ledgerId;
    notifyListeners();
  }

  Future<bool> deleteLedger(String ledgerId) async {
    if (_ledgers.length <= 1 || ledgerId == defaultLedgerId) {
      return false;
    }
    final index = _ledgers.indexWhere((ledger) => ledger.id == ledgerId);
    if (index == -1) {
      return false;
    }
    _ledgers.removeAt(index);
    _recordsByLedger.remove(ledgerId);
    _budgetsByLedger.remove(ledgerId);
    if (_currentLedgerId == ledgerId) {
      _currentLedgerId = _ledgers.first.id;
    }
    await _save();
    return true;
  }

  List<LedgerRecord> recordsForLedger(String ledgerId) {
    return List.unmodifiable(_recordsByLedger[ledgerId] ?? const <LedgerRecord>[]);
  }

  bool isDefaultLedger(String ledgerId) => ledgerId == defaultLedgerId;

  double monthlyBudgetFor(DateTime month, {String? ledgerId}) {
    final targetLedgerId = ledgerId ?? _currentLedger.id;
    final key = _monthKey(month);
    return _budgetsByLedger[targetLedgerId]?[key] ?? 0;
  }

  Future<void> setMonthlyBudget({
    required DateTime month,
    required double amount,
    String? ledgerId,
  }) async {
    final targetLedgerId = ledgerId ?? _currentLedger.id;
    final monthly = _budgetsByLedger.putIfAbsent(targetLedgerId, () => {});
    final key = _monthKey(month);

    if (amount <= 0) {
      monthly.remove(key);
    } else {
      monthly[key] = amount;
    }
    await _save();
  }

  List<LedgerRecord> recordsForMonth(DateTime month) {
    return _currentRecords
        .where((record) => _isSameMonth(record.createdAt, month))
        .toList();
  }

  List<LedgerRecord> recentRecords({int limit = 5}) {
    return _currentRecords.take(limit).toList();
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
    await _repository.saveData(
      LedgerRepositoryData(
        ledgers: List<LedgerBook>.from(_ledgers),
        currentLedgerId: _currentLedger.id,
        recordsByLedger: {
          for (final entry in _recordsByLedger.entries)
            entry.key: List<LedgerRecord>.from(entry.value),
        },
        budgetsByLedger: {
          for (final entry in _budgetsByLedger.entries)
            entry.key: Map<String, double>.from(entry.value),
        },
      ),
    );
    _saving = false;
    notifyListeners();
  }
}

String _monthKey(DateTime month) {
  final m = month.month.toString().padLeft(2, '0');
  return '${month.year}-$m';
}

bool _isSameMonth(DateTime date, DateTime month) {
  return date.year == month.year && date.month == month.month;
}
