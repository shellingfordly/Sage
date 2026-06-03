import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../data/ledger_store.dart';
import '../../models/ledger_category.dart';
import '../../models/ledger_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../components/dialogs/category_editor_dialog.dart';
import '../../components/dialogs/confirm_dialog.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  LedgerRecordType _selectedType = LedgerRecordType.expense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        actions: [
          TextButton.icon(
            onPressed: _showCreateDialog,
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
              final colors = context.colors;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<LedgerRecordType>(
                    segments: const [
                      ButtonSegment(
                        value: LedgerRecordType.expense,
                        label: Text('支出分类'),
                        icon: Icon(Icons.trending_down),
                      ),
                      ButtonSegment(
                        value: LedgerRecordType.income,
                        label: Text('收入分类'),
                        icon: Icon(Icons.trending_up),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (values) {
                      setState(() => _selectedType = values.first);
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '可添加、编辑和删除分类；长按拖动可调整顺序，删除后历史记录会归类到“其他”。',
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
                            itemCount: categories.length,
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
                              final category = categories[index];
                              final isLast = index == categories.length - 1;
                              return ReorderableDelayedDragStartListener(
                                key: ValueKey('category-${category.id}'),
                                index: index,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _CategorySlidableRow(
                                      category: category,
                                      onEdit: () => _showEditDialog(category),
                                      onDelete: () => _deleteCategory(category),
                                    ),
                                    if (!isLast)
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        indent: 62,
                                        color: colors.divider,
                                      ),
                                  ],
                                ),
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

  Future<void> _showCreateDialog() async {
    final result = await showCategoryEditorDialog(
      context,
      type: _selectedType,
      title: '新增分类',
      confirmText: '创建',
    );
    if (result == null) {
      return;
    }
    final success = await ledgerStore.createCategory(
      type: _selectedType,
      name: result.name,
      iconKey: result.iconKey,
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分类名称已存在或无效')));
    }
  }

  Future<void> _showEditDialog(LedgerCategory category) async {
    final result = await showCategoryEditorDialog(
      context,
      type: category.type,
      title: '编辑分类',
      confirmText: '保存',
      initialName: category.name,
      initialIconKey: category.iconKey,
    );
    if (result == null) {
      return;
    }
    final success = await ledgerStore.updateCategory(
      categoryId: category.id,
      name: result.name,
      iconKey: result.iconKey,
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分类名称已存在或无效')));
    }
  }

  Future<void> _deleteCategory(LedgerCategory category) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '删除分类',
      content: '确认删除「${category.name}」吗？该分类历史记录会归类到“其他”。',
      confirmText: '删除',
    );
    if (confirmed != true) {
      return;
    }
    await ledgerStore.deleteCategory(category.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除分类')));
  }
}

class _CategorySlidableRow extends StatelessWidget {
  const _CategorySlidableRow({
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
      child: _CategoryRowContent(category: category),
    );
  }
}

class _CategoryRowContent extends StatelessWidget {
  const _CategoryRowContent({required this.category});

  final LedgerCategory category;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ColoredBox(
      color: colors.surface,
      child: ListTile(
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
          category.type == LedgerRecordType.expense ? '支出分类' : '收入分类',
          style: AppTextStyles.bodyMuted(context),
        ),
        trailing: Icon(
          Icons.drag_indicator_rounded,
          color: colors.chevron,
        ),
      ),
    );
  }
}
