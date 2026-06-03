import 'package:flutter/material.dart';

import '../../data/ledger_store.dart';
import '../../models/ledger_record.dart';
import '../../pages/add_record_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/ledger_formatters.dart';

Future<void> showRecordDetailSheet(
  BuildContext context, {
  required LedgerRecord record,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _RecordDetailSheet(record: record),
  );
}

class _RecordDetailSheet extends StatelessWidget {
  const _RecordDetailSheet({required this.record});

  final LedgerRecord record;

  String _formatFullDateTime(DateTime date) {
    final datePart = formatRecordDate(date);
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (datePart.contains(':')) {
      return datePart;
    }
    return '$datePart $time';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final amountColor =
        record.isIncome ? colors.primary : colors.textPrimary;

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
                        record.isIncome ? '收入' : '支出',
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
            _DetailRow(label: '分类', value: record.category),
            const SizedBox(height: 10),
            _DetailRow(
              label: '时间',
              value: _formatFullDateTime(record.createdAt),
            ),
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              _DetailRow(label: '备注', value: record.notes),
            ],
            const SizedBox(height: 24),
            Row(
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
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check),
                    label: const Text('关闭'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
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
