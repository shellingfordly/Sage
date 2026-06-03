import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_text_styles.dart';
import '../analysis_query.dart';

class AnalysisFilterBar extends StatelessWidget {
  const AnalysisFilterBar({
    super.key,
    required this.searchController,
    required this.typeFilter,
    required this.selectedCategory,
    required this.availableCategories,
    required this.onTypeFilterChanged,
    required this.onCategoryChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final AnalysisTypeFilter typeFilter;
  final String? selectedCategory;
  final List<String> availableCategories;
  final ValueChanged<AnalysisTypeFilter> onTypeFilterChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onSearchChanged;

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
    final colors = context.colors;
    final categoryLabel = selectedCategory ?? '全部分类';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          onChanged: (_) => onSearchChanged(),
          decoration: InputDecoration(
            hintText: '搜索标题、分类、备注或金额',
            prefixIcon: Icon(Icons.search, color: colors.textSecondary),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged();
                    },
                  ),
            border: OutlineInputBorder(borderRadius: AppRadii.card),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TypeFilterChip(
                label: '全部',
                selected: typeFilter == AnalysisTypeFilter.all,
                onTap: () => onTypeFilterChanged(AnalysisTypeFilter.all),
              ),
              const SizedBox(width: 8),
              _TypeFilterChip(
                label: '支出',
                selected: typeFilter == AnalysisTypeFilter.expense,
                onTap: () => onTypeFilterChanged(AnalysisTypeFilter.expense),
              ),
              const SizedBox(width: 8),
              _TypeFilterChip(
                label: '收入',
                selected: typeFilter == AnalysisTypeFilter.income,
                onTap: () => onTypeFilterChanged(AnalysisTypeFilter.income),
              ),
              const SizedBox(width: 8),
              _TypeFilterChip(
                label: categoryLabel,
                selected: selectedCategory != null,
                trailing: Icons.expand_more,
                onTap: () => _openCategorySheet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  const _TypeFilterChip({
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
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary
                : colors.primarySoft.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : colors.surfaceBorder.withValues(alpha: 0.85),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.chip(context, selected: selected).copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 2),
                Icon(
                  trailing,
                  size: 16,
                  color: selected ? colors.onStrong : colors.textBody,
                ),
              ],
            ],
          ),
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
