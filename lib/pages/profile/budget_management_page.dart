import 'package:flutter/material.dart';

import '../../services/ai/category_budget_form_service.dart';
import '../../components/sheets/category_budget_editor_sheet.dart';
import '../../data/ledger_store.dart';
import '../../models/ledger_record.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/ledger_formatters.dart';

const _categoryBudgetFormService = CategoryBudgetFormService();

class BudgetManagementPage extends StatefulWidget {
  const BudgetManagementPage({super.key, this.initialMonth});

  final DateTime? initialMonth;

  @override
  State<BudgetManagementPage> createState() => _BudgetManagementPageState();
}

class _BudgetManagementPageState extends State<BudgetManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  late DateTime _selectedMonth;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedMonth = monthStart(widget.initialMonth ?? DateTime.now());
    _syncAmountFromStore();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('预算管理')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: ledgerStore,
          builder: (context, child) {
            final budget = ledgerStore.monthlyBudgetFor(_selectedMonth);
            final categoryBudgets = ledgerStore.categoryBudgetsForMonth(
              _selectedMonth,
            );
            final categoryBudgetTotal = _categoryBudgetFormService.sumBudgets(
              categoryBudgets,
            );
            return SingleChildScrollView(
              padding: AppSpacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LedgerInfoCard(ledgerName: ledgerStore.currentLedger.name),
                  const SizedBox(height: 16),
                  _MonthSelector(
                    month: _selectedMonth,
                    onPrevious: _saving ? null : () => _changeMonth(-1),
                    onNext: _saving ? null : () => _changeMonth(1),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.surface(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('当前预算', style: AppTextStyles.bodyMuted(context)),
                        const SizedBox(height: 6),
                        Text(
                          budget > 0 ? formatCurrency(budget) : '未设置',
                          style: AppTextStyles.tileValue(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.surface(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '分类预算',
                                style: AppTextStyles.bodyStrong(context),
                              ),
                            ),
                            Text(
                              categoryBudgets.isEmpty
                                  ? '未设置'
                                  : formatCurrency(categoryBudgetTotal),
                              style: AppTextStyles.amount(
                                context,
                                categoryBudgets.isEmpty
                                    ? Theme.of(
                                        context,
                                      ).textTheme.bodyMedium!.color!
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (categoryBudgets.isEmpty)
                          Text(
                            '可为餐饮、交通等分类单独设置预算，并自动同步到当月总预算。',
                            style: AppTextStyles.bodyMuted(context),
                          )
                        else
                          Column(
                            children: [
                              for (final entry
                                  in categoryBudgets.entries.toList()..sort(
                                    (a, b) => b.value.compareTo(a.value),
                                  ))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: AppTextStyles.bodyMuted(
                                            context,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        formatCurrency(entry.value),
                                        style: AppTextStyles.bodyMuted(context),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : _editCategoryBudgets,
                                child: const Text('编辑分类预算'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: (_saving || categoryBudgets.isEmpty)
                                    ? null
                                    : _clearCategoryBudgets,
                                child: const Text('清除分类预算'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _amountController,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '每月预算金额',
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
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _saving ? null : _saveBudget,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(_saving ? '保存中...' : '保存预算'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _saving ? null : _clearBudget,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('清除该月预算'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });
    _syncAmountFromStore();
  }

  void _syncAmountFromStore() {
    final amount = ledgerStore.monthlyBudgetFor(_selectedMonth);
    _amountController.text = amount > 0 ? amount.toStringAsFixed(2) : '';
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final amount = double.parse(_amountController.text.trim());
    await ledgerStore.setMonthlyBudget(month: _selectedMonth, amount: amount);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('预算已保存')));
  }

  Future<void> _clearBudget() async {
    setState(() => _saving = true);
    await ledgerStore.setMonthlyBudget(month: _selectedMonth, amount: 0);
    if (!mounted) {
      return;
    }
    _amountController.clear();
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('预算已清除')));
  }

  Future<void> _editCategoryBudgets() async {
    final currentBudgets = ledgerStore.categoryBudgetsForMonth(_selectedMonth);
    final previousMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
      1,
    );
    final previousCategoryBudgets = ledgerStore.categoryBudgetsForMonth(
      previousMonth,
    );
    final categoryNames = _availableExpenseCategoryNames(currentBudgets.keys);

    final rawInputs = await showCategoryBudgetEditorSheet(
      context,
      categoryNames: categoryNames,
      currentBudgets: currentBudgets,
      previousCategoryBudgets: previousCategoryBudgets,
      monthlySpendingByCategory: {
        for (final item in ledgerStore.expenseCategoryTotalsForMonth(
          _selectedMonth,
        ))
          item.category: item.amount,
      },
    );
    if (rawInputs == null) {
      return;
    }

    final parsedBudgets = _categoryBudgetFormService.parseBudgets(rawInputs);
    setState(() => _saving = true);
    await ledgerStore.setCategoryBudgetsForMonth(
      month: _selectedMonth,
      categoryBudgets: parsedBudgets,
      syncTotalBudget: true,
    );
    _syncAmountFromStore();
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('分类预算已保存并同步总预算')));
  }

  Future<void> _clearCategoryBudgets() async {
    setState(() => _saving = true);
    await ledgerStore.setCategoryBudgetsForMonth(
      month: _selectedMonth,
      categoryBudgets: const <String, double>{},
      syncTotalBudget: true,
    );
    _syncAmountFromStore();
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('分类预算已清除')));
  }

  List<String> _availableExpenseCategoryNames(Iterable<String> currentKeys) {
    final names = <String>{
      ...ledgerStore
          .categoriesForType(LedgerRecordType.expense)
          .map((category) => category.name),
      ...ledgerStore
          .expenseCategoryTotalsForMonth(_selectedMonth)
          .map((item) => item.category),
      ...currentKeys,
    };
    final list = names.toList()..sort();
    return list;
  }
}

class _LedgerInfoCard extends StatelessWidget {
  const _LedgerInfoCard({required this.ledgerName});

  final String ledgerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(context),
      child: Row(
        children: [
          const Icon(Icons.book_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '当前账本：$ledgerName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyStrong(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final title = '${month.year}年${month.month}月';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppDecorations.surface(context),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            tooltip: '上个月',
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong(context),
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: '下个月',
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
