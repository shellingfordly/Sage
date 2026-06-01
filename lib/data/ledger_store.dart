import 'package:flutter/material.dart';

import '../models/ledger_book.dart';
import '../models/ledger_category.dart';
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
  final Map<String, Map<String, Map<String, double>>> _categoryBudgetsByLedger =
      {};
  final Map<String, List<LedgerCategory>> _categoriesByLedger = {};
  String? _currentLedgerId;

  bool _loaded = false;
  bool _saving = false;

  bool get loaded => _loaded;
  bool get saving => _saving;
  List<LedgerBook> get ledgers => List.unmodifiable(_ledgers);
  LedgerBook get currentLedger => _currentLedger;
  List<LedgerRecord> get records => List.unmodifiable(_currentRecords);
  List<LedgerCategory> categoriesForType(
    LedgerRecordType type, {
    String? ledgerId,
  }) {
    final targetLedgerId = ledgerId ?? _currentLedger.id;
    final categories = _categoriesByLedger.putIfAbsent(
      targetLedgerId,
      () => List<LedgerCategory>.from(defaultCategories()),
    );

    final names = <String>{};
    final result = <LedgerCategory>[];
    for (final category in categories) {
      if (category.type == type && names.add(category.name)) {
        result.add(category);
      }
    }

    for (final record
        in _recordsByLedger[targetLedgerId] ?? const <LedgerRecord>[]) {
      if (record.type != type || !names.add(record.category)) {
        continue;
      }
      result.add(
        LedgerCategory(
          id: '${type.name}-${record.category}',
          name: record.category,
          type: type,
          iconKey: iconKeyForCategoryName(record.category, type),
        ),
      );
    }

    if (result.isEmpty) {
      final fallback = defaultCategories().where((item) => item.type == type);
      result.addAll(fallback);
    }
    return List.unmodifiable(result);
  }

  IconData categoryIconFor(
    String categoryName,
    LedgerRecordType type, {
    String? ledgerId,
  }) {
    final matched = categoriesForType(
      type,
      ledgerId: ledgerId,
    ).where((category) => category.name == categoryName);
    if (matched.isNotEmpty) {
      return categoryIconForKey(matched.first.iconKey);
    }
    return categoryIconForKey(iconKeyForCategoryName(categoryName, type));
  }

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
    _categoryBudgetsByLedger
      ..clear()
      ..addAll({
        for (final ledger in _ledgers)
          ledger.id: {
            for (final monthEntry
                in (snapshot.categoryBudgetsByLedger[ledger.id] ??
                        const <String, Map<String, double>>{})
                    .entries)
              monthEntry.key: Map<String, double>.from(monthEntry.value),
          },
      });
    _categoriesByLedger
      ..clear()
      ..addAll({
        for (final ledger in _ledgers)
          ledger.id: List<LedgerCategory>.from(
            snapshot.categoriesByLedger[ledger.id] ?? defaultCategories(),
          ),
      });
    final hasCurrent = _ledgers.any(
      (ledger) => ledger.id == snapshot.currentLedgerId,
    );
    _currentLedgerId = hasCurrent
        ? snapshot.currentLedgerId
        : _ledgers.first.id;
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

  Future<int> importRecords(
    List<LedgerRecord> importedRecords, {
    String? ledgerId,
    bool skipDuplicates = true,
  }) async {
    if (importedRecords.isEmpty) {
      return 0;
    }
    final targetLedgerId = ledgerId ?? _currentLedger.id;
    final targetRecords = _recordsByLedger.putIfAbsent(
      targetLedgerId,
      () => [],
    );
    final categories = _categoriesByLedger.putIfAbsent(
      targetLedgerId,
      () => List<LedgerCategory>.from(defaultCategories()),
    );

    final existingFingerprints = skipDuplicates
        ? targetRecords.map(_recordFingerprint).toSet()
        : <String>{};
    var addedCount = 0;
    for (var index = 0; index < importedRecords.length; index++) {
      final source = importedRecords[index];
      final title = source.title.trim();
      final categoryName = source.category.trim().isEmpty
          ? '其他'
          : source.category.trim();
      if (title.isEmpty || source.amount <= 0) {
        continue;
      }

      final normalized = LedgerRecord(
        id: '${DateTime.now().microsecondsSinceEpoch}-$index',
        title: title,
        amount: source.amount,
        type: source.type,
        category: categoryName,
        createdAt: source.createdAt,
      );
      final fingerprint = _recordFingerprint(normalized);
      if (skipDuplicates && existingFingerprints.contains(fingerprint)) {
        continue;
      }
      targetRecords.add(normalized);
      existingFingerprints.add(fingerprint);
      addedCount++;

      final hasCategory = categories.any(
        (category) =>
            category.type == normalized.type &&
            category.name == normalized.category,
      );
      if (!hasCategory) {
        categories.add(
          LedgerCategory(
            id: '${normalized.type.name}-${DateTime.now().microsecondsSinceEpoch}-$index',
            name: normalized.category,
            type: normalized.type,
            iconKey: iconKeyForCategoryName(
              normalized.category,
              normalized.type,
            ),
          ),
        );
      }
    }

    if (addedCount == 0) {
      return 0;
    }
    targetRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _save();
    return addedCount;
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
    _categoryBudgetsByLedger[ledger.id] = {};
    _categoriesByLedger[ledger.id] = List<LedgerCategory>.from(
      defaultCategories(),
    );
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
    _categoryBudgetsByLedger.remove(ledgerId);
    _categoriesByLedger.remove(ledgerId);
    if (_currentLedgerId == ledgerId) {
      _currentLedgerId = _ledgers.first.id;
    }
    await _save();
    return true;
  }

  List<LedgerRecord> recordsForLedger(String ledgerId) {
    return List.unmodifiable(
      _recordsByLedger[ledgerId] ?? const <LedgerRecord>[],
    );
  }

  bool isDefaultLedger(String ledgerId) => ledgerId == defaultLedgerId;

  Future<bool> createCategory({
    required LedgerRecordType type,
    required String name,
    required String iconKey,
    String? ledgerId,
  }) async {
    final targetLedgerId = ledgerId ?? _currentLedger.id;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final categories = _categoriesByLedger.putIfAbsent(
      targetLedgerId,
      () => List<LedgerCategory>.from(defaultCategories()),
    );
    final exists = categories.any(
      (category) => category.type == type && category.name == trimmed,
    );
    if (exists) {
      return false;
    }
    categories.add(
      LedgerCategory(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: trimmed,
        type: type,
        iconKey: iconKey,
      ),
    );
    await _save();
    return true;
  }

  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    required String iconKey,
    String? ledgerId,
  }) async {
    final targetLedgerId = ledgerId ?? _currentLedger.id;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final categories = _categoriesByLedger[targetLedgerId];
    if (categories == null) {
      return false;
    }
    final index = categories.indexWhere(
      (category) => category.id == categoryId,
    );
    if (index == -1) {
      return false;
    }

    final target = categories[index];
    final duplicate = categories.any(
      (category) =>
          category.id != target.id &&
          category.type == target.type &&
          category.name == trimmed,
    );
    if (duplicate) {
      return false;
    }

    categories[index] = target.copyWith(name: trimmed, iconKey: iconKey);
    if (target.name != trimmed) {
      final records =
          _recordsByLedger[targetLedgerId] ?? const <LedgerRecord>[];
      for (var i = 0; i < records.length; i++) {
        final record = records[i];
        if (record.type == target.type && record.category == target.name) {
          records[i] = LedgerRecord(
            id: record.id,
            title: record.title,
            amount: record.amount,
            type: record.type,
            category: trimmed,
            createdAt: record.createdAt,
          );
        }
      }
    }
    await _save();
    return true;
  }

  Future<bool> deleteCategory(String categoryId, {String? ledgerId}) async {
    final targetLedgerId = ledgerId ?? _currentLedger.id;
    final categories = _categoriesByLedger[targetLedgerId];
    if (categories == null) {
      return false;
    }
    final index = categories.indexWhere(
      (category) => category.id == categoryId,
    );
    if (index == -1) {
      return false;
    }
    final target = categories[index];
    categories.removeAt(index);

    final fallbackName = _ensureFallbackCategory(
      categoriesByLedger: _categoriesByLedger,
      targetLedgerId: targetLedgerId,
      type: target.type,
    );
    final records = _recordsByLedger[targetLedgerId] ?? const <LedgerRecord>[];
    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      if (record.type == target.type && record.category == target.name) {
        records[i] = LedgerRecord(
          id: record.id,
          title: record.title,
          amount: record.amount,
          type: record.type,
          category: fallbackName,
          createdAt: record.createdAt,
        );
      }
    }
    await _save();
    return true;
  }

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

  Map<String, double> categoryBudgetsForMonth(
    DateTime month, {
    String? ledgerId,
  }) {
    final targetLedgerId = ledgerId ?? _currentLedger.id;
    final monthKey = _monthKey(month);
    final monthly = _categoryBudgetsByLedger[targetLedgerId];
    if (monthly == null) {
      return const <String, double>{};
    }
    return Map<String, double>.unmodifiable(
      monthly[monthKey] ?? const <String, double>{},
    );
  }

  Future<void> setCategoryBudgetsForMonth({
    required DateTime month,
    required Map<String, double> categoryBudgets,
    String? ledgerId,
    bool syncTotalBudget = true,
  }) async {
    final targetLedgerId = ledgerId ?? _currentLedger.id;
    final monthly = _categoryBudgetsByLedger.putIfAbsent(
      targetLedgerId,
      () => {},
    );
    final monthKey = _monthKey(month);
    final normalized = <String, double>{};
    for (final entry in categoryBudgets.entries) {
      final name = entry.key.trim();
      final amount = entry.value;
      if (name.isEmpty || amount <= 0) {
        continue;
      }
      normalized[name] = amount;
    }

    if (normalized.isEmpty) {
      monthly.remove(monthKey);
    } else {
      monthly[monthKey] = normalized;
    }

    if (syncTotalBudget) {
      final total = normalized.values.fold<double>(
        0,
        (sum, amount) => sum + amount,
      );
      final totals = _budgetsByLedger.putIfAbsent(targetLedgerId, () => {});
      if (total <= 0) {
        totals.remove(monthKey);
      } else {
        totals[monthKey] = total;
      }
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
        categoryBudgetsByLedger: {
          for (final entry in _categoryBudgetsByLedger.entries)
            entry.key: {
              for (final monthEntry in entry.value.entries)
                monthEntry.key: Map<String, double>.from(monthEntry.value),
            },
        },
        categoriesByLedger: {
          for (final entry in _categoriesByLedger.entries)
            entry.key: List<LedgerCategory>.from(entry.value),
        },
      ),
    );
    _saving = false;
    notifyListeners();
  }
}

String _ensureFallbackCategory({
  required Map<String, List<LedgerCategory>> categoriesByLedger,
  required String targetLedgerId,
  required LedgerRecordType type,
}) {
  final categories = categoriesByLedger.putIfAbsent(
    targetLedgerId,
    () => List<LedgerCategory>.from(defaultCategories()),
  );
  for (final category in categories) {
    if (category.type == type && category.name == '其他') {
      return category.name;
    }
  }
  categories.add(
    LedgerCategory(
      id: '${type.name}-fallback-${DateTime.now().millisecondsSinceEpoch}',
      name: '其他',
      type: type,
      iconKey: 'category',
    ),
  );
  return '其他';
}

String _monthKey(DateTime month) {
  final m = month.month.toString().padLeft(2, '0');
  return '${month.year}-$m';
}

bool _isSameMonth(DateTime date, DateTime month) {
  return date.year == month.year && date.month == month.month;
}

String _recordFingerprint(LedgerRecord record) {
  return '${record.type.name}|${record.title}|${record.amount}|${record.category}|${record.createdAt.toIso8601String()}';
}
