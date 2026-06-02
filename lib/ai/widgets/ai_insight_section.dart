import 'package:flutter/material.dart';

import '../../data/ledger_store.dart';
import '../../pages/profile/budget_management_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/ledger_formatters.dart';
import '../models/ai_insight_models.dart';
import '../services/ai_budget_apply_service.dart';
import '../services/ai_insight_explainer.dart';
import '../services/ai_suggestion_batch_apply_service.dart';

const _budgetApplyService = AiBudgetApplyService();
const _suggestionBatchApplyService = AiSuggestionBatchApplyService();

class AiInsightSection extends StatelessWidget {
  const AiInsightSection({
    super.key,
    required this.snapshot,
    required this.explainer,
    this.selectedMonth,
    this.defaultExpandRiskAndAnomaly = false,
    this.highlightRiskAndAnomaly = false,
    this.budgetRiskSectionKey,
    this.anomalySectionKey,
    this.onBudgetRiskOpened,
    this.onAnomalyOpened,
  });

  final AiInsightSnapshot snapshot;
  final AiInsightExplainer explainer;
  final DateTime? selectedMonth;
  final bool defaultExpandRiskAndAnomaly;
  final bool highlightRiskAndAnomaly;
  final Key? budgetRiskSectionKey;
  final Key? anomalySectionKey;
  final VoidCallback? onBudgetRiskOpened;
  final VoidCallback? onAnomalyOpened;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final risk = snapshot.budgetRisk;
    final riskTag = switch (risk.riskLevel) {
      AiRiskLevel.safe => '安全',
      AiRiskLevel.attention => '关注',
      AiRiskLevel.warning => '预警',
    };

    final overviewTitle = monthOverviewLabel(
      selectedMonth ?? snapshot.generatedAt,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InsightAccordion(
          icon: Icons.analytics_outlined,
          title: overviewTitle,
          subtitle: explainer.overviewCardText(snapshot),
          trailingText: formatCurrency(snapshot.overview.totalExpense),
          trailingColor: colors.textPrimary,
          expandedChild: _OverviewDetails(snapshot: snapshot),
        ),
        const SizedBox(height: 10),
        _InsightAccordion(
          sectionKey: budgetRiskSectionKey,
          icon: Icons.savings_outlined,
          title: '预算风险',
          subtitle: explainer.budgetRiskCardText(snapshot),
          trailingText: riskTag,
          trailingColor: switch (risk.riskLevel) {
            AiRiskLevel.safe => colors.primary,
            AiRiskLevel.attention => colors.info,
            AiRiskLevel.warning => colors.danger,
          },
          initiallyExpanded: defaultExpandRiskAndAnomaly,
          highlighted: highlightRiskAndAnomaly,
          onExpansionChanged: onBudgetRiskOpened,
          expandedChild: _BudgetRiskDetails(snapshot: snapshot),
          actionLabel: '去预算管理',
          onAction: () => _goBudgetManagement(context),
        ),
        const SizedBox(height: 10),
        _InsightAccordion(
          sectionKey: anomalySectionKey,
          icon: Icons.warning_amber_outlined,
          title: '异常消费',
          subtitle: explainer.anomalyCardText(snapshot),
          trailingText: '${snapshot.anomalies.items.length} 条',
          trailingColor: colors.textPrimary,
          initiallyExpanded: defaultExpandRiskAndAnomaly,
          highlighted: highlightRiskAndAnomaly,
          onExpansionChanged: onAnomalyOpened,
          expandedChild: _AnomalyDetails(snapshot: snapshot),
        ),
        const SizedBox(height: 10),
        _InsightAccordion(
          icon: Icons.tips_and_updates_outlined,
          title: '下月建议',
          subtitle: explainer.suggestionCardText(snapshot),
          trailingText: snapshot.budgetSuggestion.totalSuggested > 0
              ? formatCurrency(snapshot.budgetSuggestion.totalSuggested)
              : '暂无',
          trailingColor: colors.primary,
          expandedChild: _SuggestionDetails(snapshot: snapshot),
          actionLabel: snapshot.budgetSuggestion.byCategory.isNotEmpty
              ? '按分类建议批量应用'
              : null,
          onAction: snapshot.budgetSuggestion.byCategory.isNotEmpty
              ? () => _applyCategorySuggestionsToNextMonth(context)
              : null,
          secondaryActionLabel: snapshot.budgetSuggestion.totalSuggested > 0
              ? '应用到下月预算'
              : null,
          onSecondaryAction: snapshot.budgetSuggestion.totalSuggested > 0
              ? () => _applySuggestionToNextMonth(context)
              : null,
        ),
        const SizedBox(height: 12),
        _InlineQaPanel(snapshot: snapshot, explainer: explainer),
      ],
    );
  }

  Future<void> _goBudgetManagement(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const BudgetManagementPage(),
      ),
    );
  }

  Future<void> _applySuggestionToNextMonth(BuildContext context) async {
    final shouldApply = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('应用预算建议'),
        content: Text(
          '将建议预算 ${formatCurrency(snapshot.budgetSuggestion.totalSuggested)} 应用到下月预算？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('应用'),
          ),
        ],
      ),
    );
    if (shouldApply != true) {
      return;
    }
    final applied = await _budgetApplyService.applySuggestionToNextMonth(
      suggestedBudget: snapshot.budgetSuggestion.totalSuggested,
      onApply: ({required month, required amount}) async {
        await ledgerStore.setMonthlyBudget(month: month, amount: amount);
      },
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(applied ? '已应用到下月预算' : '建议预算无效，未执行应用')),
    );
  }

  Future<void> _applyCategorySuggestionsToNextMonth(
    BuildContext context,
  ) async {
    final shouldApply = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量应用分类建议'),
        content: const Text('将分类建议汇总后应用为下月总预算？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('应用'),
          ),
        ],
      ),
    );
    if (shouldApply != true) {
      return;
    }
    final applied = await _suggestionBatchApplyService
        .applyCategorySuggestionsToNextMonth(
          suggestions: snapshot.budgetSuggestion.byCategory,
          onApply:
              ({
                required month,
                required amount,
                required categoryBudgets,
              }) async {
                await ledgerStore.setCategoryBudgetsForMonth(
                  month: month,
                  categoryBudgets: categoryBudgets,
                  syncTotalBudget: true,
                );
              },
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(applied ? '已按分类建议批量应用到下月预算' : '分类建议为空，未执行应用')),
    );
  }
}

class _InsightAccordion extends StatelessWidget {
  const _InsightAccordion({
    this.sectionKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.trailingColor,
    required this.expandedChild,
    this.initiallyExpanded = false,
    this.highlighted = false,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.onExpansionChanged,
  });

  final Key? sectionKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailingText;
  final Color trailingColor;
  final Widget expandedChild;
  final bool initiallyExpanded;
  final bool highlighted;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      key: sectionKey,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: highlighted
            ? Color.alphaBlend(
                colors.primary.withValues(alpha: 0.10),
                colors.surface,
              )
            : colors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: highlighted
              ? colors.primary.withValues(alpha: 0.75)
              : colors.surfaceBorder,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: (_) => onExpansionChanged?.call(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: AppDecorations.softFill(context),
                child: Icon(icon, size: 18, color: colors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyStrong(context)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.bodyMuted(context)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                trailingText,
                style: AppTextStyles.amount(context, trailingColor),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 6),
            expandedChild,
            if ((actionLabel != null && onAction != null) ||
                (secondaryActionLabel != null &&
                    onSecondaryAction != null)) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (actionLabel != null && onAction != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ),
                  if (actionLabel != null &&
                      onAction != null &&
                      secondaryActionLabel != null &&
                      onSecondaryAction != null)
                    const SizedBox(width: 8),
                  if (secondaryActionLabel != null && onSecondaryAction != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: onSecondaryAction,
                        child: Text(secondaryActionLabel!),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverviewDetails extends StatelessWidget {
  const _OverviewDetails({required this.snapshot});

  final AiInsightSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final overview = snapshot.overview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• 本月收入：${formatCurrency(overview.totalIncome)}',
          style: AppTextStyles.bodyMuted(context),
        ),
        Text(
          '• 本月支出：${formatCurrency(overview.totalExpense)}',
          style: AppTextStyles.bodyMuted(context),
        ),
        Text(
          '• 本月结余：${formatCurrency(overview.balance)}',
          style: AppTextStyles.bodyMuted(context),
        ),
        if (overview.topCategories.isNotEmpty)
          Text(
            '• 支出最高分类：${overview.topCategories.first.category}',
            style: AppTextStyles.bodyMuted(context),
          ),
      ],
    );
  }
}

class _BudgetRiskDetails extends StatelessWidget {
  const _BudgetRiskDetails({required this.snapshot});

  final AiInsightSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final risk = snapshot.budgetRisk;
    final usagePercent = (risk.usageRate * 100).toStringAsFixed(0);
    final timePercent = (risk.timeProgress * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (risk.hasBudget) ...[
          Text(
            '• 预算使用率：$usagePercent%',
            style: AppTextStyles.bodyMuted(context),
          ),
          Text('• 时间进度：$timePercent%', style: AppTextStyles.bodyMuted(context)),
          Text(
            '• 预计偏差：${formatCurrency(risk.forecastOverrun, signed: true)}',
            style: AppTextStyles.bodyMuted(context),
          ),
        ] else
          Text('• 当前账本未设置预算', style: AppTextStyles.bodyMuted(context)),
        Text(
          '• 建议：${risk.suggestion}',
          style: AppTextStyles.bodyMuted(context),
        ),
      ],
    );
  }
}

class _AnomalyDetails extends StatelessWidget {
  const _AnomalyDetails({required this.snapshot});

  final AiInsightSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final items = snapshot.anomalies.items;
    if (items.isEmpty) {
      return Text('• 未检测到明显异常消费。', style: AppTextStyles.bodyMuted(context));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: AppDecorations.softFill(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.title} · ${formatCurrency(item.amount)}',
                    style: AppTextStyles.bodyStrong(context),
                  ),
                  const SizedBox(height: 4),
                  Text(item.reason, style: AppTextStyles.bodyMuted(context)),
                  if (item.records.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('异常账单：', style: AppTextStyles.bodyStrong(context)),
                    const SizedBox(height: 4),
                    for (final record in item.records)
                      Text(
                        '• ${formatRecordDate(record.createdAt)} · ${record.category} · ${record.title} · ${formatCurrency(record.amount)}',
                        style: AppTextStyles.bodyMuted(context),
                      ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SuggestionDetails extends StatelessWidget {
  const _SuggestionDetails({required this.snapshot});

  final AiInsightSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final items = snapshot.budgetSuggestion.byCategory;
    if (items.isEmpty) {
      return Text(
        '• 近期数据不足，建议先持续记录后再应用建议。',
        style: AppTextStyles.bodyMuted(context),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Text(
            '• ${item.category}：建议 ${formatCurrency(item.suggestedBudget)} (较本月 ${formatCurrency(item.delta, signed: true)})',
            style: AppTextStyles.bodyMuted(context),
          ),
      ],
    );
  }
}

class _InlineQaPanel extends StatefulWidget {
  const _InlineQaPanel({required this.snapshot, required this.explainer});

  final AiInsightSnapshot snapshot;
  final AiInsightExplainer explainer;

  @override
  State<_InlineQaPanel> createState() => _InlineQaPanelState();
}

class _InlineQaPanelState extends State<_InlineQaPanel> {
  String? _selectedQuestionId;
  AiInsightAnswer? _answer;

  void _onQuestionTap(AiQuestionOption question) {
    setState(() {
      if (_selectedQuestionId == question.id) {
        _selectedQuestionId = null;
        _answer = null;
        return;
      }
      _selectedQuestionId = question.id;
      _answer = widget.explainer.answer(
        questionId: question.id,
        snapshot: widget.snapshot,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text('预设问题', style: AppTextStyles.bodyStrong(context)),
            ],
          ),
          const SizedBox(height: 4),
          Text('点击问题查看分析，再次点击可收起', style: AppTextStyles.bodyMuted(context)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final question in AiInsightExplainer.defaultQuestions)
                    SizedBox(
                      width: itemWidth,
                      child: _QuestionChip(
                        label: question.label,
                        selected: _selectedQuestionId == question.id,
                        onTap: () => _onQuestionTap(question),
                      ),
                    ),
                ],
              );
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: _answer == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.04),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _AnswerPanel(
                        key: ValueKey<String>(_selectedQuestionId!),
                        answer: _answer!,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuestionChip extends StatelessWidget {
  const _QuestionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    colors.primary.withValues(alpha: 0.12),
                    colors.surface,
                  )
                : colors.softFill,
            borderRadius: AppRadii.card,
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.65)
                  : colors.surfaceBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: selected
                      ? AppTextStyles.bodyStrong(
                          context,
                        ).copyWith(color: colors.primary)
                      : AppTextStyles.bodyMuted(
                          context,
                        ).copyWith(color: colors.textPrimary),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle, size: 16, color: colors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerPanel extends StatelessWidget {
  const _AnswerPanel({super.key, required this.answer});

  final AiInsightAnswer answer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.primary.withValues(alpha: 0.06),
          colors.softFill,
        ),
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.surfaceBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: colors.primary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer.title,
                      style: AppTextStyles.bodyStrong(context),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      answer.summary,
                      style: AppTextStyles.bodyMuted(context),
                    ),
                    if (answer.suggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final tip in answer.suggestions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• $tip',
                            style: AppTextStyles.bodyMuted(context),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
