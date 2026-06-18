import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../data/ledger_store.dart';
import '../../../models/ledger_category.dart';
import '../../../models/ledger_record.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_text_styles.dart';
import '../../../components/dialogs/confirm_dialog.dart';
import 'category_form_page.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  LedgerRecordType _selectedType = LedgerRecordType.expense;
  final Set<String> _expandedParentIds = {};

  Future<void> _openCreatePage({LedgerCategory? parentCategory}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CategoryFormPage(
          type: _selectedType,
          parentCategory: parentCategory,
        ),
      ),
    );
  }

  Future<void> _openEditPage(LedgerCategory category) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CategoryFormPage(
          type: category.type,
          category: category,
        ),
      ),
    );
  }

  Future<void> _deleteCategory(LedgerCategory category) async {
    final categories = ledgerStore.categoriesForType(_selectedType);
    final childCount = subcategoriesOf(categories, category.id).length;
    final content = childCount == 0
        ? '确认删除「${category.name}」吗？该分类历史记录会归类到“其他”。'
        : '确认删除「${category.name}」及其 $childCount 个子分类吗？相关历史记录会归类到“其他”。';
    final confirmed = await showConfirmDialog(
      context,
      title: '删除分类',
      content: content,
      confirmText: '删除',
    );
    if (confirmed != true) {
      return;
    }
    await ledgerStore.deleteCategory(category.id);
    if (!mounted) {
      return;
    }
    setState(() => _expandedParentIds.remove(category.id));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除分类')));
  }

  void _toggleExpanded(String parentId) {
    setState(() {
      if (_expandedParentIds.contains(parentId)) {
        _expandedParentIds.remove(parentId);
      } else {
        _expandedParentIds.add(parentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        actions: [
          TextButton.icon(
            onPressed: () => _openCreatePage(),
            icon: const Icon(Icons.add),
            label: const Text('新建分类'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.page,
          child: AnimatedBuilder(
            animation: ledgerStore,
            builder: (context, child) {
              final categories = ledgerStore.categoriesForType(_selectedType);
              final topLevel = topLevelCategories(categories, _selectedType);
              final colors = context.colors;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<LedgerRecordType>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: LedgerRecordType.expense,
                        label: Text('支出'),
                        icon: Icon(Icons.trending_down, size: 18),
                      ),
                      ButtonSegment(
                        value: LedgerRecordType.income,
                        label: Text('收入'),
                        icon: Icon(Icons.trending_up, size: 18),
                      ),
                      ButtonSegment(
                        value: LedgerRecordType.wealth,
                        label: Text('理财'),
                        icon: Icon(Icons.savings_outlined, size: 18),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (values) {
                      setState(() {
                        _selectedType = values.first;
                        _expandedParentIds.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '可添加、编辑和删除分类；长按拖动可调整主分类顺序，删除后历史记录会归类到“其他”。',
                    style: AppTextStyles.bodyMuted(context),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
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
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: topLevel.length,
                            onReorder: (oldIndex, newIndex) {
                              ledgerStore.reorderCategoriesForType(
                                type: _selectedType,
                                oldIndex: oldIndex,
                                newIndex: newIndex,
                              );
                            },
                            proxyDecorator: (child, index, animation) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) {
                                  final elevation = Tween<double>(
                                    begin: 0,
                                    end: 6,
                                  ).animate(animation).value;
                                  return Material(
                                    elevation: elevation,
                                    color: colors.surface,
                                    borderRadius: AppRadii.card,
                                    child: child,
                                  );
                                },
                                child: child,
                              );
                            },
                            itemBuilder: (context, index) {
                              final category = topLevel[index];
                              final subs = subcategoriesOf(categories, category.id);
                              final expanded = _expandedParentIds.contains(category.id);
                              final isLast = index == topLevel.length - 1;
                              return Column(
                                key: ValueKey('category-${category.id}'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ReorderableDelayedDragStartListener(
                                    index: index,
                                    child: _CategorySlidableRow(
                                      category: category,
                                      subtitle: subs.isEmpty
                                          ? _typeLabel(category.type)
                                          : '${_typeLabel(category.type)} · ${subs.length} 个子分类',
                                      trailing: subs.isEmpty
                                          ? null
                                          : IconButton(
                                              tooltip: expanded ? '收起子分类' : '展开子分类',
                                              onPressed: () => _toggleExpanded(category.id),
                                              icon: Icon(
                                                expanded
                                                    ? Icons.expand_less_rounded
                                                    : Icons.expand_more_rounded,
                                                color: colors.chevron,
                                              ),
                                            ),
                                      onEdit: () => _openEditPage(category),
                                      onDelete: () => _deleteCategory(category),
                                      onAddSubcategory: category.isSubcategory
                                          ? null
                                          : () => _openCreatePage(parentCategory: category),
                                    ),
                                  ),
                                  if (expanded && subs.isNotEmpty)
                                    ...subs.map(
                                      (sub) => _SubCategorySlidableRow(
                                        category: sub,
                                        onEdit: () => _openEditPage(sub),
                                        onDelete: () => _deleteCategory(sub),
                                      ),
                                    ),
                                  if (!isLast)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      indent: 62,
                                      color: colors.divider,
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _typeLabel(LedgerRecordType type) {
    return switch (type) {
      LedgerRecordType.expense => '支出分类',
      LedgerRecordType.income => '收入分类',
      LedgerRecordType.wealth => '理财分类',
    };
  }
}

class _CategorySlidableRow extends StatelessWidget {
  const _CategorySlidableRow({
    required this.category,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
    this.onAddSubcategory,
    this.trailing,
  });

  final LedgerCategory category;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onAddSubcategory;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: onAddSubcategory == null ? 0.48 : 0.72,
        children: [
          if (onAddSubcategory != null)
            SlidableAction(
              onPressed: (_) => onAddSubcategory!(),
              backgroundColor: colors.primary,
              foregroundColor: colors.onStrong,
              icon: Icons.add_outlined,
              label: '子分类',
            ),
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: colors.info,
            foregroundColor: colors.onStrong,
            icon: Icons.edit_outlined,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: colors.danger,
            foregroundColor: colors.onStrong,
            icon: Icons.delete_outline,
            label: '删除',
          ),
        ],
      ),
      child: _CategoryRowContent(
        category: category,
        subtitle: subtitle,
        trailing: trailing,
      ),
    );
  }
}

class _SubCategorySlidableRow extends StatelessWidget {
  const _SubCategorySlidableRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final LedgerCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.48,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: colors.info,
            foregroundColor: colors.onStrong,
            icon: Icons.edit_outlined,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: colors.danger,
            foregroundColor: colors.onStrong,
            icon: Icons.delete_outline,
            label: '删除',
          ),
        ],
      ),
      child: _CategoryRowContent(
        category: category,
        subtitle: '子分类',
        indent: 28,
        showDragHandle: false,
      ),
    );
  }
}

class _CategoryRowContent extends StatelessWidget {
  const _CategoryRowContent({
    required this.category,
    required this.subtitle,
    this.trailing,
    this.indent = 0,
    this.showDragHandle = true,
  });

  final LedgerCategory category;
  final String subtitle;
  final Widget? trailing;
  final double indent;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ColoredBox(
      color: colors.surface,
      child: ListTile(
        contentPadding: EdgeInsets.fromLTRB(16 + indent, 0, 8, 0),
        leading: Container(
          width: 38,
          height: 38,
          decoration: AppDecorations.softFill(context),
          child: Icon(
            categoryIconForKey(category.iconKey),
            color: colors.primary,
          ),
        ),
        title: Text(category.name, style: AppTextStyles.bodyStrong(context)),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodyMuted(context),
        ),
        trailing: trailing ??
            (showDragHandle
                ? Icon(
                    Icons.drag_indicator_rounded,
                    color: colors.chevron,
                  )
                : null),
      ),
    );
  }
}
