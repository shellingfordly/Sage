import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../components/fields/read_only_method_field.dart';
import '../../../data/ledger_store.dart';
import '../../../models/ledger_category.dart';
import '../../../models/ledger_record.dart';
import '../../../services/bank_bill/bank_bill_models.dart';
import '../../../services/bank_bill/bank_bill_privacy.dart';
import '../../../services/bank_bill/bank_bill_record_builder.dart';
import '../../../services/bank_bill/bill_import_source.dart';
import '../../../services/bank_bill/templates/standard_table_template.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/ledger_formatters.dart';

/// PDF 账单导入审核页：展示解析与跳过结果，支持编辑与删除。
class BankBillImportReviewPage extends StatefulWidget {
  const BankBillImportReviewPage({
    super.key,
    required this.fileName,
    required this.templateName,
    required this.records,
    this.skippedRows = const [],
  });

  final String fileName;
  final String templateName;
  final List<BankBillParsedRecord> records;
  final List<BankBillSkippedRow> skippedRows;

  @override
  State<BankBillImportReviewPage> createState() => _BankBillImportReviewPageState();
}

class _BankBillImportReviewPageState extends State<BankBillImportReviewPage> {
  late List<BankBillParsedRecord> _items;
  late List<BankBillSkippedRow> _skipped;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _items = List<BankBillParsedRecord>.from(widget.records);
    _skipped = List<BankBillSkippedRow>.from(widget.skippedRows);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(String haystack) {
    if (_query.isEmpty) {
      return true;
    }
    return haystack.toLowerCase().contains(_query);
  }

  List<BankBillParsedRecord> get _visibleItems {
    return _items.where((item) {
      final record = item.record;
      final haystack =
          '${record.title} ${record.category} ${record.notes} ${record.source} ${item.categoryReason}';
      return _matchesQuery(haystack);
    }).toList();
  }

  List<BankBillSkippedRow> get _visibleSkipped {
    return _skipped.where((row) {
      return _matchesQuery('${row.sourceLine} ${row.reason}');
    }).toList();
  }

  void _removeItem(BankBillParsedRecord item) {
    setState(() => _items.remove(item));
  }

  void _removeSkipped(BankBillSkippedRow row) {
    setState(() => _skipped.remove(row));
  }

  Future<void> _editParsedItem(BankBillParsedRecord item) async {
    final updated = await showBankBillImportEditSheet(
      context,
      initialRecord: item.record,
      categoryReason: item.categoryReason,
      sourceLine: item.raw.sourceLine,
    );
    if (updated == null || !mounted) {
      return;
    }
    setState(() {
      final index = _items.indexOf(item);
      if (index < 0) {
        return;
      }
      _items[index] = BankBillParsedRecord(
        record: updated,
        categoryReason: '已手动编辑',
        raw: item.raw,
      );
    });
  }

  Future<void> _editSkippedRow(BankBillSkippedRow row) async {
    final draft = _draftFromSkipped(row);
    final updated = await showBankBillImportEditSheet(
      context,
      initialRecord: draft,
      categoryReason: row.reason,
      sourceLine: row.sourceLine,
      isSkippedDraft: true,
    );
    if (updated == null || !mounted) {
      return;
    }
    setState(() {
      _skipped.remove(row);
      _items.add(
        BankBillParsedRecord(
          record: updated,
          categoryReason: '由跳过行手动修复',
          raw: BankBillRawRow(
            date: updated.createdAt,
            currency: 'CNY',
            amount: updated.isWealth
                ? updated.amount
                : (updated.isIncome ? updated.amount : -updated.amount),
            balance: 0,
            transactionSummary: _summaryFromNotes(updated.notes) ?? updated.title,
            sourceLine: row.sourceLine,
          ),
        ),
      );
    });
  }

  LedgerRecord _draftFromSkipped(BankBillSkippedRow row) {
    final raw = StandardTableBankBillTemplate.tryParseSourceLine(row.sourceLine);
    if (raw != null) {
      final built = buildBankBillParsedRecord(
        raw,
        id: 'bank-draft-${row.sourceLine.hashCode}',
      );
      return built.record;
    }

    return LedgerRecord(
      id: 'bank-draft-${row.sourceLine.hashCode}',
      title: '待补充记录',
      amount: 0,
      type: LedgerRecordType.expense,
      category: '其他',
      createdAt: DateTime.now(),
      source: BillImportSource.unknown,
    );
  }

  String? _summaryFromNotes(String notes) {
    final trimmed = notes.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    const legacyPrefix = '交易摘要：';
    if (trimmed.startsWith(legacyPrefix)) {
      return trimmed.substring(legacyPrefix.length).trim();
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final visible = _visibleItems;
    final visibleSkipped = _visibleSkipped;
    final hasVisibleContent = visible.isNotEmpty || visibleSkipped.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('账单导入审核')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '文件：${widget.fileName}',
                style: AppTextStyles.bodyMuted(context),
              ),
              const SizedBox(height: 4),
              Text(
                '模板：${widget.templateName}  ·  待导入 ${_items.length} 条'
                '${_skipped.isNotEmpty ? '  ·  需处理 ${_skipped.length} 条' : ''}',
                style: AppTextStyles.bodyMuted(context),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索名称、分类、备注或原始行',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: AppRadii.card),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: !hasVisibleContent
                    ? Center(
                        child: Text(
                          _items.isEmpty && _skipped.isEmpty
                              ? '没有可导入的记录'
                              : '没有匹配的搜索结果',
                          style: AppTextStyles.bodyMuted(context),
                        ),
                      )
                    : ListView(
                        children: [
                          if (visible.isNotEmpty) ...[
                            Text(
                              '已解析',
                              style: AppTextStyles.bodyStrong(context),
                            ),
                            const SizedBox(height: 8),
                            ...visible.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ReviewItemTile(
                                  item: item,
                                  isSkipped: false,
                                  onRemove: () => _removeItem(item),
                                  onEdit: () => _editParsedItem(item),
                                ),
                              ),
                            ),
                          ],
                          if (visibleSkipped.isNotEmpty) ...[
                            if (visible.isNotEmpty) const SizedBox(height: 12),
                            Text(
                              '解析失败（可编辑后导入）',
                              style: AppTextStyles.bodyStrong(context).copyWith(
                                color: colors.danger,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...visibleSkipped.map(
                              (row) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _SkippedItemTile(
                                  row: row,
                                  onRemove: () => _removeSkipped(row),
                                  onEdit: () => _editSkippedRow(row),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(<LedgerRecord>[]),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _items.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(
                                _items.map((item) => item.record).toList(),
                              ),
                      child: Text('确认导入 ${_items.length} 条'),
                    ),
                  ),
                ],
              ),
              if (_skipped.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '仍有 ${_skipped.length} 条未修复的跳过行不会导入；可编辑后移入待导入列表。',
                  style: AppTextStyles.bodyMuted(context).copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _reviewSubtitle(LedgerRecord record) {
  final parts = <String>[
    ledgerRecordTypeLabel(record.type),
    record.category,
    if (record.source.isNotEmpty) record.source,
    formatRecordDate(record.createdAt),
  ];
  return parts.join(' · ');
}

class _ReviewItemTile extends StatelessWidget {
  const _ReviewItemTile({
    required this.item,
    required this.isSkipped,
    required this.onRemove,
    required this.onEdit,
  });

  final BankBillParsedRecord item;
  final bool isSkipped;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final record = item.record;
    final amountColor = record.isWealth
        ? colors.primary
        : (record.isIncome ? colors.primary : colors.textBody);

    return Slidable(
      key: ValueKey(record.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.35,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: colors.primary,
            foregroundColor: colors.onStrong,
            icon: Icons.edit_outlined,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (_) => onRemove(),
            backgroundColor: colors.danger,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: '删除',
          ),
        ],
      ),
      child: _RecordCard(
        record: record,
        amountColor: amountColor,
        subtitle: _reviewSubtitle(record),
        footer: '分类依据：${item.categoryReason}',
        onEdit: onEdit,
        onRemove: onRemove,
      ),
    );
  }
}

class _SkippedItemTile extends StatelessWidget {
  const _SkippedItemTile({
    required this.row,
    required this.onRemove,
    required this.onEdit,
  });

  final BankBillSkippedRow row;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Slidable(
      key: ValueKey(row.sourceLine),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.35,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: colors.primary,
            foregroundColor: colors.onStrong,
            icon: Icons.edit_outlined,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (_) => onRemove(),
            backgroundColor: colors.danger,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: '删除',
          ),
        ],
      ),
      child: Container(
        decoration: AppDecorations.surface(context).copyWith(
          border: Border.all(color: colors.danger.withValues(alpha: 0.45)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '解析失败',
                    style: AppTextStyles.bodyMuted(context).copyWith(
                      color: colors.danger,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 18, color: colors.primary),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: Icon(Icons.close, size: 18, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              redactBankBillSourceLine(row.sourceLine),
              style: AppTextStyles.bodyStrong(context),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '原因：${row.reason}',
              style: AppTextStyles.bodyMuted(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.amountColor,
    required this.subtitle,
    required this.footer,
    required this.onEdit,
    required this.onRemove,
  });

  final LedgerRecord record;
  final Color amountColor;
  final String subtitle;
  final String footer;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: AppDecorations.surface(context),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: AppTextStyles.bodyStrong(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.bodyMuted(context)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatRecordAmount(record),
                style: AppTextStyles.bodyStrong(context).copyWith(color: amountColor),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, size: 18, color: colors.primary),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: Icon(Icons.close, size: 18, color: colors.textSecondary),
              ),
            ],
          ),
          if (record.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              record.notes,
              style: AppTextStyles.bodyMuted(context),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '方式：${record.source}',
            style: AppTextStyles.bodyMuted(context),
          ),
          const SizedBox(height: 6),
          Text(
            footer,
            style: AppTextStyles.bodyMuted(context).copyWith(
              color: colors.primary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

Future<LedgerRecord?> showBankBillImportEditSheet(
  BuildContext context, {
  required LedgerRecord initialRecord,
  String? categoryReason,
  String? sourceLine,
  bool isSkippedDraft = false,
}) {
  return showModalBottomSheet<LedgerRecord>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _BankBillImportEditSheet(
      initialRecord: initialRecord,
      categoryReason: categoryReason,
      sourceLine: sourceLine,
      isSkippedDraft: isSkippedDraft,
    ),
  );
}

class _BankBillImportEditSheet extends StatefulWidget {
  const _BankBillImportEditSheet({
    required this.initialRecord,
    this.categoryReason,
    this.sourceLine,
    this.isSkippedDraft = false,
  });

  final LedgerRecord initialRecord;
  final String? categoryReason;
  final String? sourceLine;
  final bool isSkippedDraft;

  @override
  State<_BankBillImportEditSheet> createState() => _BankBillImportEditSheetState();
}

class _BankBillImportEditSheetState extends State<_BankBillImportEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late LedgerRecordType _type;
  late String _category;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    _titleController = TextEditingController(text: record.title);
    _amountController = TextEditingController(
      text: record.amount.toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: record.notes);
    _type = record.type;
    _category = _normalizeCategory(record.type, record.category);
    _selectedDate = record.createdAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _normalizeCategory(LedgerRecordType type, String category) {
    final names = ledgerStore.categoriesForType(type).map((item) => item.name);
    if (names.contains(category)) {
      return category;
    }
    return names.first;
  }

  bool get _lockRecordType =>
      !widget.isSkippedDraft && widget.initialRecord.isWealth;

  List<LedgerCategory> _categoriesFor(LedgerRecordType type) {
    final categories = ledgerStore.categoriesForType(type);
    final names = categories.map((item) => item.name).toSet();
    if (!names.contains('转账') && (_category == '转账' || widget.initialRecord.category == '转账')) {
      return [
        ...categories,
        LedgerCategory(
          id: '${type.name}-transfer-import',
          name: '转账',
          type: type,
          iconKey: 'category',
        ),
      ];
    }
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final categories = _categoriesFor(_type);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isSkippedDraft ? '修复跳过行' : '编辑账单',
                style: AppTextStyles.bodyStrong(context),
              ),
              if (widget.sourceLine != null) ...[
                const SizedBox(height: 8),
                Text(
                  '原始行（已脱敏）：${redactBankBillSourceLine(widget.sourceLine!)}',
                  style: AppTextStyles.bodyMuted(context),
                ),
              ],
              if (widget.categoryReason != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.categoryReason!,
                  style: AppTextStyles.bodyMuted(context),
                ),
              ],
              const SizedBox(height: 16),
              if (_lockRecordType) ...[
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '类型',
                    border: OutlineInputBorder(borderRadius: AppRadii.card),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text('理财', style: AppTextStyles.bodyStrong(context)),
                    ],
                  ),
                ),
              ] else
                SegmentedButton<LedgerRecordType>(
                  segments: const [
                    ButtonSegment(
                      value: LedgerRecordType.expense,
                      label: Text('支出'),
                    ),
                    ButtonSegment(
                      value: LedgerRecordType.income,
                      label: Text('收入'),
                    ),
                    ButtonSegment(
                      value: LedgerRecordType.wealth,
                      label: Text('理财'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (values) {
                    final nextType = values.first;
                    setState(() {
                      _type = nextType;
                      _category = _normalizeCategory(nextType, _category);
                    });
                  },
                ),
              const SizedBox(height: 12),
              ReadOnlyMethodField(
                value: widget.initialRecord.source.isNotEmpty
                    ? widget.initialRecord.source
                    : BillImportSource.unknown,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '金额',
                  prefixText: '¥ ',
                  border: OutlineInputBorder(borderRadius: AppRadii.card),
                ),
                validator: (value) {
                  final amount = double.tryParse((value ?? '').trim());
                  if (amount == null) {
                    return '请输入有效金额';
                  }
                  if (_type == LedgerRecordType.wealth) {
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
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(borderRadius: AppRadii.card),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return '请输入名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('bill-category-$_type'),
                initialValue: categories.map((item) => item.name).contains(_category)
                    ? _category
                    : categories.first.name,
                decoration: const InputDecoration(
                  labelText: '分类',
                  border: OutlineInputBorder(borderRadius: AppRadii.card),
                ),
                items: [
                  for (final category in categories)
                    DropdownMenuItem(
                      value: category.name,
                      child: Text(category.name),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '备注',
                  border: OutlineInputBorder(borderRadius: AppRadii.card),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(formatRecordDate(_selectedDate)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('保存'),
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

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final amount = double.parse(_amountController.text.trim());
    Navigator.of(context).pop(
      widget.initialRecord.copyWith(
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        category: _category,
        createdAt: _selectedDate,
        notes: _notesController.text.trim(),
        source: widget.initialRecord.source.isNotEmpty
            ? widget.initialRecord.source
            : BillImportSource.unknown,
      ),
    );
  }
}

/// 打开审核页并返回用户确认导入的记录；取消或全部删除时返回空列表。
Future<List<LedgerRecord>> openBankBillImportReviewPage(
  BuildContext context, {
  required String fileName,
  required String templateName,
  required List<BankBillParsedRecord> records,
  List<BankBillSkippedRow> skippedRows = const [],
}) {
  return Navigator.of(context).push<List<LedgerRecord>>(
    MaterialPageRoute<List<LedgerRecord>>(
      builder: (context) => BankBillImportReviewPage(
        fileName: fileName,
        templateName: templateName,
        records: records,
        skippedRows: skippedRows,
      ),
    ),
  ).then((value) => value ?? const []);
}
