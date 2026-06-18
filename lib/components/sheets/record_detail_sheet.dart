import 'package:flutter/material.dart';

import '../../components/dialogs/confirm_dialog.dart';
import '../../data/ledger_store.dart';
import '../../models/ledger_record.dart';
import '../../pages/add_record_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/ledger_formatters.dart';

class RecordDetailExtraRow {
  const RecordDetailExtraRow({required this.label, required this.value});

  final String label;
  final String value;
}

String formatFullRecordDateTime(DateTime date) {
  final datePart = formatRecordDate(date);
  final time =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  if (datePart.contains(':')) {
    return datePart;
  }
  return '$datePart $time';
}

Future<void> showRecordDetailBottomSheet(
  BuildContext context, {
  required Widget child,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => child,
  );
}

Future<void> showRecordDetailSheet(
  BuildContext context, {
  required LedgerRecord record,
}) {
  var latest = record;
  for (final item in ledgerStore.records) {
    if (item.id == record.id) {
      latest = item;
      break;
    }
  }

  return showRecordDetailBottomSheet(
    context,
    child: RecordDetailSheetBody(
      record: latest,
      actions: _LedgerRecordDetailActions(record: latest),
    ),
  );
}

Future<void> showRecordKeyValueDetailSheet(
  BuildContext context, {
  Widget? header,
  required List<RecordDetailExtraRow> rows,
}) {
  return showRecordDetailBottomSheet(
    context,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[
              header,
              const SizedBox(height: 16),
            ],
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              RecordDetailRow(label: rows[i].label, value: rows[i].value),
            ],
          ],
        ),
      ),
    ),
  );
}

class RecordDetailSheetBody extends StatelessWidget {
  const RecordDetailSheetBody({
    super.key,
    required this.record,
    this.extraRows = const [],
    this.actions,
  });

  final LedgerRecord record;
  final List<RecordDetailExtraRow> extraRows;
  final Widget? actions;

  Color _amountColor(BuildContext context) {
    final colors = context.colors;
    return switch (record.type) {
      LedgerRecordType.income => colors.primary,
      LedgerRecordType.wealth => colors.primary,
      LedgerRecordType.expense => colors.textPrimary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final amountColor = _amountColor(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                        style: AppTextStyles.sectionTitle(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ledgerRecordTypeLabel(record.type),
                        style: AppTextStyles.bodyMuted(context).copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatRecordAmount(record),
                  style: AppTextStyles.amountDisplay(context, amountColor),
                ),
              ],
            ),
            const SizedBox(height: 20),
            RecordDetailRow(
              label: '分类',
              value: ledgerStore.categoryLabelForRecord(record),
            ),
            const SizedBox(height: 10),
            RecordDetailRow(
              label: '时间',
              value: formatFullRecordDateTime(record.createdAt),
            ),
            const SizedBox(height: 10),
            if (record.source.isNotEmpty) ...[
              RecordDetailRow(label: '方式', value: record.source),
              const SizedBox(height: 10),
            ],
            if (record.notes.isNotEmpty) ...[
              RecordDetailRow(label: '备注', value: record.notes),
              const SizedBox(height: 10),
            ],
            if (record.isWealth) ...[
              if (record.wealthMeta.hasRate) ...[
                RecordDetailRow(
                  label: '年利率',
                  value: '${record.wealthMeta.annualRate!.toStringAsFixed(2)}%',
                ),
                const SizedBox(height: 10),
              ],
              if (record.wealthMeta.hasMaturity) ...[
                RecordDetailRow(
                  label: '到期日',
                  value:
                      '${record.wealthMeta.maturityDate!.year}/'
                      '${record.wealthMeta.maturityDate!.month}/'
                      '${record.wealthMeta.maturityDate!.day}',
                ),
                const SizedBox(height: 10),
              ],
              if (record.wealthMeta.remindOnMaturity) ...[
                const RecordDetailRow(label: '提醒', value: '到期时在理财管理页展示'),
                const SizedBox(height: 10),
              ],
            ],
            for (final row in extraRows) ...[
              RecordDetailRow(label: row.label, value: row.value),
              const SizedBox(height: 10),
            ],
            if (actions != null) ...[
              const SizedBox(height: 24),
              actions!,
            ],
          ],
        ),
      ),
    );
  }
}

class RecordDetailRow extends StatelessWidget {
  const RecordDetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(label, style: AppTextStyles.bodyMuted(context)),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyStrong(context).copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _LedgerRecordDetailActions extends StatelessWidget {
  const _LedgerRecordDetailActions({required this.record});

  final LedgerRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              openAddRecordPage(context, editingRecord: record);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('编辑'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: Icon(Icons.delete_outline, color: colors.danger),
            label: Text('删除', style: TextStyle(color: colors.danger)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showConfirmDialog(
      context,
      title: '删除记录',
      content: '确定删除「${record.title}」吗？',
      confirmText: '删除',
    );
    if (shouldDelete != true || !context.mounted) {
      return;
    }
    await ledgerStore.deleteRecord(record.id);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
