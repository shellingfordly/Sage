import 'package:flutter/material.dart';

import '../../../data/ledger_store.dart';
import '../../../models/ledger_record.dart';
import '../../profile/budget_management_page.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/ledger_formatters.dart';
import '../../../utils/record_import_parser.dart';
import '../../../models/ai_insight_scope.dart';
import '../../../models/ai_insight_models.dart';
import '../../analysis/analysis_navigation.dart';
import '../../../services/ai/ai_budget_apply_service.dart';

const _budgetApplyService = AiBudgetApplyService();

class AiInsightSection extends StatelessWidget {
  const AiInsightSection({
    super.key,
    required this.snapshot,
    this.scope,
  });

  final AiInsightSnapshot snapshot;
  final AiInsightScope? scope;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (snapshot.headlines.isNotEmpty) ...[
          _HeadlinePanel(headlines: snapshot.headlines),
          const SizedBox(height: 12),
        ],
        _ComparisonPanel(comparison: snapshot.comparison, scope: scope),
        const SizedBox(height: 10),
        if (snapshot.comparison.categoryChanges.isNotEmpty) ...[
          _CategoryShiftPanel(changes: snapshot.comparison.categoryChanges, scope: scope),
          const SizedBox(height: 10),
        ],
        if (snapshot.monthlyVolatility.hasMultiMonthData) ...[
          _MonthlyVolatilityPanel(
            volatility: snapshot.monthlyVolatility,
            scope: scope,
          ),
          const SizedBox(height: 10),
        ],
        _MetricsPanel(snapshot: snapshot, scope: scope),
        const SizedBox(height: 10),
        _NotablePanel(snapshot: snapshot, scope: scope),
        if (_canApplySuggestion(scope)) ...[
          const SizedBox(height: 10),
          _NextMonthBudgetPanel(
            snapshot: snapshot,
            onApplyTotal: (context) => _applySuggestionToNextMonth(context),
            onGoBudgetManagement: (context) => _goBudgetManagement(context),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  bool _canApplySuggestion(AiInsightScope? scope) {
    if (scope == null || !scope.supportsBudgetApply) {
      return false;
    }
    return snapshot.budgetSuggestion.actionable &&
        snapshot.budgetSuggestion.byCategory.isNotEmpty;
  }

  DateTime _budgetApplyReference() {
    return scope?.referenceDate(DateTime.now()) ?? DateTime.now();
  }

  Future<void> _goBudgetManagement(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const BudgetManagementPage(),
      ),
    );
  }

  Future<void> _applySuggestionToNextMonth(BuildContext context) async {
    final shouldApply = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('应用预算建议'),
        content: Text(
          '将建议预算 ${formatCurrency(snapshot.budgetSuggestion.totalSuggested)} 应用到下月预算？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('应用'),
          ),
        ],
      ),
    );
    if (shouldApply != true) {
      return;
    }
    final applied = await _budgetApplyService.applySuggestionToNextMonth(
      suggestedBudget: snapshot.budgetSuggestion.totalSuggested,
      now: _budgetApplyReference(),
      onApply: ({required month, required amount}) async {
        await ledgerStore.setMonthlyBudget(month: month, amount: amount);
      },
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(applied ? '已应用到下月预算' : '建议预算无效，未执行应用')),
    );
  }
}

AnalysisDrillDown? insightDrillDown(
  AiInsightScope? scope, {
  DateTime? start,
  DateTime? end,
  String? category,
  String? searchQuery,
}) {
  if (scope == null) {
    return null;
  }
  return AnalysisDrillDown(
    dateRange: drillDownRange(
      start: start ?? scope.start,
      end: end ?? scope.end,
    ),
    category: category,
    searchQuery: searchQuery,
    consumptionOnly: true,
  );
}

String? anomalySearchQuery(AiAnomalyItem item) {
  if (item.records.isEmpty || item.records.length > 3) {
    return null;
  }
  final title = item.title.trim();
  if (title.isEmpty) {
    return null;
  }
  return title;
}

AnalysisDrillDown? _peakMonthDrillDown(
  AiInsightScope? scope,
  DateTime month, {
  String? category,
}) {
  final range = monthDrillDownRange(month);
  return insightDrillDown(
    scope,
    start: range.start,
    end: range.end,
    category: category,
  );
}

class _DrillDownLink extends StatelessWidget {
  const _DrillDownLink({
    required this.label,
    required this.drillDown,
  });

  final String label;
  final AnalysisDrillDown drillDown;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => navigateToAnalysisDrillDown(context, drillDown),
        child: Text(
          label,
          style: AppTextStyles.bodyMuted(context).copyWith(
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }
}

class _HeadlinePanel extends StatelessWidget {
  const _HeadlinePanel({required this.headlines});

  final List<FinanceHeadline> headlines;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text('核心结论', style: AppTextStyles.bodyStrong(context)),
            ],
          ),
          const SizedBox(height: 10),
          for (final headline in headlines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: AppTextStyles.bodyStrong(context)),
                  Expanded(
                    child: Text(
                      headline.text,
                      style: AppTextStyles.bodyMuted(context).copyWith(
                        color: colors.textPrimary,
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

class _ComparisonPanel extends StatelessWidget {
  const _ComparisonPanel({required this.comparison, this.scope});

  final FinanceComparisonInsight comparison;
  final AiInsightScope? scope;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasPrevious = comparison.previousExpense > 0;
    final changePercent =
        (comparison.changePercent * 100).abs().toStringAsFixed(0);
    final direction = comparison.changeAmount >= 0 ? '增加' : '减少';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('时段对比', style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: '消费支出',
                  value: formatCurrency(comparison.currentExpense),
                ),
              ),
              if (hasPrevious)
                Expanded(
                  child: _MetricTile(
                    label: '上一时段',
                    value: formatCurrency(comparison.previousExpense),
                  ),
                ),
            ],
          ),
          if (hasPrevious) ...[
            const SizedBox(height: 8),
            Text(
              '较上一时段$direction $changePercent%',
              style: AppTextStyles.bodyMuted(context).copyWith(
                color: comparison.changeAmount >= 0
                    ? colors.danger
                    : colors.primary,
              ),
            ),
          ],
          if (comparison.currentExpense > 0) ...[
            const SizedBox(height: 4),
            if (insightDrillDown(scope) case final drillDown?)
              _DrillDownLink(label: '查看账单', drillDown: drillDown),
          ],
        ],
      ),
    );
  }
}

class _CategoryShiftPanel extends StatelessWidget {
  const _CategoryShiftPanel({required this.changes, this.scope});

  final List<FinanceCategoryChange> changes;
  final AiInsightScope? scope;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('分类变化', style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 8),
          for (final change in changes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ledgerStore.categoryLabelFor(change.category, LedgerRecordType.expense)} ${formatCurrency(change.currentAmount)} '
                    '(${_formatSignedChange(change.changeAmount, change.changePercent)})',
                    style: AppTextStyles.bodyMuted(context).copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  if (change.cluster != null) ...[
                    Text(
                      '${change.cluster!.count} 笔集中在 '
                      '${formatDateSlash(change.cluster!.start)}-'
                      '${formatDateSlash(change.cluster!.end)}，'
                      '共 ${formatCurrency(change.cluster!.total)}',
                      style: AppTextStyles.bodyMuted(context),
                    ),
                    if (insightDrillDown(
                          scope,
                          start: change.cluster!.start,
                          end: change.cluster!.end,
                          category: change.category,
                        )
                        case final clusterDrillDown?)
                      _DrillDownLink(
                        label: '查看集中消费',
                        drillDown: clusterDrillDown,
                      ),
                  ],
                  if (insightDrillDown(scope, category: change.category)
                      case final categoryDrillDown?)
                    _DrillDownLink(
                      label: '查看账单',
                      drillDown: categoryDrillDown,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatSignedChange(double amount, double percent) {
    final sign = amount >= 0 ? '+' : '-';
    final percentText = (percent.abs() * 100).toStringAsFixed(0);
    return '$sign${formatCurrency(amount.abs())}，$sign$percentText%';
  }
}

class _MonthlyVolatilityPanel extends StatelessWidget {
  const _MonthlyVolatilityPanel({required this.volatility, this.scope});

  final FinanceMonthlyVolatilityInsight volatility;
  final AiInsightScope? scope;

  @override
  Widget build(BuildContext context) {
    final peak = volatility.peakMonth!;
    final peakLabel = '${peak.month.year}年${peak.month.month}月';
    final direction = peak.deviationFromAverage >= 0 ? '高于' : '低于';
    final percent = (peak.deviationPercent.abs() * 100).toStringAsFixed(0);
    final others = volatility.monthlyTotals
        .where((item) => item.month != peak.month)
        .take(3)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('波动最大月份', style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 8),
          Text(
            '$peakLabel · ${formatCurrency(peak.expense)}',
            style: AppTextStyles.bodyStrong(context).copyWith(
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$direction时段月均 ${formatCurrency(volatility.periodAverage)} 约 $percent%',
            style: AppTextStyles.bodyMuted(context),
          ),
          if (peak.topCategory != null) ...[
            const SizedBox(height: 4),
            Text(
              '该月最高分类：${peak.topCategory}（${formatCurrency(peak.topCategoryAmount)}）',
              style: AppTextStyles.bodyMuted(context),
            ),
            if (_peakMonthDrillDown(
                  scope,
                  peak.month,
                  category: peak.topCategory,
                )
                case final topCategoryDrillDown?)
              _DrillDownLink(
                label: '查看该月${peak.topCategory}',
                drillDown: topCategoryDrillDown,
              ),
          ],
          if (_peakMonthDrillDown(scope, peak.month) case final monthDrillDown?)
            _DrillDownLink(
              label: '查看该月账单',
              drillDown: monthDrillDown,
            ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('其他月份', style: AppTextStyles.bodyMuted(context)),
            const SizedBox(height: 4),
            for (final month in others)
              Text(
                '• ${month.month.year}年${month.month.month}月：'
                '${formatCurrency(month.expense)}',
                style: AppTextStyles.bodyMuted(context),
              ),
          ],
        ],
      ),
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  const _MetricsPanel({required this.snapshot, this.scope});

  final AiInsightSnapshot snapshot;
  final AiInsightScope? scope;

  @override
  Widget build(BuildContext context) {
    final overview = snapshot.overview;
    final incomeLabel = scope?.periodIncomeLabel() ?? '时段收入';
    final expenseLabel = scope?.periodExpenseLabel() ?? '消费支出';
    final balanceLabel = scope?.periodBalanceLabel() ?? '时段结余';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('收支概览', style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 8),
          _MetricLine(
            label: incomeLabel,
            value: formatCurrency(overview.totalIncome),
          ),
          _MetricLine(
            label: expenseLabel,
            value: formatCurrency(overview.totalExpense),
          ),
          _MetricLine(
            label: balanceLabel,
            value: formatCurrency(overview.balance),
          ),
          if (overview.dailyAvgExpense > 0)
            _MetricLine(
              label: '日均消费',
              value: formatCurrency(overview.dailyAvgExpense),
            ),
          if (snapshot.budgetRisk.hasBudget) ...[
            const SizedBox(height: 4),
            _MetricLine(
              label: scope?.periodBudgetLabel() ?? '时段预算',
              value: formatCurrency(snapshot.budgetRisk.monthlyBudget),
            ),
            Text(
              snapshot.budgetRisk.summary,
              style: AppTextStyles.bodyMuted(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotablePanel extends StatelessWidget {
  const _NotablePanel({
    required this.snapshot,
    this.scope,
  });

  final AiInsightSnapshot snapshot;
  final AiInsightScope? scope;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = snapshot.anomalies.items;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('值得关注', style: AppTextStyles.bodyStrong(context)),
              ),
              Text(
                '${items.length} 条',
                style: AppTextStyles.bodyMuted(context),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 26, top: 4),
            child: Text(
              snapshot.anomalies.summary,
              style: AppTextStyles.bodyMuted(context),
            ),
          ),
          children: [
            if (items.isEmpty)
              Text('• 未发现明显异常消费。', style: AppTextStyles.bodyMuted(context))
            else
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: AppDecorations.softFill(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.title} · ${formatCurrency(item.amount)}',
                          style: AppTextStyles.bodyStrong(context),
                        ),
                        const SizedBox(height: 4),
                        Text(item.reason, style: AppTextStyles.bodyMuted(context)),
                        if (insightDrillDown(
                              scope,
                              category: item.category,
                              searchQuery: anomalySearchQuery(item),
                            )
                            case final itemDrillDown?)
                          _DrillDownLink(
                            label: '查看相关账单',
                            drillDown: itemDrillDown,
                          ),
                        if (item.records.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          for (final record in item.records)
                            Text(
                              '• ${formatRecordDate(record.createdAt)} · '
                              '${ledgerStore.categoryLabelFor(record.category, LedgerRecordType.expense)} · ${record.title} · '
                              '${formatCurrency(record.amount)}',
                              style: AppTextStyles.bodyMuted(context),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _NextMonthBudgetPanel extends StatelessWidget {
  const _NextMonthBudgetPanel({
    required this.snapshot,
    required this.onApplyTotal,
    required this.onGoBudgetManagement,
  });

  final AiInsightSnapshot snapshot;
  final Future<void> Function(BuildContext context) onApplyTotal;
  final Future<void> Function(BuildContext context) onGoBudgetManagement;

  @override
  Widget build(BuildContext context) {
    final suggestion = snapshot.budgetSuggestion;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('下月预算建议', style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 4),
          Text(suggestion.summary, style: AppTextStyles.bodyMuted(context)),
          const SizedBox(height: 8),
          for (final item in suggestion.byCategory)
            Text(
              '• ${ledgerStore.categoryLabelFor(item.category, LedgerRecordType.expense)}：建议 ${formatCurrency(item.suggestedBudget)} '
              '(较本月 ${formatCurrency(item.delta, signed: true)})',
              style: AppTextStyles.bodyMuted(context),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onGoBudgetManagement(context),
                  child: const Text('去预算管理'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => onApplyTotal(context),
                  child: const Text('应用到下月'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMuted(context)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyStrong(context)),
      ],
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '• $label：$value',
        style: AppTextStyles.bodyMuted(context),
      ),
    );
  }
}
