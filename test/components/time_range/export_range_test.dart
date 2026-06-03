import 'package:flutter_test/flutter_test.dart';

import 'package:ledger_app/models/ledger_record.dart';
import 'package:ledger_app/components/time_range/export_range.dart';

void main() {
  final records = [
    LedgerRecord(
      id: '1',
      title: '本周午餐',
      amount: 20,
      type: LedgerRecordType.expense,
      category: '餐饮',
      createdAt: DateTime(2026, 6, 3, 12),
    ),
    LedgerRecord(
      id: '2',
      title: '上月交通',
      amount: 6,
      type: LedgerRecordType.expense,
      category: '交通',
      createdAt: DateTime(2026, 5, 20),
    ),
    LedgerRecord(
      id: '3',
      title: '去年工资',
      amount: 8000,
      type: LedgerRecordType.income,
      category: '工资',
      createdAt: DateTime(2025, 3, 1),
    ),
  ];

  final now = DateTime(2026, 6, 3, 18);

  group('filterRecordsByExportRange', () {
    test('filters current week from monday to sunday', () {
      final result = filterRecordsByExportRange(
        allRecords: records,
        range: ExportRange.week,
        now: now,
      );

      expect(result, hasLength(1));
      expect(result.first.title, '本周午餐');
    });

    test('filters last month', () {
      final result = filterRecordsByExportRange(
        allRecords: records,
        range: ExportRange.lastMonth,
        now: now,
      );

      expect(result, hasLength(1));
      expect(result.first.title, '上月交通');
    });

    test('filters last year', () {
      final result = filterRecordsByExportRange(
        allRecords: records,
        range: ExportRange.lastYear,
        now: now,
      );

      expect(result, hasLength(1));
      expect(result.first.title, '去年工资');
    });
  });
}
