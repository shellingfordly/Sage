import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/components/time_range/export_range.dart';
import 'package:ledger_app/models/ledger_record.dart';
import 'package:ledger_app/pages/analysis/analysis_navigation.dart';
import 'package:ledger_app/pages/analysis/analysis_query.dart';

void main() {
  tearDown(() {
    analysisNavigationController.consumePending();
  });

  group('AnalysisNavigationController', () {
    test('stores and consumes pending drill-down', () {
      final range = DateTimeRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30, 23, 59, 59),
      );
      final drillDown = AnalysisDrillDown(
        dateRange: range,
        category: '餐饮',
        consumptionOnly: true,
      );

      analysisNavigationController.open(drillDown);

      expect(analysisNavigationController.pending, isNotNull);
      expect(analysisNavigationController.pending!.category, '餐饮');

      final consumed = analysisNavigationController.consumePending();
      expect(consumed?.category, '餐饮');
      expect(analysisNavigationController.pending, isNull);
    });

    test('toFilters maps to custom range with consumption filter', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31, 23, 59, 59),
      );
      final filters = AnalysisDrillDown(
        dateRange: range,
        category: '交通',
        searchQuery: '地铁',
        consumptionOnly: true,
      ).toFilters();

      expect(filters.range, ExportRange.custom);
      expect(filters.customRange, range);
      expect(filters.typeFilter, AnalysisTypeFilter.expense);
      expect(filters.category, '交通');
      expect(filters.searchQuery, '地铁');
      expect(filters.consumptionOnly, isTrue);
    });
  });

  group('monthDrillDownRange', () {
    test('covers full calendar month', () {
      final range = monthDrillDownRange(DateTime(2026, 6, 15));
      expect(range.start, DateTime(2026, 6, 1));
      expect(range.end, DateTime(2026, 6, 30, 23, 59, 59));
    });
  });
}
