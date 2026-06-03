import 'package:flutter/material.dart';

import '../data/ledger_store.dart';
import '../models/ledger_category.dart';
import '../models/ledger_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/app_text_styles.dart';
import '../components/sheets/category_picker_sheet.dart';
import '../components/pickers/record_date_picker.dart';

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
  final _notesController = TextEditingController();

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
      _notesController.text = editingRecord.notes;
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
    _notesController.dispose();
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
                CategoryPicker(
                  key: ValueKey(_type),
                  categories: _categoriesFor(_type),
                  selectedName: _category,
                  enabled: !_saving,
                  onSelected: (name) => setState(() => _category = name),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  enabled: !_saving,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                    hintText: '补充说明，导入 PDF 账单时可自动填入交易摘要',
                    border: OutlineInputBorder(borderRadius: AppRadii.card),
                  ),
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
    final picked = await pickRecordDate(
      context,
      initialDate: _selectedDate,
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
        notes: _notesController.text,
      );
    } else {
      await ledgerStore.updateRecord(
        recordId: editingRecord.id,
        title: _titleController.text,
        amount: amount,
        type: _type,
        category: _category,
        createdAt: _selectedDate,
        notes: _notesController.text,
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
