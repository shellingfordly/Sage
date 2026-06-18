import 'package:flutter/material.dart';

import '../../data/ledger_store.dart';
import '../../models/ledger_category.dart';
import '../../models/ledger_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';

const _gridCrossAxisCount = 5;
const _gridSpacing = 6.0;

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
    if (categories.isEmpty) {
      return resolveDisplayCategory(
        categories,
        name: selectedName,
        type: LedgerRecordType.expense,
      );
    }
    return resolveDisplayCategory(
      categories,
      name: selectedName,
      type: categories.first.type,
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
                  ledgerStore.categoryLabelFor(
                    selected.name,
                    categories.first.type,
                  ),
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

class CategoryPickerSheet extends StatefulWidget {
  const CategoryPickerSheet({
    super.key,
    required this.categories,
    required this.selectedName,
  });

  final List<LedgerCategory> categories;
  final String selectedName;

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  String? _expandedParentId;

  LedgerRecordType get _type => widget.categories.first.type;

  List<LedgerCategory> get _topLevel =>
      topLevelCategories(widget.categories, _type);

  @override
  void initState() {
    super.initState();
    final selected = findCategoryByName(
      widget.categories,
      name: widget.selectedName,
      type: _type,
    );
    _expandedParentId = selected?.parentId;
  }

  void _onParentTap(LedgerCategory parent) {
    final subs = subcategoriesOf(widget.categories, parent.id);
    if (subs.isEmpty) {
      Navigator.of(context).pop(parent.name);
      return;
    }
    if (_expandedParentId == parent.id) {
      Navigator.of(context).pop(parent.name);
      return;
    }
    setState(() => _expandedParentId = parent.id);
  }

  bool _isParentActive(LedgerCategory parent) {
    if (widget.selectedName == parent.name) {
      return true;
    }
    return subcategoriesOf(widget.categories, parent.id).any(
      (sub) => sub.name == widget.selectedName,
    );
  }

  LedgerCategory? _findCategoryById(String? id) {
    if (id == null) {
      return null;
    }
    for (final category in widget.categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  int _rowIndexForCategory(String categoryId) {
    final index = _topLevel.indexWhere((category) => category.id == categoryId);
    if (index == -1) {
      return -1;
    }
    return index ~/ _gridCrossAxisCount;
  }

  Widget _buildCategoryGrid({
    required List<LedgerCategory> items,
    required bool isSubcategory,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - _gridSpacing * (_gridCrossAxisCount - 1)) /
            _gridCrossAxisCount;
        return Wrap(
          spacing: _gridSpacing,
          runSpacing: _gridSpacing,
          children: [
            for (final category in items)
              SizedBox(
                width: itemWidth,
                child: _CategoryGridTile(
                  category: category,
                  selected: isSubcategory
                      ? category.name == widget.selectedName
                      : _isParentActive(category),
                  expanded: !isSubcategory && _expandedParentId == category.id,
                  hasSubcategories: !isSubcategory &&
                      categoryHasSubcategories(widget.categories, category.id),
                  compact: isSubcategory,
                  onTap: isSubcategory
                      ? () => Navigator.of(context).pop(category.name)
                      : () => _onParentTap(category),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSubcategoryPanel(LedgerCategory parent) {
    final subs = subcategoriesOf(widget.categories, parent.id);
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: subs.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.primarySoft.withValues(alpha: 0.42),
                  borderRadius: AppRadii.card,
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                  child: _buildCategoryGrid(
                    items: subs,
                    isSubcategory: true,
                  ),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expandedRowIndex = _expandedParentId == null
        ? -1
        : _rowIndexForCategory(_expandedParentId!);
    final expandedParent = _findCategoryById(_expandedParentId);
    final rowCount = (_topLevel.length / _gridCrossAxisCount).ceil();

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
              '有子分类的项目可展开后选择，再次点击主分类可直接选用',
              style: AppTextStyles.bodyMuted(context),
            ),
            const SizedBox(height: 14),
            for (var row = 0; row < rowCount; row++) ...[
              if (row > 0) const SizedBox(height: 4),
              _buildCategoryGrid(
                items: _topLevel.sublist(
                  row * _gridCrossAxisCount,
                  (row + 1) * _gridCrossAxisCount > _topLevel.length
                      ? _topLevel.length
                      : (row + 1) * _gridCrossAxisCount,
                ),
                isSubcategory: false,
              ),
              if (expandedRowIndex == row && expandedParent != null)
                _buildSubcategoryPanel(expandedParent),
            ],
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
    this.hasSubcategories = false,
    this.expanded = false,
    this.compact = false,
  });

  final LedgerCategory category;
  final bool selected;
  final bool hasSubcategories;
  final bool expanded;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconBoxSize = compact ? 30.0 : 36.0;
    final iconSize = compact ? 16.0 : 18.0;
    final labelSize = compact ? 10.5 : 11.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.primary.withValues(alpha: 0.14)
                          : colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? colors.primary.withValues(alpha: 0.55)
                            : colors.surfaceBorder.withValues(alpha: 0.85),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Icon(
                      categoryIconForKey(category.iconKey),
                      size: iconSize,
                      color: selected ? colors.primary : colors.textBody,
                    ),
                  ),
                  if (hasSubcategories)
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: selected ? colors.primary : colors.softFill,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? colors.primary
                                : colors.surfaceBorder,
                          ),
                        ),
                        child: Icon(
                          expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 11,
                          color: selected ? colors.onStrong : colors.chevron,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: labelSize,
                  height: 1.15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? colors.primary : colors.textBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
