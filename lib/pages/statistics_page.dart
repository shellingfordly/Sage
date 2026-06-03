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
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  DateTime _anchorDate(DateTime today) => switch (_selectedPeriod) {
    _StatisticsPeriod.year => DateTime(_selectedYear, 1, 1),
    _StatisticsPeriod.month => DateTime(_selectedYear, _selectedMonth, 1),
  };

  void _onYearSelected(int year, DateTime today) {
    setState(() {
      _selectedYear = year;
      if (year == today.year && _selectedMonth > today.month) {
        _selectedMonth = today.month;
      }
    });
  }

  void _onMonthSelected(int month) {
    setState(() => _selectedMonth = month);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ledgerStore,
      builder: (context, child) {
        final today = DateTime.now();
        final anchor = _anchorDate(today);
        final range = _periodRangeFor(_selectedPeriod, anchor);
        final expenseRecords = _expenseRecordsInRange(
          ledgerStore.records,
          range,
        );
        final totalExpense = expenseRecords.fold<double>(
          0,
          (sum, record) => sum + record.amount,
        );
        final isCurrentPeriod = _isCurrentPeriod(
          _selectedPeriod,
          anchor,
          today,
        );
        final elapsedDays = _elapsedDaysForPeriod(
          _selectedPeriod,
          anchor,
          today,
        );
        final dailyAverage = elapsedDays == 0
            ? 0.0
            : totalExpense / elapsedDays;
        final largestExpense = _largestExpense(expenseRecords);
        final categories = _categoryTotalsForRecords(expenseRecords);
        final periodLabel = _periodLabel(
          _selectedPeriod,
          anchor,
          today,
        );
        final firstYear = _statisticsFirstYear(today);
        final periodRangeText = _formatPeriodRangeText(
          range,
          today,
          isCurrentPeriod: isCurrentPeriod,
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StatisticsHeader(),
                const SizedBox(height: 20),
                _StatisticsPeriodPanel(
                  selectedPeriod: _selectedPeriod,
                  selectedYear: _selectedYear,
                  selectedMonth: _selectedMonth,
                  firstYear: firstYear,
                  lastYear: today.year,
                  currentMonth: today.month,
                  periodRangeText: periodRangeText,
                  onPeriodSelected: (period) {
                    if (period == _selectedPeriod) {
                      return;
                    }
                    setState(() {
                      _selectedPeriod = period;
                      if (period == _StatisticsPeriod.month &&
                          _selectedYear == today.year &&
                          _selectedMonth > today.month) {
                        _selectedMonth = today.month;
                      }
                    });
                  },
                  onYearSelected: (year) => _onYearSelected(year, today),
                  onMonthSelected: _onMonthSelected,
                ),
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
                  anchor: anchor,
                  today: today,
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
        Text('按月可选年份与月份，按年查看全年', style: AppTextStyles.pageSubtitle(context)),
      ],
    );
  }
}

class _StatisticsPeriodPanel extends StatelessWidget {
  const _StatisticsPeriodPanel({
    required this.selectedPeriod,
    required this.selectedYear,
    required this.selectedMonth,
    required this.firstYear,
    required this.lastYear,
    required this.currentMonth,
    required this.periodRangeText,
    required this.onPeriodSelected,
    required this.onYearSelected,
    required this.onMonthSelected,
  });

  final _StatisticsPeriod selectedPeriod;
  final int selectedYear;
  final int selectedMonth;
  final int firstYear;
  final int lastYear;
  final int currentMonth;
  final String periodRangeText;
  final ValueChanged<_StatisticsPeriod> onPeriodSelected;
  final ValueChanged<int> onYearSelected;
  final ValueChanged<int> onMonthSelected;

  List<int> _visibleMonths() {
    final lastMonth = selectedYear < lastYear ? 12 : currentMonth;
    return [for (var month = 1; month <= lastMonth; month++) month];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final years = [for (var y = firstYear; y <= lastYear; y++) y];
    final visibleMonths = _visibleMonths();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: _PeriodSegmentedControl(
              selectedPeriod: selectedPeriod,
              onSelected: onPeriodSelected,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colors.surfaceBorder.withValues(alpha: 0.65),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: selectedPeriod == _StatisticsPeriod.year
                ? _HorizontalChipStrip(
                    selectedIndex: selectedYear - firstYear,
                    itemStride: 56,
                    onSelected: (index) => onYearSelected(years[index]),
                    items: [
                      for (final year in years)
                        _StripChipItem(label: '$year', enabled: true),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HorizontalChipStrip(
                        selectedIndex: selectedYear - firstYear,
                        itemStride: 56,
                        onSelected: (index) => onYearSelected(years[index]),
                        items: [
                          for (final year in years)
                            _StripChipItem(label: '$year', enabled: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _HorizontalChipStrip(
                        selectedIndex: math.max(
                          0,
                          visibleMonths.indexOf(selectedMonth),
                        ),
                        itemStride: 46,
                        onSelected: (index) =>
                            onMonthSelected(visibleMonths[index]),
                        items: [
                          for (final month in visibleMonths)
                            _StripChipItem(label: '$month月', enabled: true),
                        ],
                      ),
                    ],
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                colors.primary.withValues(alpha: 0.08),
                colors.surface,
              ),
              border: Border(
                top: BorderSide(
                  color: colors.surfaceBorder.withValues(alpha: 0.55),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: colors.primary.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    periodRangeText,
                    style: AppTextStyles.bodyMuted(context).copyWith(
                      color: colors.textBody,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSegmentedControl extends StatelessWidget {
  const _PeriodSegmentedControl({
    required this.selectedPeriod,
    required this.onSelected,
  });

  final _StatisticsPeriod selectedPeriod;
  final ValueChanged<_StatisticsPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.softFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.surfaceBorder.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PeriodSegment(
              label: '按月',
              selected: selectedPeriod == _StatisticsPeriod.month,
              onTap: () => onSelected(_StatisticsPeriod.month),
            ),
          ),
          Expanded(
            child: _PeriodSegment(
              label: '按年',
              selected: selectedPeriod == _StatisticsPeriod.year,
              onTap: () => onSelected(_StatisticsPeriod.year),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.chip(context, selected: selected).copyWith(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _StripChipItem {
  const _StripChipItem({required this.label, required this.enabled});

  final String label;
  final bool enabled;
}

class _HorizontalChipStrip extends StatefulWidget {
  const _HorizontalChipStrip({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.itemStride,
  });

  final List<_StripChipItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double itemStride;

  @override
  State<_HorizontalChipStrip> createState() => _HorizontalChipStripState();
}

class _HorizontalChipStripState extends State<_HorizontalChipStrip> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(_HorizontalChipStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!_controller.hasClients || widget.items.isEmpty) {
      return;
    }
    final index = widget.selectedIndex.clamp(0, widget.items.length - 1);
    final offset = math.max(0.0, index * widget.itemStride - widget.itemStride);
    _controller.animateTo(
      offset.clamp(0.0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 30,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          itemCount: widget.items.length,
          separatorBuilder: (context, index) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final selected = index == widget.selectedIndex;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: item.enabled ? () => widget.onSelected(index) : null,
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary
                        : item.enabled
                        ? colors.primarySoft.withValues(alpha: 0.45)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected
                          ? colors.primary
                          : item.enabled
                          ? colors.surfaceBorder.withValues(alpha: 0.85)
                          : colors.surfaceBorder.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    item.label,
                    style: AppTextStyles.chip(context, selected: selected)
                        .copyWith(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: item.enabled
                              ? null
                              : colors.textSecondary.withValues(alpha: 0.45),
                        ),
                  ),
                ),
              ),
            );
          },
        ),
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
    required this.anchor,
    required this.today,
  });

  final _StatisticsPeriod period;
  final List<LedgerRecord> expenseRecords;
  final _DateRange range;
  final DateTime anchor;
  final DateTime today;

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
      anchor: widget.anchor,
      today: widget.today,
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

enum _StatisticsPeriod { month, year }

class _DateRange {
  const _DateRange({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;
}

bool _isCurrentPeriod(
  _StatisticsPeriod period,
  DateTime anchor,
  DateTime today,
) {
  switch (period) {
    case _StatisticsPeriod.month:
      return anchor.year == today.year && anchor.month == today.month;
    case _StatisticsPeriod.year:
      return anchor.year == today.year;
  }
}

String _periodLabel(
  _StatisticsPeriod period,
  DateTime anchor,
  DateTime today,
) {
  if (_isCurrentPeriod(period, anchor, today)) {
    return switch (period) {
      _StatisticsPeriod.month => '本月',
      _StatisticsPeriod.year => '本年',
    };
  }
  return switch (period) {
    _StatisticsPeriod.month => anchor.year == today.year
        ? '${anchor.month}月'
        : '${anchor.year}年${anchor.month}月',
    _StatisticsPeriod.year => '${anchor.year}年',
  };
}

int _statisticsFirstYear(DateTime today) {
  var firstYear = today.year;
  for (final record in ledgerStore.records) {
    if (record.createdAt.year < firstYear) {
      firstYear = record.createdAt.year;
    }
  }
  return firstYear;
}

String _formatPeriodRangeText(
  _DateRange range,
  DateTime today, {
  required bool isCurrentPeriod,
}) {
  final todayDate = DateTime(today.year, today.month, today.day);
  final rangeEnd = range.endExclusive.subtract(const Duration(days: 1));
  final displayEnd =
      isCurrentPeriod && todayDate.isBefore(rangeEnd) ? todayDate : rangeEnd;
  return '${_formatDate(range.start)} - ${_formatDate(displayEnd)}';
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

_DateRange _periodRangeFor(_StatisticsPeriod period, DateTime anchor) {
  switch (period) {
    case _StatisticsPeriod.month:
      final monthStartDate = DateTime(anchor.year, anchor.month, 1);
      return _DateRange(
        start: monthStartDate,
        endExclusive: DateTime(anchor.year, anchor.month + 1, 1),
      );
    case _StatisticsPeriod.year:
      final yearStart = DateTime(anchor.year, 1, 1);
      return _DateRange(
        start: yearStart,
        endExclusive: DateTime(anchor.year + 1, 1, 1),
      );
  }
}

int _elapsedDaysForPeriod(
  _StatisticsPeriod period,
  DateTime anchor,
  DateTime today,
) {
  final range = _periodRangeFor(period, anchor);
  if (!_isCurrentPeriod(period, anchor, today)) {
    return range.endExclusive.difference(range.start).inDays;
  }

  switch (period) {
    case _StatisticsPeriod.month:
      return today.day;
    case _StatisticsPeriod.year:
      return today.difference(DateTime(today.year, 1, 1)).inDays + 1;
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
  required DateTime anchor,
  required DateTime today,
}) {
  switch (period) {
    case _StatisticsPeriod.month:
      return _monthlyTrendBuckets(expenseRecords, range, today);
    case _StatisticsPeriod.year:
      return _yearlyTrendBuckets(expenseRecords, anchor, today);
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
  DateTime anchor,
  DateTime today,
) {
  final monthlyTotals = List<double>.filled(12, 0);

  for (final record in expenseRecords) {
    monthlyTotals[record.createdAt.month - 1] += record.amount;
  }

  final highlightMonth = anchor.year == today.year ? today.month : null;
  return [
    for (var index = 0; index < monthlyTotals.length; index++)
      _TrendBucket(
        label: '${index + 1}月',
        summaryLabel: '${index + 1}月',
        amount: monthlyTotals[index],
        isToday: highlightMonth != null && index + 1 == highlightMonth,
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
