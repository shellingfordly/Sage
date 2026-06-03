import 'package:flutter/material.dart';

import 'package:ledger_app/components/time_range/export_range.dart';
import '../../models/ledger_record.dart';

enum AnalysisTypeFilter { all, expense, income }

class AnalysisFilters {
  const AnalysisFilters({
    this.range = ExportRange.month,
    this.customRange,
    this.typeFilter = AnalysisTypeFilter.all,
    this.category,
    this.searchQuery = '',
  });

  final ExportRange range;
  final DateTimeRange? customRange;
  final AnalysisTypeFilter typeFilter;
  final String? category;
  final String searchQuery;

  AnalysisFilters copyWith({
    ExportRange? range,
    Object? customRange = _unset,
    AnalysisTypeFilter? typeFilter,
    Object? category = _unset,
    String? searchQuery,
  }) {
    return AnalysisFilters(
      range: range ?? this.range,
      customRange: identical(customRange, _unset)
          ? this.customRange
          : customRange as DateTimeRange?,
      typeFilter: typeFilter ?? this.typeFilter,
      category: identical(category, _unset) ? this.category : category as String?,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  static const _unset = Object();
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
    if (filters.category != null && record.category != filters.category) {
      return false;
    }
    if (normalizedQuery.isNotEmpty && !_matchesSearch(record, normalizedQuery)) {
      return false;
    }
    return true;
  }).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  var income = 0.0;
  var expense = 0.0;
  for (final record in filtered) {
    if (record.isIncome) {
      income += record.amount;
    } else {
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
    AnalysisTypeFilter.all => true,
    AnalysisTypeFilter.expense => record.type == LedgerRecordType.expense,
    AnalysisTypeFilter.income => record.type == LedgerRecordType.income,
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
