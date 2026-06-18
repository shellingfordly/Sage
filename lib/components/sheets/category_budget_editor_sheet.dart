import 'package:flutter/material.dart';

import '../../data/ledger_store.dart';
import '../../services/ai/category_budget_form_service.dart';
import '../../models/ledger_record.dart';
import '../../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';

const _categoryBudgetFormService = CategoryBudgetFormService();

Future<Map<String, String>?> showCategoryBudgetEditorSheet(
  BuildContext context, {
  required List<String> categoryNames,
  required Map<String, double> currentBudgets,
  required Map<String, double> previousCategoryBudgets,
  required Map<String, double> monthlySpendingByCategory,
}) {
  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => CategoryBudgetEditorSheet(
      categoryNames: categoryNames,
      currentBudgets: currentBudgets,
      previousCategoryBudgets: previousCategoryBudgets,
      monthlySpendingByCategory: monthlySpendingByCategory,
    ),
  );
}

class CategoryBudgetEditorSheet extends StatefulWidget {
  const CategoryBudgetEditorSheet({
    super.key,
    required this.categoryNames,
    required this.currentBudgets,
    required this.previousCategoryBudgets,
    required this.monthlySpendingByCategory,
  });

  final List<String> categoryNames;
  final Map<String, double> currentBudgets;
  final Map<String, double> previousCategoryBudgets;
  final Map<String, double> monthlySpendingByCategory;

  @override
  State<CategoryBudgetEditorSheet> createState() =>
      _CategoryBudgetEditorSheetState();
}

class _CategoryBudgetEditorSheetState extends State<CategoryBudgetEditorSheet> {
  bool _onlyWithSpending = false;

  late final Map<String, TextEditingController> _controllers = {
    for (final category in widget.categoryNames)
      category: TextEditingController(
        text: widget.currentBudgets[category]?.toStringAsFixed(2) ?? '',
      ),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('编辑分类预算', style: AppTextStyles.sectionTitle(context)),
              const SizedBox(height: 6),
              Text(
                '仅保存大于 0 的金额，留空将视为不设置。',
                style: AppTextStyles.bodyMuted(context),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          final draft = _categoryBudgetFormService
                              .createDraftFromSpending(
                                widget.monthlySpendingByCategory,
                              );
                          _applyDraftToControllers(draft);
                        },
                        child: const Text('按本月支出填充'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.previousCategoryBudgets.isEmpty
                            ? null
                            : () {
                                final draft = _categoryBudgetFormService
                                    .createDraftFromPreviousBudgets(
                                      widget.previousCategoryBudgets,
                                    );
                                _applyDraftToControllers(draft);
                              },
                        child: const Text('复制上月预算'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('仅显示有支出分类'),
                value: _onlyWithSpending,
                onChanged: (value) => setState(() => _onlyWithSpending = value),
              ),
              const SizedBox(height: 4),
              for (final category in _visibleCategories())
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _controllers[category],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: ledgerStore.categoryLabelFor(
                        category,
                        LedgerRecordType.expense,
                      ),
                      prefixText: '¥ ',
                      border: const OutlineInputBorder(
                        borderRadius: AppRadii.card,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final result = <String, String>{
                      for (final entry in _controllers.entries)
                        entry.key: entry.value.text,
                    };
                    Navigator.of(context).pop(result);
                  },
                  child: const Text('保存分类预算'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _visibleCategories() {
    if (!_onlyWithSpending) {
      return widget.categoryNames;
    }
    final visible = widget.categoryNames
        .where((name) => (widget.monthlySpendingByCategory[name] ?? 0) > 0)
        .toList();
    if (visible.isEmpty) {
      return widget.categoryNames;
    }
    return visible;
  }

  void _applyDraftToControllers(Map<String, double> draft) {
    setState(() {
      for (final entry in draft.entries) {
        final controller = _controllers[entry.key];
        if (controller != null) {
          controller.text = entry.value.toStringAsFixed(2);
        }
      }
    });
  }
}
