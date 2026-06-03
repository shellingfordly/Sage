import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../components/dialogs/confirm_dialog.dart';
import '../../../data/ledger_store.dart';
import '../../../models/ledger_record.dart';
import '../../../pages/add_record_page.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/ledger_formatters.dart';
import '../../../components/sheets/record_detail_sheet.dart';

const analysisRecordPageSize = 30;

class AnalysisRecordList extends StatelessWidget {
  const AnalysisRecordList({
    super.key,
    required this.records,
    required this.totalCount,
    required this.hasActiveFilters,
    required this.hasMore,
  });

  final List<LedgerRecord> records;
  final int totalCount;
  final bool hasActiveFilters;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty && totalCount == 0) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(hasActiveFilters: hasActiveFilters),
        ),
      );
    }

    final colors = context.colors;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index.isOdd) {
                  return const _RecordDivider();
                }
                final recordIndex = index ~/ 2;
                final isFirst = recordIndex == 0;
                final isLast = recordIndex == records.length - 1;

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: isFirst && isLast
                        ? AppRadii.card
                        : isFirst
                        ? const BorderRadius.vertical(top: Radius.circular(8))
                        : isLast
                        ? const BorderRadius.vertical(bottom: Radius.circular(8))
                        : BorderRadius.zero,
                    border: Border(
                      left: BorderSide(color: colors.surfaceBorder),
                      right: BorderSide(color: colors.surfaceBorder),
                      top: isFirst
                          ? BorderSide(color: colors.surfaceBorder)
                          : BorderSide.none,
                      bottom: isLast && !hasMore
                          ? BorderSide(color: colors.surfaceBorder)
                          : BorderSide.none,
                    ),
                  ),
                  child: _RecordSlidable(record: records[recordIndex]),
                );
              },
              childCount: records.isEmpty ? 0 : records.length * 2 - 1,
            ),
          ),
          if (hasMore)
            SliverToBoxAdapter(
              child: _LoadMoreHint(
                loadedCount: records.length,
                totalCount: totalCount,
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadMoreHint extends StatelessWidget {
  const _LoadMoreHint({
    required this.loadedCount,
    required this.totalCount,
  });

  final int loadedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        border: Border(
          left: BorderSide(color: colors.surfaceBorder),
          right: BorderSide(color: colors.surfaceBorder),
          bottom: BorderSide(color: colors.surfaceBorder),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '已显示 $loadedCount / $totalCount，继续下滑加载',
            style: AppTextStyles.bodyMuted(context),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasActiveFilters});

  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: AppDecorations.surface(context),
      child: Column(
        children: [
          Icon(
            hasActiveFilters
                ? Icons.filter_alt_off_outlined
                : Icons.receipt_long_outlined,
            color: colors.primary,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            hasActiveFilters ? '没有匹配的账单' : '该时段暂无账单',
            style: AppTextStyles.bodyStrong(context),
          ),
          const SizedBox(height: 4),
          Text(
            hasActiveFilters ? '试试调整筛选条件或搜索关键词' : '切换其他年月查看',
            style: AppTextStyles.bodyMuted(context),
          ),
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
    final amountColor =
        record.isIncome ? colors.primary : colors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showRecordDetailSheet(context, record: record),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: AppDecorations.softFill(context),
                child: Icon(
                  ledgerStore.categoryIconFor(record.category, record.type),
                  color: colors.textBody,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong(context).copyWith(
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.category} · ${formatRecordDate(record.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMuted(context).copyWith(
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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
    final shouldDelete = await showConfirmDialog(
      context,
      title: '删除记录',
      content: '确定删除「${record.title}」吗？',
      confirmText: '删除',
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
      indent: 58,
      endIndent: 12,
      color: context.colors.divider,
    );
  }
}
