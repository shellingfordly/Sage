import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../data/ledger_store.dart';
import '../../models/ledger_book.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import 'ledger_merge_page.dart';
import 'ledger_name_dialog.dart';

class LedgerManagementPage extends StatelessWidget {
  const LedgerManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账本管理')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: ledgerStore,
          builder: (context, child) {
            final ledgers = ledgerStore.ledgers;
            final currentLedgerId = ledgerStore.currentLedger.id;
            final colors = context.colors;

            return SingleChildScrollView(
              padding: AppSpacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final name = await showLedgerNameDialog(
                              context,
                              title: '新建账本',
                              confirmText: '创建',
                            );
                            if (name == null) {
                              return;
                            }
                            await ledgerStore.createLedger(name);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('新建账本'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const LedgerMergePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.merge_type_outlined),
                          label: const Text('合并账本'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                      child: SlidableAutoCloseBehavior(
                        child: Column(
                          children: [
                            for (var index = 0; index < ledgers.length; index++) ...[
                              _LedgerSlidableRow(
                                ledger: ledgers[index],
                                selected: ledgers[index].id == currentLedgerId,
                              ),
                              if (index != ledgers.length - 1)
                                const _PanelDivider(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LedgerSlidableRow extends StatelessWidget {
  const _LedgerSlidableRow({
    required this.ledger,
    required this.selected,
  });

  final LedgerBook ledger;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDefault = ledgerStore.isDefaultLedger(ledger.id);
    return Slidable(
      key: ValueKey('ledger-${ledger.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: isDefault ? 0.24 : 0.48,
        children: [
          SlidableAction(
            onPressed: (_) => _renameLedger(context),
            backgroundColor: colors.info,
            foregroundColor: colors.onStrong,
            icon: Icons.edit_outlined,
            label: '编辑',
          ),
          if (!isDefault)
            SlidableAction(
              onPressed: (_) => _deleteLedger(context),
              backgroundColor: colors.danger,
              foregroundColor: colors.onStrong,
              icon: Icons.delete_outline,
              label: '删除',
            ),
        ],
      ),
      child: _LedgerRowContent(
        ledger: ledger,
        selected: selected,
      ),
    );
  }

  Future<void> _renameLedger(BuildContext context) async {
    final name = await showLedgerNameDialog(
      context,
      title: '编辑账本',
      confirmText: '保存',
      initialValue: ledger.name,
    );
    if (name != null) {
      await ledgerStore.renameLedger(ledgerId: ledger.id, name: name);
    }
  }

  Future<void> _deleteLedger(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除账本'),
        content: Text('确定删除「${ledger.name}」吗？账本内记录会一并删除。'),
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
    if (shouldDelete != true) {
      return;
    }
    final deleted = await ledgerStore.deleteLedger(ledger.id);
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少需要保留一个账本')),
      );
    }
  }
}

class _LedgerRowContent extends StatelessWidget {
  const _LedgerRowContent({
    required this.ledger,
    required this.selected,
  });

  final LedgerBook ledger;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recordCount = ledgerStore.recordsForLedger(ledger.id).length;
    final isDefault = ledgerStore.isDefaultLedger(ledger.id);

    return ColoredBox(
      color: colors.surface,
      child: ListTile(
        onTap: () => ledgerStore.switchLedger(ledger.id),
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? colors.primary : colors.chevron,
        ),
        title: Text(
          ledger.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyStrong(context),
        ),
        subtitle: Text(
          isDefault ? '默认账本 · 记录 $recordCount 笔' : '记录 $recordCount 笔',
          style: AppTextStyles.bodyMuted(context),
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
      indent: 56,
      color: context.colors.divider,
    );
  }
}

