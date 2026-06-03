import 'package:flutter/material.dart';

import '../../models/ledger_category.dart';
import '../../models/ledger_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CategoryDialogResult {
  const CategoryDialogResult({required this.name, required this.iconKey});

  final String name;
  final String iconKey;
}

Future<CategoryDialogResult?> showCategoryEditorDialog(
  BuildContext context, {
  required LedgerRecordType type,
  required String title,
  required String confirmText,
  String? initialName,
  String? initialIconKey,
}) {
  return showDialog<CategoryDialogResult>(
    context: context,
    builder: (dialogContext) => _CategoryEditorDialog(
      type: type,
      title: title,
      confirmText: confirmText,
      initialName: initialName,
      initialIconKey: initialIconKey,
    ),
  );
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({
    required this.type,
    required this.title,
    required this.confirmText,
    this.initialName,
    this.initialIconKey,
  });

  final LedgerRecordType type;
  final String title;
  final String confirmText;
  final String? initialName;
  final String? initialIconKey;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late String _selectedIconKey;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedIconKey =
        widget.initialIconKey ??
        iconKeyForCategoryName('其他', widget.type);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      CategoryDialogResult(
        name: _nameController.text.trim(),
        iconKey: _selectedIconKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
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
                      selected: option.key == _selectedIconKey,
                      onTap: () => setState(() => _selectedIconKey = option.key),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
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
