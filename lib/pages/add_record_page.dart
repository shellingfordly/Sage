import 'package:flutter/material.dart';

import '../data/ledger_store.dart';
import '../models/ledger_category.dart';
import '../models/ledger_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/app_text_styles.dart';

Future<void> openAddRecordPage(
  BuildContext context, {
  LedgerRecordType initialType = LedgerRecordType.expense,
  String? initialCategory,
  LedgerRecord? editingRecord,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) => AddRecordPage(
        initialType: initialType,
        initialCategory: initialCategory,
        editingRecord: editingRecord,
      ),
    ),
  );
}

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({
    super.key,
    this.initialType = LedgerRecordType.expense,
    this.initialCategory,
    this.editingRecord,
  });

  final LedgerRecordType initialType;
  final String? initialCategory;
  final LedgerRecord? editingRecord;

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  late LedgerRecordType _type;
  late String _category;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  bool get _isEditing => widget.editingRecord != null;

  @override
  void initState() {
    super.initState();
    final editingRecord = widget.editingRecord;
    if (editingRecord != null) {
      _type = editingRecord.type;
      _category = editingRecord.category;
      _selectedDate = editingRecord.createdAt;
      _titleController.text = editingRecord.title;
      _amountController.text = editingRecord.amount.toStringAsFixed(2);
      return;
    }

    _type = widget.initialType;
    _category =
        _categoriesFor(_type).map((item) => item.name).contains(widget.initialCategory)
        ? widget.initialCategory!
        : _categoriesFor(_type).first.name;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑记录' : '添加记录'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? '修改账单信息' : '记录一笔新的收支',
                  style: AppTextStyles.pageSubtitle(context),
                ),
                const SizedBox(height: 20),
                SegmentedButton<LedgerRecordType>(
                  segments: const [
                    ButtonSegment(
                      value: LedgerRecordType.expense,
                      label: Text('支出'),
                      icon: Icon(Icons.trending_down),
                    ),
                    ButtonSegment(
                      value: LedgerRecordType.income,
                      label: Text('收入'),
                      icon: Icon(Icons.trending_up),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: _saving
                      ? null
                      : (values) {
                          final nextType = values.first;
                          final nextCategories = _categoriesFor(nextType);
                          setState(() {
                            _type = nextType;
                            _category =
                                nextCategories
                                    .map((item) => item.name)
                                    .contains(_category)
                                ? _category
                                : nextCategories.first.name;
                          });
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '金额',
                    prefixText: '¥ ',
                    border: OutlineInputBorder(borderRadius: AppRadii.card),
                  ),
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').trim());
                    if (amount == null || amount <= 0) {
                      return '请输入大于 0 的金额';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  enabled: !_saving,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '例如：午餐、地铁、工资',
                    border: OutlineInputBorder(borderRadius: AppRadii.card),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return '请输入记录名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _CategoryPicker(
                  key: ValueKey(_type),
                  categories: _categoriesFor(_type),
                  selectedName: _category,
                  enabled: !_saving,
                  onSelected: (name) => setState(() => _category = name),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('${_selectedDate.month}月${_selectedDate.day}日'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    alignment: Alignment.centerLeft,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.card,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onStrong,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.card,
                    ),
                  ),
                  child: Text(_saving ? '保存中...' : '保存记录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final amount = double.parse(_amountController.text.trim());
    final editingRecord = widget.editingRecord;
    if (editingRecord == null) {
      await ledgerStore.addRecord(
        title: _titleController.text,
        amount: amount,
        type: _type,
        category: _category,
        createdAt: _selectedDate,
      );
    } else {
      await ledgerStore.updateRecord(
        recordId: editingRecord.id,
        title: _titleController.text,
        amount: amount,
        type: _type,
        category: _category,
        createdAt: _selectedDate,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

List<LedgerCategory> _categoriesFor(LedgerRecordType type) {
  return ledgerStore.categoriesForType(type);
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
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
      builder: (sheetContext) => _CategoryPickerSheet(
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
              color: enabled ? colors.chevron : colors.chevron.withValues(alpha: 0.4),
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

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
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
                        fontSize: 12,
                        height: 1.2,
                      )
                    : AppTextStyles.bodyMuted(context).copyWith(
                        color: colors.textBody,
                        fontSize: 12,
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
