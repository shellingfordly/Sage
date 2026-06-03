import 'package:flutter/material.dart';

import '../../components/pickers/record_date_picker.dart';
import 'package:ledger_app/components/time_range/export_range.dart';
import 'package:ledger_app/components/time_range/time_range_panel.dart';
import '../../data/ledger_store.dart';
import '../../theme/app_styles.dart';
import 'statistics_calculator.dart';
import 'widgets/category_breakdown_panel.dart';
import 'widgets/charts_common_widgets.dart';
import 'widgets/charts_summary_widgets.dart';
import 'widgets/expense_trend_panel.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  ExportRange _range = ExportRange.month;
  DateTimeRange? _customRange;

  void _onRangeChanged(ExportRange range) {
    setState(() {
      _range = range;
      if (range == ExportRange.custom && _customRange == null) {
        final now = DateTime.now();
        _customRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialRange = _customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );
    final picked = await pickCustomDateRange(
      context,
      initialStart: initialRange.start,
      initialEnd: initialRange.end,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: '选择统计时间范围',
    );
    if (picked == null) {
      return;
    }
    setState(() => _customRange = picked);
  }

  void _onClearCustomRange() {
    setState(() => _customRange = null);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ledgerStore,
      builder: (context, child) {
        final today = DateTime.now();
        final bounds = exportRangeBounds(
          range: _range,
          customRange: _customRange,
          now: today,
        );
        if (bounds == null) {
          return const SafeArea(
            child: Center(child: Text('请选择有效的时间范围')),
          );
        }

        final statisticsRange = statisticsDateRangeFromBounds(bounds);
        final expenseRecords = expenseRecordsInRange(
          ledgerStore.records,
          statisticsRange,
        );
        final totalExpense = expenseRecords.fold<double>(
          0,
          (sum, record) => sum + record.amount,
        );
        final isCurrentRange = isCurrentTimeRange(_range);
        final elapsedDays = isCurrentRange
            ? elapsedDaysInBounds(bounds, today)
            : statisticsRange.endExclusive.difference(statisticsRange.start).inDays;
        final dailyAverage = elapsedDays == 0
            ? 0.0
            : totalExpense / elapsedDays;
        final largestExpense = largestExpenseRecord(expenseRecords);
        final categories = categoryTotalsForRecords(expenseRecords);
        final periodLabel = timeRangeChartLabel(_range);
        final periodRangeText = formatTimeRangeBoundsText(
          bounds,
          today,
          isCurrentRange: isCurrentRange,
        );
        final trendBuckets = trendBucketsForTimeRange(
          range: _range,
          bounds: bounds,
          expenseRecords: expenseRecords,
          today: today,
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ChartsHeader(),
                const SizedBox(height: 20),
                TimeRangePanel(
                  selectedRange: _range,
                  periodRangeText: periodRangeText,
                  customRange: _customRange,
                  onRangeChanged: _onRangeChanged,
                  onPickCustomRange: _pickCustomRange,
                  onClearCustomRange: _onClearCustomRange,
                ),
                const SizedBox(height: 18),
                ChartsTotalCard(
                  periodLabel: periodLabel,
                  totalExpense: totalExpense,
                  topCategory: categories.isEmpty ? null : categories.first,
                ),
                const SizedBox(height: 16),
                ChartsSummaryGrid(
                  dailyAverage: dailyAverage,
                  largestExpense: largestExpense,
                ),
                const SizedBox(height: 28),
                const ChartsSectionTitle(title: '支出分类'),
                const SizedBox(height: 12),
                CategoryBreakdownPanel(categories: categories),
                const SizedBox(height: 28),
                ChartsSectionTitle(title: '$periodLabel趋势'),
                const SizedBox(height: 12),
                ExpenseTrendPanel(buckets: trendBuckets),
              ],
            ),
          ),
        );
      },
    );
  }
}
