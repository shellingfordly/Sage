import 'package:flutter/material.dart';

import '../../models/ledger_category.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';

class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selectedName,
    required this.enabled,
    required this.onSelected,
  });

  final List<LedgerCategory> categories;
  final String selectedName;
  final bool enabled;
  final ValueChanged<String> onSelected;

  LedgerCategory get _selectedCategory {
    return categories.firstWhere(
      (item) => item.name == selectedName,
      orElse: () => categories.first,
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    if (!enabled) {
      return;
    }

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => CategoryPickerSheet(
        categories: categories,
        selectedName: selectedName,
      ),
    );

    if (picked != null) {
      onSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = _selectedCategory;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _openSheet(context) : null,
        borderRadius: AppRadii.card,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: '分类',
            enabled: enabled,
            suffixIcon: Icon(
              Icons.expand_more_rounded,
              color: enabled
                  ? colors.chevron
                  : colors.chevron.withValues(alpha: 0.4),
            ),
            border: const OutlineInputBorder(borderRadius: AppRadii.card),
            contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 12),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  categoryIconForKey(selected.iconKey),
                  size: 18,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected.name,
                  style: AppTextStyles.bodyStrong(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({
    super.key,
    required this.categories,
    required this.selectedName,
  });

  final List<LedgerCategory> categories;
  final String selectedName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择分类', style: AppTextStyles.sectionTitle(context)),
            const SizedBox(height: 6),
            Text(
              '点击图标即可切换分类',
              style: AppTextStyles.bodyMuted(context),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 96,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryGridTile(
                  category: category,
                  selected: category.name == selectedName,
                  onTap: () => Navigator.of(context).pop(category.name),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGridTile extends StatelessWidget {
  const _CategoryGridTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final LedgerCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadii.card,
            color: selected ? colors.primarySoft : colors.softFill,
            border: Border.all(
              color: selected ? colors.primary : colors.surfaceBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.14)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.28)
                        : colors.surfaceBorder.withValues(alpha: 0.8),
                  ),
                ),
                child: Icon(
                  categoryIconForKey(category.iconKey),
                  size: 18,
                  color: selected ? colors.primary : colors.textBody,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: selected
                    ? AppTextStyles.bodyStrong(context).copyWith(
                        color: colors.primary,
                        height: 1.2,
                      )
                    : AppTextStyles.bodyMuted(context).copyWith(
                        color: colors.textBody,
                        height: 1.2,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
