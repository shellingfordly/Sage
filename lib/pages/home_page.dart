import 'package:flutter/material.dart';

import '../data/ledger_store.dart';
import '../models/ledger_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/app_text_styles.dart';
import '../utils/ledger_formatters.dart';
import '../widgets/add_record_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ledgerStore,
      builder: (context, child) {
        final now = DateTime.now();
        final previousMonth = DateTime(now.year, now.month - 1);
        final income = ledgerStore.incomeForMonth(now);
        final expense = ledgerStore.expenseForMonth(now);
        final balance = income - expense;
        final previousBalance = ledgerStore.balanceForMonth(previousMonth);

        return SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeader(month: now),
                const SizedBox(height: 22),
                _BalancePanel(
                  balance: balance,
                  comparison: monthlyComparisonText(balance, previousBalance),
                ),
                const SizedBox(height: 16),
                _MonthlySummary(income: income, expense: expense),
                const SizedBox(height: 28),
                const _SectionTitle(title: '快捷记账'),
                const SizedBox(height: 12),
                const _QuickActions(),
                const SizedBox(height: 28),
                const _SectionTitle(title: '最近记录'),
                const SizedBox(height: 12),
                _RecentRecords(records: ledgerStore.recentRecords()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatMonthTitle(month),
                style: AppTextStyles.pageTitle(context),
              ),
              const SizedBox(height: 4),
              Text('今天也把钱花得明明白白', style: AppTextStyles.pageSubtitle(context)),
            ],
          ),
        ),
        IconButton.filled(
          onPressed: () => showAddRecordSheet(context),
          tooltip: '添加记录',
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onStrong,
            fixedSize: const Size(44, 44),
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
          ),
        ),
      ],
    );
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({required this.balance, required this.comparison});

  final double balance;
  final String comparison;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                  color: colors.overlayOnStrong,
                  borderRadius: AppRadii.card,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colors.onStrong,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text('本月结余', style: AppTextStyles.cardLabel(context)),
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
          Text(title, style: AppTextStyles.labelMuted(context)),
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

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.78,
      children: const [
        _QuickAction(
          icon: Icons.restaurant_outlined,
          label: '餐饮',
          type: LedgerRecordType.expense,
          category: '餐饮',
        ),
        _QuickAction(
          icon: Icons.directions_bus_outlined,
          label: '交通',
          type: LedgerRecordType.expense,
          category: '交通',
        ),
        _QuickAction(
          icon: Icons.shopping_bag_outlined,
          label: '购物',
          type: LedgerRecordType.expense,
          category: '购物',
        ),
        _QuickAction(
          icon: Icons.payments_outlined,
          label: '工资',
          type: LedgerRecordType.income,
          category: '工资',
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.type,
    required this.category,
  });

  final IconData icon;
  final String label;
  final LedgerRecordType type;
  final String category;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () {
        showAddRecordSheet(
          context,
          initialType: type,
          initialCategory: category,
        );
      },
      child: Container(
        decoration: AppDecorations.surface(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textBody,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRecords extends StatelessWidget {
  const _RecentRecords({required this.records});

  final List<LedgerRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyRecords();
    }

    return Container(
      decoration: AppDecorations.surface(context),
      child: Column(
        children: [
          for (var index = 0; index < records.length; index++) ...[
            _RecordTile(record: records[index]),
            if (index != records.length - 1) const _RecordDivider(),
          ],
        ],
      ),
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.surface(context),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: colors.primary, size: 30),
          const SizedBox(height: 10),
          Text('还没有记录', style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 4),
          Text('点击右上角加号开始记账', style: AppTextStyles.bodyMuted(context)),
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

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: AppDecorations.softFill(context),
            child: Icon(
              iconForCategory(record.category, record.type),
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
    );
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
