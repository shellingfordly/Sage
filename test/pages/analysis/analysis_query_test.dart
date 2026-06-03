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
      createdAt: DateTime(2025, 12, 10),
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

      expect(result.records, hasLength(1));
      expect(result.records.first.title, '地铁');
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
  });
}
