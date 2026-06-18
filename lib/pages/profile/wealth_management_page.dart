import 'package:flutter/material.dart';

import '../../components/sheets/record_detail_sheet.dart';
import '../../data/ledger_store.dart';
import '../../models/ledger_record.dart';
import '../../services/wealth/wealth_analyzer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/ledger_formatters.dart';
import '../add_record_page.dart';

const _wealthAnalyzer = WealthAnalyzer();

class WealthManagementPage extends StatefulWidget {
  const WealthManagementPage({super.key});

  @override
  State<WealthManagementPage> createState() => _WealthManagementPageState();
}

class _WealthManagementPageState extends State<WealthManagementPage> {
  final _monthlyTargetController = TextEditingController();
  final _yearlyTargetController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _syncTargetsFromStore();
  }

  @override
  void dispose() {
    _monthlyTargetController.dispose();
    _yearlyTargetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('理财管理'),
        actions: [
          TextButton.icon(
            onPressed: _saving
                ? null
                : () => openAddRecordPage(
                      context,
                      initialType: LedgerRecordType.wealth,
                    ),
            icon: const Icon(Icons.add),
            label: const Text('记一笔'),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: ledgerStore,
          builder: (context, child) {
            final summary = _wealthAnalyzer.analyze(
              records: ledgerStore.records,
              monthlyTarget: ledgerStore.wealthMonthlyTarget(),
              yearlyTarget: ledgerStore.wealthYearlyTarget(),
            );

            return SingleChildScrollView(
              padding: AppSpacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryGrid(summary: summary),
                  const SizedBox(height: 16),
                  _TargetEditor(
                    monthlyController: _monthlyTargetController,
                    yearlyController: _yearlyTargetController,
                    saving: _saving,
                    onSave: _saveTargets,
                  ),
                  const SizedBox(height: 20),
                  Text('本年存入趋势', style: AppTextStyles.sectionTitle(context)),
                  const SizedBox(height: 10),
                  _MonthlyTrendChart(trend: summary.monthlyTrend),
                  if (summary.upcomingItems.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('即将到期', style: AppTextStyles.sectionTitle(context)),
                    const SizedBox(height: 10),
                    for (final item in summary.upcomingItems)
                      _MaturityCard(item: item),
                  ],
                  const SizedBox(height: 20),
                  Text('理财记录', style: AppTextStyles.sectionTitle(context)),
                  const SizedBox(height: 10),
                  _WealthRecordList(records: ledgerStore.wealthRecords()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _syncTargetsFromStore() {
    final monthly = ledgerStore.wealthMonthlyTarget();
    final yearly = ledgerStore.wealthYearlyTarget();
    _monthlyTargetController.text =
        monthly > 0 ? monthly.toStringAsFixed(2) : '';
    _yearlyTargetController.text = yearly > 0 ? yearly.toStringAsFixed(2) : '';
  }

  Future<void> _saveTargets() async {
    setState(() => _saving = true);
    final monthly = double.tryParse(_monthlyTargetController.text.trim()) ?? 0;
    final yearly = double.tryParse(_yearlyTargetController.text.trim()) ?? 0;
    await ledgerStore.setWealthMonthlyTarget(amount: monthly);
    await ledgerStore.setWealthYearlyTarget(amount: yearly);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('理财目标已保存')),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final WealthSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: '理财本金合计',
                value: formatCurrency(summary.principalTotal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: '预估利息合计',
                value: formatCurrency(summary.projectedInterestTotal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: '本月存入',
                value: formatCurrency(summary.monthNet, signed: true),
                subtitle: summary.monthlyTarget > 0
                    ? '目标 ${formatCurrency(summary.monthlyTarget)}'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: '本年存入',
                value: formatCurrency(summary.yearNet, signed: true),
                subtitle: summary.yearlyTarget > 0
                    ? '目标 ${formatCurrency(summary.yearlyTarget)}'
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyMuted(context)),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.tileValue(context)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTextStyles.bodyMuted(context)),
          ],
        ],
      ),
    );
  }
}

class _TargetEditor extends StatelessWidget {
  const _TargetEditor({
    required this.monthlyController,
    required this.yearlyController,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController monthlyController;
  final TextEditingController yearlyController;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('存入目标', style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 4),
          Text(
            '设置通用的每月与每年存入目标，用于对比当前进度。',
            style: AppTextStyles.bodyMuted(context),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: monthlyController,
            enabled: !saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '每月目标',
              prefixText: '¥ ',
              border: OutlineInputBorder(borderRadius: AppRadii.card),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: yearlyController,
            enabled: !saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '每年目标',
              prefixText: '¥ ',
              border: OutlineInputBorder(borderRadius: AppRadii.card),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: saving ? null : onSave,
            child: Text(saving ? '保存中...' : '保存目标'),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.trend});

  final List<WealthMonthTotal> trend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxAmount = trend.fold<double>(
      0,
      (max, item) => item.netAmount.abs() > max ? item.netAmount.abs() : max,
    );

    return Container(
      height: 210,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: AppDecorations.surface(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final item in trend)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      formatCompactCurrency(item.netAmount, signed: true),
                      style: AppTextStyles.bodyMuted(context).copyWith(
                        fontSize: 9,
                        color: item.netAmount >= 0
                            ? colors.primary
                            : colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (maxAmount > 0)
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: (item.netAmount.abs() / maxAmount)
                              .clamp(0.05, 1.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(
                                alpha: item.netAmount >= 0 ? 0.85 : 0.35,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 4),
                    const SizedBox(height: 6),
                    Text(
                      '${item.month.month}',
                      style: AppTextStyles.bodyMuted(context).copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MaturityCard extends StatelessWidget {
  const _MaturityCard({required this.item});

  final WealthMaturityItem item;

  @override
  Widget build(BuildContext context) {
    final record = item.record;
    final maturity = record.wealthMeta.maturityDate!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(record.title, style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 4),
          Text(
            '${ledgerStore.categoryLabelForRecord(record)} · 本金 ${formatCurrency(record.amount)}',
            style: AppTextStyles.bodyMuted(context),
          ),
          const SizedBox(height: 4),
          Text(
            '到期 ${maturity.year}/${maturity.month}/${maturity.day} · '
            '预估利息 ${formatCurrency(item.projectedInterest)} · '
            '${item.daysUntilMaturity} 天后',
            style: AppTextStyles.bodyMuted(context),
          ),
          if (record.wealthMeta.remindOnMaturity)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '已标记到期提醒（应用内）',
                style: AppTextStyles.bodyMuted(context).copyWith(
                  color: context.colors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WealthRecordList extends StatelessWidget {
  const _WealthRecordList({required this.records});

  final List<LedgerRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: AppDecorations.surface(context),
        child: Text(
          '暂无理财记录，可点击右上角「记一笔」添加。',
          style: AppTextStyles.bodyMuted(context),
        ),
      );
    }

    return Column(
      children: [
        for (final record in records)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: AppDecorations.surface(context),
            child: ListTile(
              onTap: () => showRecordDetailSheet(context, record: record),
              leading: Container(
                width: 36,
                height: 36,
                decoration: AppDecorations.softFill(context),
                child: Icon(
                  ledgerStore.categoryIconFor(record.category, record.type),
                  size: 18,
                  color: context.colors.textBody,
                ),
              ),
              title: Text(record.title),
              subtitle: Text(
                '${ledgerStore.categoryLabelForRecord(record)} · ${formatRecordDate(record.createdAt)}'
                '${record.wealthMeta.hasRate ? ' · 年利率 ${record.wealthMeta.annualRate!.toStringAsFixed(2)}%' : ''}',
              ),
              trailing: Text(
                formatRecordAmount(record),
                style: AppTextStyles.bodyStrong(context).copyWith(
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
