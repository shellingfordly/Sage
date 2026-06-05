import 'package:flutter/material.dart';

import 'package:ledger_app/components/time_range/export_range.dart';
import '../../models/ledger_record.dart';
import '../../services/ai/consumption_record_filter.dart';
import '../../utils/ledger_formatters.dart';
import '../../utils/record_import_parser.dart';

enum AnalysisTypeFilter { all, expense, income, wealth }

enum AnalysisSortOption {
  timeDesc,
  timeAsc,
  amountDesc,
  amountAsc,
}

extension AnalysisSortOptionLabel on AnalysisSortOption {
  bool get isTimeSort =>
      this == AnalysisSortOption.timeDesc || this == AnalysisSortOption.timeAsc;

  bool get isAmountSort =>
      this == AnalysisSortOption.amountDesc || this == AnalysisSortOption.amountAsc;

  bool get isAscending =>
      this == AnalysisSortOption.timeAsc || this == AnalysisSortOption.amountAsc;

  AnalysisSortOption toggleDirection() => switch (this) {
    AnalysisSortOption.timeDesc => AnalysisSortOption.timeAsc,
    AnalysisSortOption.timeAsc => AnalysisSortOption.timeDesc,
    AnalysisSortOption.amountDesc => AnalysisSortOption.amountAsc,
    AnalysisSortOption.amountAsc => AnalysisSortOption.amountDesc,
  };
}

class AnalysisFilters {
  const AnalysisFilters({
    this.range = ExportRange.month,
    this.customRange,
    this.typeFilter = AnalysisTypeFilter.all,
    this.category,
    this.searchQuery = '',
    this.sort = AnalysisSortOption.timeDesc,
    this.consumptionOnly = false,
  });

  final ExportRange range;
  final DateTimeRange? customRange;
  final AnalysisTypeFilter typeFilter;
  final String? category;
  final String searchQuery;
  final AnalysisSortOption sort;
  final bool consumptionOnly;

  AnalysisFilters copyWith({
    ExportRange? range,
    Object? customRange = _unset,
    AnalysisTypeFilter? typeFilter,
    Object? category = _unset,
    String? searchQuery,
    AnalysisSortOption? sort,
    bool? consumptionOnly,
  }) {
    return AnalysisFilters(
      range: range ?? this.range,
      customRange: identical(customRange, _unset)
          ? this.customRange
          : customRange as DateTimeRange?,
      typeFilter: typeFilter ?? this.typeFilter,
      category: identical(category, _unset) ? this.category : category as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      sort: sort ?? this.sort,
      consumptionOnly: consumptionOnly ?? this.consumptionOnly,
    );
  }

  static const _unset = Object();
}

class AnalysisRecordGroup {
  const AnalysisRecordGroup({
    required this.title,
    required this.records,
  });

  final String title;
  final List<LedgerRecord> records;
}

class AnalysisQueryResult {
  const AnalysisQueryResult({
    required this.records,
    required this.totalIncome,
    required this.totalExpense,
  });

  final List<LedgerRecord> records;
  final double totalIncome;
  final double totalExpense;
}

AnalysisQueryResult queryAnalysisRecords(
  List<LedgerRecord> allRecords,
  AnalysisFilters filters, {
  DateTime? now,
}) {
  final normalizedQuery = filters.searchQuery.trim().toLowerCase();
  final periodRecords = filterRecordsByExportRange(
    allRecords: allRecords,
    range: filters.range,
    customRange: filters.customRange,
    now: now,
  );
  final filtered = periodRecords.where((record) {
    if (!_matchesType(record, filters.typeFilter)) {
      return false;
    }
    if (filters.consumptionOnly && !isConsumptionExpense(record)) {
      return false;
    }
    if (filters.category != null && record.category != filters.category) {
      return false;
    }
    if (normalizedQuery.isNotEmpty && !_matchesSearch(record, normalizedQuery)) {
      return false;
    }
    return true;
  }).toList();

  _sortAnalysisRecords(filtered, filters.sort);

  var income = 0.0;
  var expense = 0.0;
  for (final record in filtered) {
    if (record.isIncome) {
      income += record.amount;
    } else if (record.isExpense) {
      expense += record.amount;
    }
  }

  return AnalysisQueryResult(
    records: filtered,
    totalIncome: income,
    totalExpense: expense,
  );
}

bool _matchesType(LedgerRecord record, AnalysisTypeFilter typeFilter) {
  return switch (typeFilter) {
    AnalysisTypeFilter.all => !record.isWealth,
    AnalysisTypeFilter.expense => record.type == LedgerRecordType.expense,
    AnalysisTypeFilter.income => record.type == LedgerRecordType.income,
    AnalysisTypeFilter.wealth => record.type == LedgerRecordType.wealth,
  };
}

bool _matchesSearch(LedgerRecord record, String query) {
  return record.title.toLowerCase().contains(query) ||
      record.category.toLowerCase().contains(query) ||
      record.notes.toLowerCase().contains(query) ||
      record.amount.toString().contains(query);
}

List<String> analysisCategoriesInPeriod(
  List<LedgerRecord> allRecords,
  AnalysisFilters filters, {
  DateTime? now,
}) {
  final periodRecords = filterRecordsByExportRange(
    allRecords: allRecords,
    range: filters.range,
    customRange: filters.customRange,
    now: now,
  );
  final names = <String>{};
  for (final record in periodRecords) {
    if (!_matchesType(record, filters.typeFilter)) {
      continue;
    }
    names.add(record.category);
  }
  final result = names.toList()..sort();
  return result;
}

void _sortAnalysisRecords(
  List<LedgerRecord> records,
  AnalysisSortOption sort,
) {
  switch (sort) {
    case AnalysisSortOption.timeDesc:
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case AnalysisSortOption.timeAsc:
      records.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    case AnalysisSortOption.amountDesc:
      records.sort((a, b) {
        final amountCompare = b.amount.compareTo(a.amount);
        if (amountCompare != 0) {
          return amountCompare;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    case AnalysisSortOption.amountAsc:
      records.sort((a, b) {
        final amountCompare = a.amount.compareTo(b.amount);
        if (amountCompare != 0) {
          return amountCompare;
        }
        return a.createdAt.compareTo(b.createdAt);
      });
  }
}

List<AnalysisRecordGroup> groupAnalysisRecords(
  List<LedgerRecord> records, {
  required ExportRange range,
  DateTimeRange? customRange,
  DateTime? now,
}) {
  if (records.isEmpty) {
    return const [];
  }

  final reference = now ?? DateTime.now();

  return switch (range) {
    ExportRange.week ||
    ExportRange.month ||
    ExportRange.lastMonth =>
      [
        AnalysisRecordGroup(
          title: exportRangeLabel(range),
          records: records,
        ),
      ],
    ExportRange.custom => _groupCustomRangeRecords(
        records,
        customRange: customRange,
        now: reference,
      ),
    ExportRange.year || ExportRange.lastYear => _groupRecordsByMonthTitle(
        records,
        now: reference,
      ),
  };
}

List<AnalysisRecordGroup> _groupCustomRangeRecords(
  List<LedgerRecord> records, {
  DateTimeRange? customRange,
  required DateTime now,
}) {
  final monthKeys = records
      .map((record) => DateTime(record.createdAt.year, record.createdAt.month))
      .toSet();
  if (monthKeys.length > 1) {
    return _groupRecordsByMonthTitle(records, now: now);
  }

  final bounds = exportRangeBounds(
    range: ExportRange.custom,
    customRange: customRange,
    now: now,
  );
  final title = bounds == null
      ? exportRangeLabel(ExportRange.custom)
      : formatDateRangeLabelCompact(bounds.start, bounds.end);

  return [
    AnalysisRecordGroup(title: title, records: records),
  ];
}

List<AnalysisRecordGroup> _groupRecordsByMonthTitle(
  List<LedgerRecord> records, {
  required DateTime now,
}) {
  if (records.isEmpty) {
    return const [];
  }

  final groups = <AnalysisRecordGroup>[];
  DateTime? currentMonth;
  List<LedgerRecord>? currentRecords;

  for (final record in records) {
    final month = DateTime(record.createdAt.year, record.createdAt.month);
    if (currentMonth == null || month != currentMonth) {
      if (currentRecords != null && currentMonth != null) {
        groups.add(
          AnalysisRecordGroup(
            title: formatMonthTitle(currentMonth, now: now, includeLedgerSuffix: false),
            records: currentRecords,
          ),
        );
      }
      currentMonth = month;
      currentRecords = [record];
    } else {
      currentRecords!.add(record);
    }
  }

  if (currentRecords != null && currentMonth != null) {
    groups.add(
      AnalysisRecordGroup(
        title: formatMonthTitle(currentMonth, now: now, includeLedgerSuffix: false),
        records: currentRecords,
      ),
    );
  }

  return groups;
}
