import 'package:flutter/material.dart';

import '../../data/ledger_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/ledger_formatters.dart';
import 'budget_management_page.dart';
import 'wealth_management_page.dart';
import 'category/category_management_page.dart';
import 'data_backup/data_backup_page.dart';
import 'ledger/ledger_management_page.dart';
import '../../components/dialogs/ledger_name_dialog.dart';
import 'about_app_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _ProfileHeader(),
            SizedBox(height: 20),
            _AccountCard(),
            SizedBox(height: 16),
            _ProfileStats(),
            SizedBox(height: 28),
            _SectionTitle(title: '账本设置'),
            SizedBox(height: 12),
            _SettingsPanel(),
            SizedBox(height: 28),
            _SectionTitle(title: '应用'),
            SizedBox(height: 12),
            _AppPanel(),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('我的', style: AppTextStyles.pageTitle(context)),
        const SizedBox(height: 4),
        Text('管理账本、预算和个人偏好', style: AppTextStyles.pageSubtitle(context)),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedBuilder(
      animation: ledgerStore,
      builder: (context, child) {
        final recordCount = ledgerStore.records.length;
        final subtitle = recordCount == 0 ? '开始你的第一笔记录' : '已记录 $recordCount 笔';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: AppDecorations.strongSurface(context),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: AppDecorations.primaryFill(context),
                child: Text(
                  '账',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onStrong,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ledgerStore.currentLedger.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppDecorations.strongSurfaceForeground(context),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.cardLabel(context)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showRenameCurrentLedgerDialog(context),
                tooltip: '编辑账本',
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppDecorations.strongSurfaceAccent(context),
                  size: 22,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ledgerStore,
      builder: (context, child) {
        final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
        final budget = ledgerStore.monthlyBudgetFor(currentMonth);
        final budgetText = budget > 0 ? formatCurrency(budget) : '未设置';
        final categories = ledgerStore.records
            .map((record) => record.category)
            .toSet();

        return Row(
          children: [
            Expanded(
              child: _StatTile(
                label: '记录',
                value: ledgerStore.records.length.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(label: '预算', value: budgetText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: '分类',
                value: categories.length.toString(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTextStyles.tileValue(context)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMuted(context),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.surface(context),
      child: Column(
        children: [
          _SettingTile(
            icon: Icons.savings_outlined,
            title: '预算管理',
            subtitle: '设置每月支出消费额度',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const BudgetManagementPage(),
                ),
              );
            },
          ),
          const _PanelDivider(),
          _SettingTile(
            icon: Icons.account_balance_outlined,
            title: '理财管理',
            subtitle: '查看理财记录与目标',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const WealthManagementPage(),
                ),
              );
            },
          ),
          const _PanelDivider(),
          _SettingTile(
            icon: Icons.category_outlined,
            title: '分类管理',
            subtitle: '调整收入和支出分类',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const CategoryManagementPage(),
                ),
              );
            },
          ),
          const _PanelDivider(),
          _SettingTile(
            icon: Icons.book_outlined,
            title: '账本管理',
            subtitle: '切换或新增账本',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const LedgerManagementPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AppPanel extends StatelessWidget {
  const _AppPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.surface(context),
      child: Column(
        children: [
          _SettingTile(
            icon: Icons.cloud_upload_outlined,
            title: '数据备份',
            subtitle: '最近备份：今天 10:24',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const DataBackupPage(),
                ),
              );
            },
          ),
          const _PanelDivider(),
          _SettingTile(
            icon: Icons.settings_outlined,
            title: '设置',
            subtitle: '主题、显示和偏好',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
          const _PanelDivider(),
          _SettingTile(
            icon: Icons.info_outline,
            title: '关于应用',
            subtitle: '智账 Sage 1.1.2',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AboutAppPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: AppDecorations.softFill(context),
              child: Icon(icon, color: colors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong(context),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMuted(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: colors.chevron, size: 22),
          ],
        ),
      ),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.sectionTitle(context));
  }
}

Future<void> _showRenameCurrentLedgerDialog(BuildContext context) async {
  final name = await showLedgerNameDialog(
    context,
    title: '编辑账本',
    confirmText: '保存',
    initialValue: ledgerStore.currentLedger.name,
  );
  if (name != null) {
    await ledgerStore.renameLedger(
      ledgerId: ledgerStore.currentLedger.id,
      name: name,
    );
  }
}
