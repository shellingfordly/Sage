import 'package:flutter/material.dart';

import '../../../models/ledger_record.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/ledger_formatters.dart';

class ChartsTotalCard extends StatelessWidget {
  const ChartsTotalCard({
    super.key,
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

class ChartsSummaryGrid extends StatelessWidget {
  const ChartsSummaryGrid({
    super.key,
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
