import 'package:flutter/material.dart';

import '../../models/ledger_category.dart';
import '../../models/ledger_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../sheets/app_form_sheet.dart';

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
  return showAppFormSheet<CategoryDialogResult>(
    context,
    sheet: _CategoryEditorSheet(
      type: type,
      title: title,
      confirmText: confirmText,
      initialName: initialName,
      initialIconKey: initialIconKey,
    ),
  );
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({
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
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
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
    final typeLabel =
        widget.type == LedgerRecordType.expense ? '支出分类' : '收入分类';

    return AppFormSheet(
      title: widget.title,
      subtitle: typeLabel,
      confirmText: widget.confirmText,
      maxHeightFactor: 0.88,
      onConfirm: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormTextField(
              controller: _nameController,
              label: '分类名称',
              hintText: '例如：早餐、房租、副业',
              maxLength: 12,
              autofocus: true,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return '请输入分类名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const AppFormSectionLabel(label: '选择图标'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categoryIconOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final option = categoryIconOptions[index];
                return _IconChoiceTile(
                  option: option,
                  selected: option.key == _selectedIconKey,
                  onTap: () => setState(() => _selectedIconKey = option.key),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChoiceTile extends StatelessWidget {
  const _IconChoiceTile({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.card,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? colors.primarySoft : colors.softFill,
            borderRadius: AppRadii.card,
            border: Border.all(
              color: selected ? colors.primary : colors.surfaceBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option.icon,
                size: 22,
                color: selected ? colors.primary : colors.textBody,
              ),
              const SizedBox(height: 4),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: selected ? colors.primary : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
