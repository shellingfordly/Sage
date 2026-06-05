import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledger_app/models/ledger_record.dart';
import 'package:ledger_app/components/time_range/export_range.dart';
import 'package:ledger_app/pages/analysis/analysis_query.dart';

void main() {
  final records = [
    LedgerRecord(
      id: '1',
      title: '午餐',
      amount: 35,
      type: LedgerRecordType.expense,
      category: '餐饮',
      createdAt: DateTime(2026, 3, 5, 12, 30),
      notes: '公司附近',
    ),
    LedgerRecord(
      id: '2',
      title: '工资',
      amount: 8000,
      type: LedgerRecordType.income,
      category: '工资',
      createdAt: DateTime(2026, 3, 1),
    ),
    LedgerRecord(
      id: '3',
      title: '地铁',
      amount: 6,
      type: LedgerRecordType.expense,
      category: '交通',
      createdAt: DateTime(2026, 1, 10),
    ),
    LedgerRecord(
      id: '4',
      title: '定存开户',
      amount: 60000,
      type: LedgerRecordType.expense,
      category: '存款',
      createdAt: DateTime(2026, 1, 15),
    ),
  ];

  final now = DateTime(2026, 3, 5, 18);

  group('queryAnalysisRecords', () {
    test('filters by month', () {
      final result = queryAnalysisRecords(
        records,
        const AnalysisFilters(range: ExportRange.month),
        now: now,
      );

      expect(result.records, hasLength(2));
      expect(result.totalExpense, 35);
      expect(result.totalIncome, 8000);
    });

    test('filters by last year', () {
      final result = queryAnalysisRecords(
        records,
        const AnalysisFilters(range: ExportRange.lastYear),
        now: now,
      );

      expect(result.records, isEmpty);
    });

    test('filters by type, category and search', () {
      final result = queryAnalysisRecords(
        records,
        const AnalysisFilters(
          range: ExportRange.month,
          typeFilter: AnalysisTypeFilter.expense,
          category: '餐饮',
          searchQuery: '公司',
        ),
        now: now,
      );

      expect(result.records, hasLength(1));
      expect(result.records.first.title, '午餐');
    });

    test('sorts by time ascending', () {
      final result = queryAnalysisRecords(
        records,
        const AnalysisFilters(
          range: ExportRange.year,
          sort: AnalysisSortOption.timeAsc,
        ),
        now: now,
      );

      expect(result.records.map((record) => record.title).toList(), [
        '地铁',
        '定存开户',
        '工资',
        '午餐',
      ]);
    });

    test('sorts by amount descending', () {
      final result = queryAnalysisRecords(
        records,
        const AnalysisFilters(
          range: ExportRange.year,
          sort: AnalysisSortOption.amountDesc,
        ),
        now: now,
      );

      expect(result.records.first.title, '定存开户');
      expect(result.records.last.title, '地铁');
    });

    test('excludes non-consumption when consumptionOnly is true', () {
      final result = queryAnalysisRecords(
        records,
        const AnalysisFilters(
          range: ExportRange.month,
          typeFilter: AnalysisTypeFilter.expense,
          consumptionOnly: true,
        ),
        now: now,
      );

      expect(result.records, hasLength(1));
      expect(result.records.first.title, '午餐');
    });
  });

  group('groupAnalysisRecords', () {
    test('uses preset label for month range', () {
      final groups = groupAnalysisRecords(
        [records[0], records[1]],
        range: ExportRange.month,
        now: now,
      );

      expect(groups, hasLength(1));
      expect(groups.first.title, '本月');
      expect(groups.first.records, hasLength(2));
    });

    test('uses preset label for week range', () {
      final groups = groupAnalysisRecords(
        [records[0]],
        range: ExportRange.week,
        now: now,
      );

      expect(groups.single.title, '本周');
    });

    test('splits year records into month titled groups', () {
      final sorted = queryAnalysisRecords(
        records,
        const AnalysisFilters(
          range: ExportRange.year,
          sort: AnalysisSortOption.timeDesc,
        ),
        now: now,
      ).records;
      final groups = groupAnalysisRecords(
        sorted,
        range: ExportRange.year,
        now: now,
      );

      expect(groups, hasLength(2));
      expect(groups[0].title, '3月');
      expect(groups[0].records.first.title, '午餐');
      expect(groups[1].title, '1月');
      expect(groups[1].records.first.title, '定存开户');
    });

    test('uses compact custom range label for single-month custom range', () {
      final groups = groupAnalysisRecords(
        [records[0], records[1]],
        range: ExportRange.custom,
        customRange: DateTimeRange(
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 31),
        ),
        now: now,
      );

      expect(groups, hasLength(1));
      expect(groups.first.title, '2026/03/01 - 03/31');
    });
  });
}
