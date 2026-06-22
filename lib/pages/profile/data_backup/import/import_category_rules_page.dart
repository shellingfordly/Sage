import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../components/dialogs/confirm_dialog.dart';
import '../../../../components/sheets/category_picker_sheet.dart';
import '../../../../data/ledger_store.dart';
import '../../../../models/import_category_rule.dart';
import '../../../../models/ledger_category.dart';
import '../../../../models/ledger_record.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_styles.dart';
import '../../../../theme/app_text_styles.dart';

class ImportCategoryRulesPage extends StatefulWidget {
  const ImportCategoryRulesPage({super.key});

  @override
  State<ImportCategoryRulesPage> createState() =>
      _ImportCategoryRulesPageState();
}

class _ImportCategoryRulesPageState extends State<ImportCategoryRulesPage> {
  Future<void> _openRuleEditor({ImportCategoryRule? rule}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ImportCategoryRuleEditorSheet(rule: rule),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteRule(ImportCategoryRule rule) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '删除规则',
      content: '确认删除「${rule.keyword}」的匹配规则吗？',
      confirmText: '删除',
    );
    if (confirmed != true) {
      return;
    }
    await ledgerStore.deleteImportCategoryRule(rule.id);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = ledgerStore.importCategoryRules;

    return Scaffold(
      appBar: AppBar(
        title: const Text('导入分类规则'),
        actions: [
          IconButton(
            onPressed: () => _openRuleEditor(),
            icon: const Icon(Icons.add),
            tooltip: '新增规则',
          ),
        ],
      ),
      body: SafeArea(
        child: rules.isEmpty
            ? _EmptyRulesHint(onAdd: () => _openRuleEditor())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: AppSpacing.page,
                    child: Text(
                      '账单导入时，若交易描述包含关键词则优先映射到指定分类。'
                      '默认最长关键词优先，同长度时按下方排序。',
                      style: AppTextStyles.bodyMuted(context),
                    ),
                  ),
                  Expanded(
                    child: SlidableAutoCloseBehavior(
                      child: ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: rules.length,
                        onReorder: (oldIndex, newIndex) async {
                          await ledgerStore.reorderImportCategoryRules(
                            oldIndex: oldIndex,
                            newIndex: newIndex,
                          );
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        itemBuilder: (context, index) {
                          final rule = rules[index];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(rule.id),
                            index: index,
                            child: _RuleTile(
                              rule: rule,
                              categoryLabel: ledgerStore.categoryLabelFor(
                                rule.category,
                                LedgerRecordType.expense,
                              ),
                              onEdit: () => _openRuleEditor(rule: rule),
                              onDelete: () => _deleteRule(rule),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyRulesHint extends StatelessWidget {
  const _EmptyRulesHint({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rule_folder_outlined,
              size: 56,
              color: context.colors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '还没有自定义规则',
              style: AppTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: 8),
            Text(
              '例如：「某某加油站」→ 交通·加油充电\n「某某超市」→ 餐饮·零食水果',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted(context),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('添加第一条规则'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.rule,
    required this.categoryLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final ImportCategoryRule rule;
  final String categoryLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.45,
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: colors.primary,
              foregroundColor: colors.onStrong,
              icon: Icons.edit_outlined,
              label: '编辑',
            ),
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: '删除',
            ),
          ],
        ),
        child: Material(
          color: colors.surface,
          borderRadius: AppRadii.card,
          child: ListTile(
            leading: Icon(Icons.drag_handle, color: colors.textSecondary),
            title: Text(
              rule.keyword,
              style: AppTextStyles.bodyStrong(context),
            ),
            subtitle: Text(
              '→ $categoryLabel',
              style: AppTextStyles.bodyMuted(context),
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
          ),
        ),
      ),
    );
  }
}

class _ImportCategoryRuleEditorSheet extends StatefulWidget {
  const _ImportCategoryRuleEditorSheet({this.rule});

  final ImportCategoryRule? rule;

  bool get isEditing => rule != null;

  @override
  State<_ImportCategoryRuleEditorSheet> createState() =>
      _ImportCategoryRuleEditorSheetState();
}

class _ImportCategoryRuleEditorSheetState
    extends State<_ImportCategoryRuleEditorSheet> {
  late final TextEditingController _keywordController;
  late String _selectedCategory;
  bool _saving = false;
  String? _errorMessage;

  List<LedgerCategory> get _expenseCategories {
    final categories = ledgerStore.categoriesForType(LedgerRecordType.expense);
    return flattenCategoriesWithSubs(
      topLevelCategories(categories, LedgerRecordType.expense),
      categories,
    );
  }

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController(text: widget.rule?.keyword ?? '');
    _keywordController.addListener(_clearError);
    _selectedCategory = widget.rule?.category ??
        _expenseCategories.firstOrNull?.name ??
        '其他';
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  String? _validateInput(String keyword) {
    if (keyword.isEmpty) {
      return '请输入匹配关键词';
    }
    final duplicate = ledgerStore.importCategoryRules.any(
      (rule) =>
          rule.keyword == keyword &&
          (!widget.isEditing || rule.id != widget.rule!.id),
    );
    if (duplicate) {
      return '该关键词已存在，请换一个';
    }
    return null;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }

    final keyword = _keywordController.text.trim();
    final validationError = _validateInput(keyword);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    final success = widget.isEditing
        ? await ledgerStore.updateImportCategoryRule(
            ruleId: widget.rule!.id,
            keyword: keyword,
            category: _selectedCategory,
          )
        : await ledgerStore.createImportCategoryRule(
            keyword: keyword,
            category: _selectedCategory,
          );

    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _errorMessage = '分类无效或保存失败，请重试');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isEditing ? '编辑规则' : '新增规则',
            style: AppTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _keywordController,
            decoration: InputDecoration(
              labelText: '匹配关键词',
              hintText: '关键词',
              errorText: _errorMessage,
              border: const OutlineInputBorder(borderRadius: AppRadii.card),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          CategoryPicker(
            categories: _expenseCategories,
            selectedName: _selectedCategory,
            enabled: true,
            onSelected: (value) {
              _clearError();
              setState(() => _selectedCategory = value);
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isEditing ? '保存' : '添加'),
          ),
        ],
      ),
    );
  }
}
