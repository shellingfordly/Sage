import 'package:flutter/material.dart';

import '../../../components/sheets/app_form_sheet.dart';
import '../../../data/ledger_store.dart';
import '../../../models/ledger_category.dart';
import '../../../models/ledger_record.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_styles.dart';

class CategoryFormPage extends StatefulWidget {
  const CategoryFormPage({
    super.key,
    required this.type,
    this.category,
  });

  final LedgerRecordType type;
  final LedgerCategory? category;

  bool get isEditing => category != null;

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  late final TextEditingController _nameController;
  late LedgerRecordType _selectedType;
  late String _selectedIconKey;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.category?.type ?? widget.type;
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIconKey =
        widget.category?.iconKey ??
        iconKeyForCategoryName('其他', _selectedType);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) {
      return;
    }

    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final success = widget.isEditing
        ? await ledgerStore.updateCategory(
            categoryId: widget.category!.id,
            name: name,
            iconKey: _selectedIconKey,
          )
        : await ledgerStore.createCategory(
            type: _selectedType,
            name: name,
            iconKey: _selectedIconKey,
          );

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分类名称已存在或无效')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '编辑分类' : '新增分类'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.page,
                child: Form(
                  key: _formKey,
                  child: Column(
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
                        onSelectionChanged: widget.isEditing || _saving
                            ? null
                            : (values) {
                                setState(() => _selectedType = values.first);
                              },
                      ),
                      const SizedBox(height: 20),
                      AppFormTextField(
                        controller: _nameController,
                        label: '分类名称',
                        hintText: '例如：早餐、房租、副业',
                        maxLength: 12,
                        autofocus: !widget.isEditing,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return '请输入分类名称';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const AppFormSectionLabel(label: '选择图标'),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categoryIconOptions.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final option = categoryIconOptions[index];
                          return _IconChoiceTile(
                            icon: option.icon,
                            selected: option.key == _selectedIconKey,
                            enabled: !_saving,
                            onTap: () =>
                                setState(() => _selectedIconKey = option.key),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: AppSpacing.page,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onStrong,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.card,
                  ),
                ),
                child: Text(_saving ? '保存中...' : (widget.isEditing ? '保存' : '创建')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChoiceTile extends StatelessWidget {
  const _IconChoiceTile({
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.card,
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? colors.primarySoft : colors.softFill,
            borderRadius: AppRadii.card,
            border: Border.all(
              color: selected ? colors.primary : colors.surfaceBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 24,
              color: selected ? colors.primary : colors.textBody,
            ),
          ),
        ),
      ),
    );
  }
}
