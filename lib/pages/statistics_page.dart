import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/ledger_store.dart';
import '../models/ledger_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/app_text_styles.dart';
import '../utils/ledger_formatters.dart';
import '../widgets/liquid_category_disk.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  _StatisticsPeriod _selectedPeriod = _StatisticsPeriod.month;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ledgerStore,
      builder: (context, child) {
        final now = DateTime.now();
        final range = _periodRangeFor(_selectedPeriod, now);
        final expenseRecords = _expenseRecordsInRange(
          ledgerStore.records,
          range,
        );
        final totalExpense = expenseRecords.fold<double>(
          0,
          (sum, record) => sum + record.amount,
        );
        final elapsedDays = _elapsedDaysForPeriod(_selectedPeriod, now);
        final dailyAverage = elapsedDays == 0
            ? 0.0
            : totalExpense / elapsedDays;
        final largestExpense = _largestExpense(expenseRecords);
        final categories = _categoryTotalsForRecords(expenseRecords);
        final periodLabel = _periodLabel(_selectedPeriod);
        final periodRangeText = _formatPeriodRangeText(range, now);

        return SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StatisticsHeader(),
                const SizedBox(height: 20),
                _PeriodTabs(
                  selectedPeriod: _selectedPeriod,
                  onSelected: (period) {
                    if (period == _selectedPeriod) {
                      return;
                    }
                    setState(() => _selectedPeriod = period);
                  },
                ),
                const SizedBox(height: 8),
                _PeriodRangePill(text: periodRangeText),
                const SizedBox(height: 18),
                _TotalCard(
                  periodLabel: periodLabel,
                  totalExpense: totalExpense,
                  topCategory: categories.isEmpty ? null : categories.first,
                ),
                const SizedBox(height: 16),
                _SummaryGrid(
                  dailyAverage: dailyAverage,
                  largestExpense: largestExpense,
                ),
                const SizedBox(height: 28),
                const _SectionTitle(title: '支出分类'),
                const SizedBox(height: 12),
                _CategoryBreakdown(categories: categories),
                const SizedBox(height: 28),
                _SectionTitle(title: '$periodLabel趋势'),
                const SizedBox(height: 12),
                _TrendPanel(
                  period: _selectedPeriod,
                  expenseRecords: expenseRecords,
                  range: range,
                  now: now,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatisticsHeader extends StatelessWidget {
  const _StatisticsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('统计', style: AppTextStyles.pageTitle(context)),
        const SizedBox(height: 4),
        Text('按周、月、年查看你的钱都流向哪里', style: AppTextStyles.pageSubtitle(context)),
      ],
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.selectedPeriod, required this.onSelected});

  final _StatisticsPeriod selectedPeriod;
  final ValueChanged<_StatisticsPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PeriodChip(
          label: '本月',
          selected: selectedPeriod == _StatisticsPeriod.month,
          onTap: () => onSelected(_StatisticsPeriod.month),
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: '本周',
          selected: selectedPeriod == _StatisticsPeriod.week,
          onTap: () => onSelected(_StatisticsPeriod.week),
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: '本年',
          selected: selectedPeriod == _StatisticsPeriod.year,
          onTap: () => onSelected(_StatisticsPeriod.year),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: AppRadii.card,
          border: Border.all(
            color: selected ? colors.primary : colors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.chip(context, selected: selected),
        ),
      ),
    );
  }
}

class _PeriodRangePill extends StatelessWidget {
  const _PeriodRangePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        border: Border.all(color: colors.surfaceBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodyMuted(
              context,
            ).copyWith(color: colors.textBody, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.periodLabel,
    required this.totalExpense,
    required this.topCategory,
  });

  final String periodLabel;
  final double totalExpense;
  final CategoryTotal? topCategory;

  @override
  Widget build(BuildContext context) {
    final summary = topCategory == null
        ? '添加记录后会自动生成支出分析'
        : '${topCategory!.category}占比最高，约 ${(topCategory!.percent * 100).round()}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.strongSurface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$periodLabel总支出', style: AppTextStyles.cardLabel(context)),
          const SizedBox(height: 12),
          Text(
            formatCurrency(totalExpense),
            style: AppTextStyles.cardDisplay(context),
          ),
          const SizedBox(height: 10),
          Text(summary, style: AppTextStyles.cardPositive(context)),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.dailyAverage,
    required this.largestExpense,
  });

  final double dailyAverage;
  final LedgerRecord? largestExpense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: '日均支出',
            value: formatCurrency(dailyAverage),
            icon: Icons.calendar_today_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            label: largestExpense == null ? '最大单笔' : largestExpense!.title,
            value: formatCurrency(largestExpense?.amount ?? 0),
            icon: Icons.receipt_long_outlined,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMuted(context),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTextStyles.tileValue(context)),
          ),
        ],
      ),
    );
  }
}

class _CategoryGridLayout {
  const _CategoryGridLayout({
    required this.itemsPerRow,
    required this.diskSize,
  });

  final int itemsPerRow;
  final double diskSize;
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.categories});

  static const _itemGap = 12.0;
  static const _minDiskSize = 48.0;
  static const _maxDiskSize = 76.0;
  static const _diskPadding = 8.0;

  final List<CategoryTotal> categories;

  static _CategoryGridLayout? _layoutFor(double width, int totalItems) {
    if (totalItems == 0 || width <= 0) {
      return null;
    }

    final minCellWidth = _minDiskSize + _diskPadding;
    final maxColumns = math.min(
      totalItems,
      ((width + _itemGap) / (minCellWidth + _itemGap)).floor(),
    );

    if (maxColumns < 2) {
      return null;
    }

    final columns = maxColumns >= totalItems ? totalItems : maxColumns;
    final cellWidth = (width - (columns - 1) * _itemGap) / columns;
    final diskSize = (cellWidth - _diskPadding).clamp(_minDiskSize, _maxDiskSize);

    return _CategoryGridLayout(
      itemsPerRow: columns,
      diskSize: diskSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const _EmptyStatsPanel(
        icon: Icons.pie_chart_outline,
        title: '暂无分类数据',
        subtitle: '添加支出记录后会显示分类占比',
      );
    }

    final colors = context.colors;
    final diskColors = [
      colors.primary,
      colors.danger,
      colors.info,
      colors.positiveText,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: AppDecorations.surface(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _layoutFor(constraints.maxWidth, categories.length);
          if (layout == null) {
            return const SizedBox.shrink();
          }

          final rows = <Widget>[];
          for (var start = 0;
              start < categories.length;
              start += layout.itemsPerRow) {
            final end = math.min(start + layout.itemsPerRow, categories.length);
            rows.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = start; index < end; index++) ...[
                    if (index > start) const SizedBox(width: _itemGap),
                    Expanded(
                      child: _CategoryDisk(
                        category: categories[index],
                        color: diskColors[index % diskColors.length],
                        diskSize: layout.diskSize,
                      ),
                    ),
                  ],
                ],
              ),
            );
            if (end < categories.length) {
              rows.add(const SizedBox(height: 16));
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          );
        },
      ),
    );
  }
}

class _CategoryDisk extends StatelessWidget {
  const _CategoryDisk({
    required this.category,
    required this.color,
    required this.diskSize,
  });

  final CategoryTotal category;
  final Color color;
  final double diskSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LiquidCategoryDisk(
          amountLabel: formatCurrency(category.amount),
          progress: category.percent,
          color: color,
          size: diskSize,
        ),
        const SizedBox(height: 8),
        Text(
          category.category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted(context),
        ),
      ],
    );
  }
}

class _TrendPanel extends StatefulWidget {
  const _TrendPanel({
    required this.period,
    required this.expenseRecords,
    required this.range,
    required this.now,
  });

  final _StatisticsPeriod period;
  final List<LedgerRecord> expenseRecords;
  final _DateRange range;
  final DateTime now;

  @override
  State<_TrendPanel> createState() => _TrendPanelState();
}

class _TrendPanelState extends State<_TrendPanel> {
  final ScrollController _scrollController = ScrollController();
  String? _lastAutoScrollToken;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buckets = _trendBucketsForPeriod(
      period: widget.period,
      expenseRecords: widget.expenseRecords,
      range: widget.range,
      now: widget.now,
    );
    final maxAmount = buckets.fold<double>(
      0,
      (max, bucket) => math.max(max, bucket.amount),
    );
    final barColor = context.colors.primary;

    if (buckets.isEmpty || maxAmount == 0) {
      return const _EmptyStatsPanel(
        icon: Icons.bar_chart_outlined,
        title: '暂无趋势数据',
        subtitle: '添加支出记录后会显示趋势',
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: AppDecorations.surface(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final neededWidth =
              buckets.length * _trendBarItemWidth +
              math.max(0, buckets.length - 1) * _trendBarMinSpacing;
          final contentWidth = math.max(neededWidth, constraints.maxWidth);
          final spacing = buckets.length <= 1
              ? 0.0
              : (contentWidth - buckets.length * _trendBarItemWidth) /
                    (buckets.length - 1);
          final canScroll = neededWidth > constraints.maxWidth;
          final firstDataIndex = buckets.indexWhere(
            (bucket) => bucket.amount > 0,
          );
          final targetIndex = firstDataIndex == -1 ? 0 : firstDataIndex;
          _scheduleAutoScroll(
            canScroll: canScroll,
            targetIndex: targetIndex,
            itemExtent: _trendBarItemWidth + spacing,
            token:
                '${widget.period.index}-${buckets.length}-$targetIndex-${canScroll ? 1 : 0}',
          );

          return ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: canScroll
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: contentWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var index = 0; index < buckets.length; index++) ...[
                      SizedBox(
                        width: _trendBarItemWidth,
                        child: _TrendBar(
                          label: buckets[index].label,
                          amount: buckets[index].amount,
                          maxAmount: maxAmount,
                          color: barColor,
                        ),
                      ),
                      if (index != buckets.length - 1) SizedBox(width: spacing),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _scheduleAutoScroll({
    required bool canScroll,
    required int targetIndex,
    required double itemExtent,
    required String token,
  }) {
    if (_lastAutoScrollToken == token) {
      return;
    }
    _lastAutoScrollToken = token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final targetOffset = canScroll ? itemExtent * targetIndex : 0.0;
      final maxOffset = _scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxOffset);
      _scrollController.jumpTo(clampedOffset);
    });
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.label,
    required this.amount,
    required this.maxAmount,
    required this.color,
  });

  final String label;
  final double amount;
  final double maxAmount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final active = amount == maxAmount && amount > 0;
    final height = 18 + (amount / maxAmount * 104);
    final baseColor = active ? color : color.withValues(alpha: 0.42);
    final trackColor = Color.alphaBlend(
      color.withValues(alpha: active ? 0.16 : 0.10),
      context.colors.surface,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 16,
          height: height,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 16,
                height: height,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: AppRadii.card,
                ),
              ),
              if (amount > 0)
                Container(
                  width: 16,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.card,
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        liquidCategoryShade(baseColor, -0.08),
                        baseColor,
                        liquidCategoryShade(baseColor, 0.14),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: baseColor.withValues(alpha: 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: AppRadii.card,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        liquidCategoryShade(baseColor, 0.2).withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMuted(context).copyWith(
            color: active ? context.colors.primary : null,
            fontWeight: active ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}

class _EmptyStatsPanel extends StatelessWidget {
  const _EmptyStatsPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.surface(context),
      child: Column(
        children: [
          Icon(icon, color: colors.primary, size: 30),
          const SizedBox(height: 10),
          Text(title, style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.bodyMuted(context)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.sectionTitle(context));
  }
}

enum _StatisticsPeriod { week, month, year }

class _DateRange {
  const _DateRange({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;
}

String _periodLabel(_StatisticsPeriod period) {
  switch (period) {
    case _StatisticsPeriod.week:
      return '本周';
    case _StatisticsPeriod.month:
      return '本月';
    case _StatisticsPeriod.year:
      return '本年';
  }
}

String _formatPeriodRangeText(_DateRange range, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final rangeEnd = range.endExclusive.subtract(const Duration(days: 1));
  final displayEnd = today.isBefore(rangeEnd) ? today : rangeEnd;
  return '${_formatDate(range.start)} - ${_formatDate(displayEnd)}';
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

_DateRange _periodRangeFor(_StatisticsPeriod period, DateTime now) {
  final dayStart = DateTime(now.year, now.month, now.day);

  switch (period) {
    case _StatisticsPeriod.week:
      final weekStart = dayStart.subtract(Duration(days: dayStart.weekday - 1));
      return _DateRange(
        start: weekStart,
        endExclusive: weekStart.add(const Duration(days: 7)),
      );
    case _StatisticsPeriod.month:
      final monthStart = DateTime(now.year, now.month, 1);
      return _DateRange(
        start: monthStart,
        endExclusive: DateTime(now.year, now.month + 1, 1),
      );
    case _StatisticsPeriod.year:
      final yearStart = DateTime(now.year, 1, 1);
      return _DateRange(
        start: yearStart,
        endExclusive: DateTime(now.year + 1, 1, 1),
      );
  }
}

int _elapsedDaysForPeriod(_StatisticsPeriod period, DateTime now) {
  switch (period) {
    case _StatisticsPeriod.week:
      return now.weekday;
    case _StatisticsPeriod.month:
      return now.day;
    case _StatisticsPeriod.year:
      return now.difference(DateTime(now.year, 1, 1)).inDays + 1;
  }
}

List<LedgerRecord> _expenseRecordsInRange(
  List<LedgerRecord> records,
  _DateRange range,
) {
  return records.where((record) {
    return record.type == LedgerRecordType.expense &&
        !record.createdAt.isBefore(range.start) &&
        record.createdAt.isBefore(range.endExclusive);
  }).toList();
}

LedgerRecord? _largestExpense(List<LedgerRecord> expenseRecords) {
  if (expenseRecords.isEmpty) {
    return null;
  }
  return expenseRecords.reduce(
    (largest, record) => record.amount > largest.amount ? record : largest,
  );
}

List<CategoryTotal> _categoryTotalsForRecords(
  List<LedgerRecord> expenseRecords,
) {
  final totals = <String, double>{};
  for (final record in expenseRecords) {
    totals.update(
      record.category,
      (value) => value + record.amount,
      ifAbsent: () => record.amount,
    );
  }

  final totalExpense = totals.values.fold<double>(0, (sum, item) => sum + item);
  return totals.entries.map((entry) {
    final percent = totalExpense == 0 ? 0.0 : entry.value / totalExpense;
    return CategoryTotal(
      category: entry.key,
      amount: entry.value,
      percent: percent,
    );
  }).toList()..sort((a, b) => b.amount.compareTo(a.amount));
}

List<_TrendBucket> _trendBucketsForPeriod({
  required _StatisticsPeriod period,
  required List<LedgerRecord> expenseRecords,
  required _DateRange range,
  required DateTime now,
}) {
  switch (period) {
    case _StatisticsPeriod.week:
      return _weeklyTrendBuckets(expenseRecords, range, now);
    case _StatisticsPeriod.month:
      return _monthlyTrendBuckets(expenseRecords, range, now);
    case _StatisticsPeriod.year:
      return _yearlyTrendBuckets(expenseRecords, now);
  }
}

Map<DateTime, double> _dailyTotalsMap(List<LedgerRecord> expenseRecords) {
  final totalsByDay = <DateTime, double>{};
  for (final record in expenseRecords) {
    final day = DateTime(
      record.createdAt.year,
      record.createdAt.month,
      record.createdAt.day,
    );
    totalsByDay.update(
      day,
      (value) => value + record.amount,
      ifAbsent: () => record.amount,
    );
  }
  return totalsByDay;
}

List<_TrendBucket> _weeklyTrendBuckets(
  List<LedgerRecord> expenseRecords,
  _DateRange range,
  DateTime now,
) {
  final totalsByDay = _dailyTotalsMap(expenseRecords);
  final today = DateTime(now.year, now.month, now.day);

  final buckets = <_TrendBucket>[];
  for (
    var day = range.start;
    day.isBefore(range.endExclusive);
    day = day.add(const Duration(days: 1))
  ) {
    final amount = totalsByDay[day] ?? 0;
    buckets.add(
      _TrendBucket(
        label: '${day.weekday}',
        summaryLabel: '${day.month}月${day.day}日',
        amount: amount,
        isToday: day == today,
      ),
    );
  }

  return buckets;
}

List<_TrendBucket> _monthlyTrendBuckets(
  List<LedgerRecord> expenseRecords,
  _DateRange range,
  DateTime now,
) {
  final totalsByDay = _dailyTotalsMap(expenseRecords);
  final daysInMonth = range.endExclusive.difference(range.start).inDays;
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(daysInMonth, (index) => index + 1).map((day) {
    final date = DateTime(range.start.year, range.start.month, day);
    return _TrendBucket(
      label: '$day日',
      summaryLabel: '${date.month}月$day日',
      amount: totalsByDay[date] ?? 0,
      isToday: date == today,
    );
  }).toList();
}

List<_TrendBucket> _yearlyTrendBuckets(
  List<LedgerRecord> expenseRecords,
  DateTime now,
) {
  final monthlyTotals = List<double>.filled(12, 0);

  for (final record in expenseRecords) {
    monthlyTotals[record.createdAt.month - 1] += record.amount;
  }

  final currentMonth = now.month;
  return [
    for (var index = 0; index < monthlyTotals.length; index++)
      _TrendBucket(
        label: '${index + 1}月',
        summaryLabel: '${index + 1}月',
        amount: monthlyTotals[index],
        isToday: index + 1 == currentMonth,
      ),
  ];
}

class _TrendBucket {
  const _TrendBucket({
    required this.label,
    required this.summaryLabel,
    required this.amount,
    required this.isToday,
  });

  final String label;
  final String summaryLabel;
  final double amount;
  final bool isToday;
}

const double _trendBarItemWidth = 34;
const double _trendBarMinSpacing = 8;
