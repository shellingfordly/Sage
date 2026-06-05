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
import '../analysis_query.dart';

const analysisRecordPageSize = 30;
const _folderRadius = 8.0;

class AnalysisRecordList extends StatelessWidget {
  const AnalysisRecordList({
    super.key,
    required this.recordGroups,
    required this.totalCount,
    required this.hasActiveFilters,
    required this.hasMore,
  });

  final List<AnalysisRecordGroup> recordGroups;
  final int totalCount;
  final bool hasActiveFilters;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (recordGroups.isEmpty && totalCount == 0) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(hasActiveFilters: hasActiveFilters),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 8 : 0,
                  bottom: index == recordGroups.length - 1 ? 0 : 12,
                ),
                child: _FolderRecordSection(
                  title: recordGroups[index].title,
                  records: recordGroups[index].records,
                ),
              ),
              childCount: recordGroups.length,
            ),
          ),
          if (hasMore)
            SliverToBoxAdapter(
              child: _LoadMoreHint(
                loadedCount: _loadedCount,
                totalCount: totalCount,
              ),
            ),
        ],
      ),
    );
  }

  int get _loadedCount =>
      recordGroups.fold<int>(0, (sum, group) => sum + group.records.length);
}

class _FolderRecordSection extends StatelessWidget {
  const _FolderRecordSection({
    required this.title,
    required this.records,
  });

  final String title;
  final List<LedgerRecord> records;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor = colors.surfaceBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 56, maxWidth: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(_folderRadius),
              topRight: Radius.circular(_folderRadius),
            ),
            border: Border(
              top: BorderSide(color: borderColor),
              left: BorderSide(color: borderColor),
              right: BorderSide(color: borderColor),
            ),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyStrong(context).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(_folderRadius),
                bottomLeft: Radius.circular(_folderRadius),
                bottomRight: Radius.circular(_folderRadius),
              ),
              border: Border.all(color: borderColor),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(_folderRadius),
                bottomLeft: Radius.circular(_folderRadius),
                bottomRight: Radius.circular(_folderRadius),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < records.length; index++) ...[
                    _RecordSlidable(record: records[index]),
                    if (index != records.length - 1) const _RecordDivider(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.primary.withValues(alpha: 0.7),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: AppDecorations.softFill(context),
                child: Icon(
                  ledgerStore.categoryIconFor(record.category, record.type),
                  color: colors.textBody,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong(context).copyWith(
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${record.category} · ${formatRecordDate(record.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMuted(context).copyWith(
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatRecordAmount(record),
                  style: AppTextStyles.amount(context, amountColor).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
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
      indent: 48,
      endIndent: 10,
      color: context.colors.divider.withValues(alpha: 0.75),
    );
  }
}
