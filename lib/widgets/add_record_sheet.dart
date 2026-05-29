import 'package:flutter/material.dart';

import '../data/ledger_store.dart';
import '../models/ledger_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/app_text_styles.dart';

const expenseCategories = ['餐饮', '交通', '购物', '居住', '娱乐', '医疗', '学习', '其他'];
const incomeCategories = ['工资', '奖金', '理财', '兼职', '其他'];

Future<void> showAddRecordSheet(
  BuildContext context, {
  LedgerRecordType initialType = LedgerRecordType.expense,
  String? initialCategory,
  LedgerRecord? editingRecord,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      return AddRecordSheet(
        initialType: initialType,
        initialCategory: initialCategory,
        editingRecord: editingRecord,
      );
    },
  );
}

class AddRecordSheet extends StatefulWidget {
  const AddRecordSheet({
    super.key,
    this.initialType = LedgerRecordType.expense,
    this.initialCategory,
    this.editingRecord,
  });

  final LedgerRecordType initialType;
  final String? initialCategory;
  final LedgerRecord? editingRecord;

  @override
  State<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<AddRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  late LedgerRecordType _type;
  late String _category;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

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
    _category = _categoriesFor(_type).contains(widget.initialCategory)
        ? widget.initialCategory!
        : _categoriesFor(_type).first;
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        color: colors.pageBackground,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.editingRecord == null ? '添加记录' : '编辑记录',
                      style: AppTextStyles.sectionTitle(context),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    tooltip: '关闭',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                          _category = nextCategories.contains(_category)
                              ? _category
                              : nextCategories.first;
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
              DropdownButtonFormField<String>(
                key: ValueKey(_type),
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: '分类',
                  border: OutlineInputBorder(borderRadius: AppRadii.card),
                ),
                items: [
                  for (final category in _categoriesFor(_type))
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _category = value);
                        }
                      },
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
              const SizedBox(height: 18),
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

List<String> _categoriesFor(LedgerRecordType type) {
  return type == LedgerRecordType.income ? incomeCategories : expenseCategories;
}
