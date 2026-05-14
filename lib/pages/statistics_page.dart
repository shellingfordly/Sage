import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/ledger_store.dart';
import '../models/ledger_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/app_text_styles.dart';
import '../utils/ledger_formatters.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ledgerStore,
      builder: (context, child) {
        final now = DateTime.now();
        final expense = ledgerStore.expenseForMonth(now);
        final dailyAverage = expense / _elapsedDaysForMonth(now);
        final largestExpense = ledgerStore.largestExpenseForMonth(now);
        final categories = ledgerStore.expenseCategoryTotalsForMonth(now);
        final dailyTotals = ledgerStore.dailyExpenseTotalsForMonth(now);

        return SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StatisticsHeader(),
                const SizedBox(height: 20),
                const _PeriodTabs(),
                const SizedBox(height: 18),
                _TotalCard(
                  totalExpense: expense,
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
                const _SectionTitle(title: '本月趋势'),
                const SizedBox(height: 12),
                _TrendPanel(dailyTotals: dailyTotals),
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
        Text('按月查看你的钱都流向哪里', style: AppTextStyles.pageSubtitle(context)),
      ],
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _PeriodChip(label: '本月', selected: true),
        SizedBox(width: 8),
        _PeriodChip(label: '本周'),
        SizedBox(width: 8),
        _PeriodChip(label: '本年'),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
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
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalExpense, required this.topCategory});

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
          Text('本月总支出', style: AppTextStyles.cardLabel(context)),
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
            style: AppTextStyles.labelMuted(context),
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

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.categories});

  final List<CategoryTotal> categories;

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
    final rowColors = [colors.primary, colors.danger, colors.info];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(context),
      child: Column(
        children: [
          for (var index = 0; index < categories.take(5).length; index++) ...[
            _CategoryRow(
              category: categories[index],
              color: rowColors[index % rowColors.length],
            ),
            if (index != math.min(categories.length, 5) - 1)
              const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.color});

  final CategoryTotal category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: AppDecorations.softFill(context),
          child: Icon(
            iconForCategory(category.category, LedgerRecordType.expense),
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatCurrency(category.amount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textBody,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: AppRadii.progress,
                child: LinearProgressIndicator(
                  value: category.percent.clamp(0, 1),
                  minHeight: 7,
                  color: color,
                  backgroundColor: colors.divider,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendPanel extends StatelessWidget {
  const _TrendPanel({required this.dailyTotals});

  final List<DailyExpenseTotal> dailyTotals;

  @override
  Widget build(BuildContext context) {
    final buckets = _bucketDailyTotals(dailyTotals);
    final maxAmount = buckets.fold<double>(
      0,
      (max, bucket) => math.max(max, bucket.amount),
    );

    if (maxAmount == 0) {
      return const _EmptyStatsPanel(
        icon: Icons.bar_chart_outlined,
        title: '暂无趋势数据',
        subtitle: '添加支出记录后会显示本月趋势',
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: AppDecorations.surface(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bucket in buckets)
            _TrendBar(
              label: bucket.label,
              amount: bucket.amount,
              maxAmount: maxAmount,
            ),
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.label,
    required this.amount,
    required this.maxAmount,
  });

  final String label;
  final double amount;
  final double maxAmount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = amount == maxAmount;
    final height = 18 + (amount / maxAmount * 104);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 16,
            height: height,
            decoration: BoxDecoration(
              color: active ? colors.primary : colors.primarySoft,
              borderRadius: AppRadii.card,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.bodyMuted(context)),
        ],
      ),
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

int _elapsedDaysForMonth(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month) {
    return now.day;
  }
  return DateTime(date.year, date.month + 1, 0).day;
}

List<_TrendBucket> _bucketDailyTotals(List<DailyExpenseTotal> dailyTotals) {
  if (dailyTotals.isEmpty) {
    return [];
  }

  const bucketCount = 7;
  final bucketSize = (dailyTotals.length / bucketCount).ceil();
  final buckets = <_TrendBucket>[];

  for (var index = 0; index < bucketCount; index++) {
    final start = index * bucketSize;
    if (start >= dailyTotals.length) {
      break;
    }

    final end = math.min(start + bucketSize, dailyTotals.length);
    final amount = dailyTotals
        .sublist(start, end)
        .fold<double>(0, (sum, day) => sum + day.amount);
    buckets.add(
      _TrendBucket(label: dailyTotals[start].day.toString(), amount: amount),
    );
  }

  return buckets;
}

class _TrendBucket {
  const _TrendBucket({required this.label, required this.amount});

  final String label;
  final double amount;
}
