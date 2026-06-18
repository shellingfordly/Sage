import 'package:flutter/material.dart';

import '../data/ledger_store.dart';
import '../models/ledger_category.dart';
import '../models/ledger_record.dart';
import '../models/wealth_meta.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/app_text_styles.dart';
import '../components/fields/read_only_method_field.dart';
import '../components/sheets/category_picker_sheet.dart';
import '../components/pickers/date_picker.dart';

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
  final _annualRateController = TextEditingController();

  late LedgerRecordType _type;
  late String _category;
  DateTime _selectedDate = DateTime.now();
  DateTime? _maturityDate;
  bool _remindOnMaturity = false;
  bool _saving = false;

  bool get _isEditing => widget.editingRecord != null;

  bool get _showMethod =>
      _isEditing && widget.editingRecord!.source.isNotEmpty;

  bool get _isWealth => _type == LedgerRecordType.wealth;

  bool get _lockRecordType =>
      _isEditing && widget.editingRecord!.isWealth;

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
      if (editingRecord.isWealth) {
        final meta = editingRecord.wealthMeta;
        if (meta.annualRate != null) {
          _annualRateController.text = meta.annualRate!.toStringAsFixed(2);
        }
        _maturityDate = meta.maturityDate;
        _remindOnMaturity = meta.remindOnMaturity;
      }
      return;
    }

    _type = widget.initialType;
    _category = _resolveCategory(_type, widget.initialCategory);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _annualRateController.dispose();
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
                  _isEditing ? '修改账单信息' : '记录一笔新的收支或理财',
                  style: AppTextStyles.pageSubtitle(context),
                ),
                const SizedBox(height: 20),
                if (_lockRecordType) ...[
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '类型',
                      border: OutlineInputBorder(borderRadius: AppRadii.card),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.savings_outlined, color: colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '理财',
                          style: AppTextStyles.bodyStrong(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '理财记录独立于收支结余，编辑时不可改为收入或支出。',
                    style: AppTextStyles.bodyMuted(context),
                  ),
                ] else ...[
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
                      ButtonSegment(
                        value: LedgerRecordType.wealth,
                        label: Text('理财'),
                        icon: Icon(Icons.savings_outlined),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: _saving
                        ? null
                        : (values) {
                            final nextType = values.first;
                            setState(() {
                              _type = nextType;
                              _category = _resolveCategory(nextType, _category);
                            });
                          },
                  ),
                  if (_isWealth) ...[
                    const SizedBox(height: 8),
                    Text(
                      '理财记录独立于收支结余。存入填正数，取出填负数；可填写利率与到期日以便统计。',
                      style: AppTextStyles.bodyMuted(context),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '金额',
                    prefixText: '¥ ',
                    helperText: _isWealth ? '存入填正数，取出填负数' : null,
                    border: const OutlineInputBorder(borderRadius: AppRadii.card),
                  ),
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').trim());
                    if (amount == null) {
                      return '请输入有效金额';
                    }
                    if (_isWealth) {
                      if (amount == 0) {
                        return '理财金额不能为 0';
                      }
                      return null;
                    }
                    if (amount <= 0) {
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
                  decoration: InputDecoration(
                    labelText: '名称',
                    hintText: _isWealth ? '例如：某银行定存' : '例如：午餐、地铁、工资',
                    border: const OutlineInputBorder(borderRadius: AppRadii.card),
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
                if (_isWealth) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _annualRateController,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '年利率（可选）',
                      suffixText: '%',
                      border: OutlineInputBorder(borderRadius: AppRadii.card),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickMaturityDate,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      _maturityDate == null
                          ? '选择到期日（可选）'
                          : '到期 ${_maturityDate!.year}/${_maturityDate!.month}/${_maturityDate!.day}',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      alignment: Alignment.centerLeft,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.card,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('到期时在理财管理页提醒'),
                    value: _remindOnMaturity,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _remindOnMaturity = value),
                  ),
                ],
                const SizedBox(height: 12),
                if (_showMethod) ...[
                  ReadOnlyMethodField(value: widget.editingRecord!.source),
                  const SizedBox(height: 12),
                ],
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

  String _resolveCategory(LedgerRecordType type, String? preferred) {
    final categories = _categoriesFor(type);
    if (preferred != null &&
        categories.map((item) => item.name).contains(preferred)) {
      return preferred;
    }
    return categories.first.name;
  }

  Future<void> _pickDate() async {
    final picked = await pickDate(
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

  Future<void> _pickMaturityDate() async {
    final picked = await pickDate(
      context,
      initialDate: _maturityDate ?? _selectedDate,
      helpText: '选择到期日',
    );
    if (picked != null) {
      setState(() => _maturityDate = picked);
    }
  }

  WealthMeta _buildWealthMeta() {
    final rate = double.tryParse(_annualRateController.text.trim());
    return WealthMeta(
      annualRate: rate != null && rate > 0 ? rate : null,
      maturityDate: _maturityDate,
      remindOnMaturity: _remindOnMaturity,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final amount = double.parse(_amountController.text.trim());
    final wealthMeta = _isWealth ? _buildWealthMeta() : const WealthMeta();
    final editingRecord = widget.editingRecord;
    if (editingRecord == null) {
      await ledgerStore.addRecord(
        title: _titleController.text,
        amount: amount,
        type: _type,
        category: _category,
        createdAt: _selectedDate,
        notes: _notesController.text,
        wealthMeta: wealthMeta,
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
        source: editingRecord.source,
        wealthMeta: wealthMeta,
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
