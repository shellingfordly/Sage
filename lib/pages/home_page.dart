import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../ai/models/ai_insight_models.dart';
import '../ai/services/ai_insight_cache.dart';
import '../ai/services/ai_insight_engine.dart';
import '../ai/services/ai_home_alert_service.dart';
import '../data/ledger_store.dart';
import '../models/ledger_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/app_text_styles.dart';
import '../utils/ledger_formatters.dart';
import '../pages/profile/budget_management_page.dart';
import '../pages/add_record_page.dart';
import '../widgets/month_nav_row.dart';

const _aiInsightEngine = AiInsightEngine();
const _aiHomeAlertService = AiHomeAlertService();
final _aiInsightCache = AiInsightCache();

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.selectedMonth,
    required this.canGoNextMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onOpenAiPage,
  });

  final DateTime selectedMonth;
  final bool canGoNextMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onOpenAiPage;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ledgerStore,
      builder: (context, child) {
        final now = DateTime.now();
        final previousMonth = DateTime(
          selectedMonth.year,
          selectedMonth.month - 1,
          1,
        );
        final monthReference = monthReferenceDate(selectedMonth, now: now);
        final income = ledgerStore.incomeForMonth(selectedMonth);
        final expense = ledgerStore.expenseForMonth(selectedMonth);
        final budget = ledgerStore.monthlyBudgetFor(selectedMonth);
        final balance = income - expense;
        final previousBalance = ledgerStore.balanceForMonth(previousMonth);
        final aiSnapshot = _aiInsightCache.getOrBuild(
          ledgerId: ledgerStore.currentLedger.id,
          records: ledgerStore.records,
          monthlyBudget: budget,
          mode: AiSuggestionMode.balanced,
          now: monthReference,
          builder: () => _aiInsightEngine.buildSnapshot(
            records: ledgerStore.records,
            monthlyBudget: budget,
            mode: AiSuggestionMode.balanced,
            now: monthReference,
          ),
        );
        final alert = _aiHomeAlertService.evaluate(aiSnapshot);

        return SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeader(
                  month: selectedMonth,
                  now: now,
                  canGoNext: canGoNextMonth,
                  onPreviousMonth: onPreviousMonth,
                  onNextMonth: onNextMonth,
                ),
                const SizedBox(height: 22),
                _BalancePanel(
                  month: selectedMonth,
                  balance: balance,
                  comparison: monthlyComparisonText(balance, previousBalance),
                ),
                const SizedBox(height: 16),
                _MonthlySummary(income: income, expense: expense),
                const SizedBox(height: 16),
                _BudgetProgressCard(
                  month: selectedMonth,
                  budget: budget,
                  expense: expense,
                ),
                if (alert.show) ...[
                  const SizedBox(height: 16),
                  _AiAlertCard(alert: alert, onTap: onOpenAiPage),
                ],
                const SizedBox(height: 28),
                _SectionTitle(
                  title: monthBillSectionTitle(selectedMonth, now: now),
                ),
                const SizedBox(height: 12),
                _MonthlyRecords(
                  month: selectedMonth,
                  records: ledgerStore.recordsForMonth(selectedMonth),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AiAlertCard extends StatelessWidget {
  const _AiAlertCard({required this.alert, required this.onTap});

  final AiHomeAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final warningText = <String>[
      if (alert.hasBudgetWarning) '预算预警',
      if (alert.hasAnomaly) '异常消费 ${alert.anomalyCount} 条',
    ].join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(context),
      child: Row(
        children: [
          Icon(Icons.notification_important_outlined, color: colors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI 风险提醒', style: AppTextStyles.bodyStrong(context)),
                const SizedBox(height: 4),
                Text(warningText, style: AppTextStyles.bodyMuted(context)),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: const Text('查看')),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.month,
    required this.now,
    required this.canGoNext,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime month;
  final DateTime now;
  final bool canGoNext;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonthNavRow(
          title: formatMonthTitle(month, now: now),
          canGoPrevious: true,
          canGoNext: canGoNext,
          onPrevious: onPreviousMonth,
          onNext: onNextMonth,
        ),
        const SizedBox(height: 4),
        Text(
          homeSubtitleForMonth(month, now: now),
          style: AppTextStyles.pageSubtitle(context),
        ),
      ],
    );
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({
    required this.month,
    required this.balance,
    required this.comparison,
  });

  final DateTime month;
  final double balance;
  final String comparison;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.strongSurface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppDecorations.strongSurfaceIconBackground(context),
                  borderRadius: AppRadii.card,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppDecorations.strongSurfaceIconForeground(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                monthBalanceLabel(month),
                style: AppTextStyles.cardLabel(context),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            formatCurrency(balance),
            style: AppTextStyles.cardDisplay(context),
          ),
          const SizedBox(height: 12),
          Text(comparison, style: AppTextStyles.cardPositive(context)),
        ],
      ),
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({required this.income, required this.expense});

  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            title: '收入',
            amount: formatCurrency(income),
            icon: Icons.trending_up,
            iconColor: colors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            title: '支出',
            amount: formatCurrency(expense),
            icon: Icons.trending_down,
            iconColor: colors.danger,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.bodyMuted(context)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(amount, style: AppTextStyles.tileValue(context)),
          ),
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

class _BudgetProgressCard extends StatelessWidget {
  const _BudgetProgressCard({
    required this.month,
    required this.budget,
    required this.expense,
  });

  final DateTime month;
  final double budget;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasBudget = budget > 0;
    final remaining = hasBudget ? (budget - expense) : 0.0;
    final progress = hasBudget
        ? (expense / budget).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final overBudget = hasBudget && expense > budget;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.savings_outlined,
                color: overBudget ? colors.danger : colors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                monthBudgetLabel(month),
                style: AppTextStyles.bodyStrong(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasBudget) ...[
            Text('暂未设置预算，设置后可跟踪支出进度', style: AppTextStyles.bodyMuted(context)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _openBudgetManagement(context),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('去设置预算'),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '已支出 ${formatCurrency(expense)}',
                    style: AppTextStyles.bodyMuted(context),
                  ),
                ),
                Text(
                  overBudget
                      ? '已超支 ${formatCurrency(expense - budget)}'
                      : '剩余 ${formatCurrency(remaining)}',
                  style: overBudget
                      ? AppTextStyles.amount(context, colors.danger)
                      : AppTextStyles.amount(context, colors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colors.softFill,
                valueColor: AlwaysStoppedAnimation<Color>(
                  overBudget ? colors.danger : colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '预算 ${formatCurrency(budget)}',
              style: AppTextStyles.bodyMuted(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openBudgetManagement(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BudgetManagementPage(initialMonth: month),
      ),
    );
  }
}

class _MonthlyRecords extends StatelessWidget {
  const _MonthlyRecords({required this.month, required this.records});

  final DateTime month;
  final List<LedgerRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return _EmptyRecords(month: month);
    }

    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.card,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.card,
        child: Column(
          children: [
            for (var index = 0; index < records.length; index++) ...[
              _RecordSlidable(record: records[index]),
              if (index != records.length - 1) const _RecordDivider(),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final emptyText = isCurrentMonth(month)
        ? '本月还没有账单'
        : '${month.month}月还没有账单';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.surface(context),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: colors.primary, size: 30),
          const SizedBox(height: 10),
          Text(emptyText, style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 4),
          Text('点击底部加号开始记账', style: AppTextStyles.bodyMuted(context)),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final LedgerRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final amountColor = record.isIncome ? colors.primary : colors.danger;

    return ColoredBox(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: AppDecorations.softFill(context),
            child: Icon(
              ledgerStore.categoryIconFor(record.category, record.type),
              color: colors.textBody,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong(context),
                ),
                const SizedBox(height: 3),
                Text(
                  '${record.category} · ${formatRecordDate(record.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMuted(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatRecordAmount(record),
              style: AppTextStyles.amount(context, amountColor),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _RecordSlidable extends StatelessWidget {
  const _RecordSlidable({required this.record});

  final LedgerRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Slidable(
      key: ValueKey(record.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.48,
        children: [
          SlidableAction(
            onPressed: (_) =>
                openAddRecordPage(context, editingRecord: record),
            backgroundColor: colors.info,
            foregroundColor: colors.onStrong,
            icon: Icons.edit_outlined,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
            backgroundColor: colors.danger,
            foregroundColor: colors.onStrong,
            icon: Icons.delete_outline,
            label: '删除',
          ),
        ],
      ),
      child: _RecordTile(record: record),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确定删除「${record.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await ledgerStore.deleteRecord(record.id);
    }
  }
}

class _RecordDivider extends StatelessWidget {
  const _RecordDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 66,
      color: context.colors.divider,
    );
  }
}
