import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../data/ledger_store.dart';
import '../../models/ledger_category.dart';
import '../../models/ledger_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';

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
                    '可添加、编辑和删除分类；删除后历史记录会归类到“其他”。',
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
                          child: ListView.separated(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return _CategorySlidableRow(
                                category: category,
                                onEdit: () => _showEditDialog(category),
                                onDelete: () => _deleteCategory(category),
                              );
                            },
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 1,
                              indent: 62,
                              color: colors.divider,
                            ),
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
    final result = await _showCategoryDialog(
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
    final result = await _showCategoryDialog(
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确认删除「${category.name}」吗？该分类历史记录会归类到“其他”。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
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
      key: ValueKey('category-${category.id}'),
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
      ),
    );
  }
}

class _CategoryDialogResult {
  const _CategoryDialogResult({required this.name, required this.iconKey});

  final String name;
  final String iconKey;
}

Future<_CategoryDialogResult?> _showCategoryDialog(
  BuildContext context, {
  required LedgerRecordType type,
  required String title,
  required String confirmText,
  String? initialName,
  String? initialIconKey,
}) async {
  final nameController = TextEditingController(text: initialName ?? '');
  var selectedIconKey = initialIconKey ?? iconKeyForCategoryName('其他', type);
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<_CategoryDialogResult>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    maxLength: 12,
                    decoration: const InputDecoration(
                      labelText: '分类名称',
                      hintText: '例如：早餐、房租、副业',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return '请输入分类名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Text('选择图标', style: AppTextStyles.bodyStrong(context)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in categoryIconOptions)
                        _IconChoiceChip(
                          option: option,
                          selected: option.key == selectedIconKey,
                          onTap: () => setState(() => selectedIconKey = option.key),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(dialogContext).pop(
                  _CategoryDialogResult(
                    name: nameController.text.trim(),
                    iconKey: selectedIconKey,
                  ),
                );
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    ),
  );
  nameController.dispose();
  return result;
}

class _IconChoiceChip extends StatelessWidget {
  const _IconChoiceChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CategoryIconOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? colors.primarySoft : colors.softFill,
          border: Border.all(
            color: selected ? colors.primary : colors.surfaceBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(option.icon, size: 16, color: colors.textBody),
            const SizedBox(width: 6),
            Text(option.label, style: AppTextStyles.bodyMuted(context)),
          ],
        ),
      ),
    );
  }
}
