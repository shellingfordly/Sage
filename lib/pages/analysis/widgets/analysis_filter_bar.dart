import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../analysis_query.dart';

class AnalysisFilterBar extends StatelessWidget {
  const AnalysisFilterBar({
    super.key,
    required this.typeFilter,
    required this.selectedCategory,
    required this.availableCategories,
    required this.onTypeFilterChanged,
    required this.onCategoryChanged,
    this.showBottomDivider = true,
  });

  final AnalysisTypeFilter typeFilter;
  final String? selectedCategory;
  final List<String> availableCategories;
  final ValueChanged<AnalysisTypeFilter> onTypeFilterChanged;
  final ValueChanged<String?> onCategoryChanged;
  final bool showBottomDivider;

  Future<void> _openCategorySheet(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _CategoryFilterSheet(
        categories: availableCategories,
        selectedCategory: selectedCategory,
      ),
    );
    if (picked != null) {
      onCategoryChanged(picked.isEmpty ? null : picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryLabel = selectedCategory ?? '分类';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _FilterTab(
                label: '全部',
                selected: typeFilter == AnalysisTypeFilter.all,
                onTap: () => onTypeFilterChanged(AnalysisTypeFilter.all),
              ),
            ),
            Expanded(
              child: _FilterTab(
                label: '支出',
                selected: typeFilter == AnalysisTypeFilter.expense,
                onTap: () => onTypeFilterChanged(AnalysisTypeFilter.expense),
              ),
            ),
            Expanded(
              child: _FilterTab(
                label: '收入',
                selected: typeFilter == AnalysisTypeFilter.income,
                onTap: () => onTypeFilterChanged(AnalysisTypeFilter.income),
              ),
            ),
            Expanded(
              child: _FilterTab(
                label: categoryLabel,
                selected: selectedCategory != null,
                trailing: Icons.expand_more,
                onTap: () => _openCategorySheet(context),
              ),
            ),
          ],
        ),
        if (showBottomDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: context.colors.divider.withValues(alpha: 0.85),
          ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyStrong(context).copyWith(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? colors.primary : colors.textSecondary,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 1),
                    Icon(
                      trailing,
                      size: 14,
                      color: selected ? colors.primary : colors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 2,
              width: selected ? 24 : 0,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterSheet extends StatelessWidget {
  const _CategoryFilterSheet({
    required this.categories,
    required this.selectedCategory,
  });

  final List<String> categories;
  final String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('筛选分类', style: AppTextStyles.sectionTitle(context)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CategoryOptionChip(
                  label: '全部分类',
                  selected: selectedCategory == null,
                  onTap: () => Navigator.of(context).pop(''),
                ),
                for (final category in categories)
                  _CategoryOptionChip(
                    label: category,
                    selected: selectedCategory == category,
                    onTap: () => Navigator.of(context).pop(category),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOptionChip extends StatelessWidget {
  const _CategoryOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.primarySoft : colors.softFill,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? colors.primary : colors.surfaceBorder,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.chip(context, selected: selected).copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
