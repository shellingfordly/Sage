import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ai_insight_models.dart';
import 'package:ledger_app/services/ai/ai_insight_explainer.dart';
import 'package:ledger_app/pages/ai/widgets/ai_insight_section.dart';
import 'package:ledger_app/theme/app_colors.dart';
import 'package:ledger_app/theme/app_theme.dart';

void main() {
  testWidgets('shows budget management shortcut in budget risk detail', (
    tester,
  ) async {
    final snapshot = _snapshot();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.fromPalette(
          brightness: Brightness.light,
          colors: AppPalette.light,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AiInsightSection(
              snapshot: snapshot,
              explainer: const AiInsightExplainer(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('预算风险'));
    await tester.pumpAndSettle();

    expect(find.text('去预算管理'), findsOneWidget);
  });

  testWidgets('expands risk and anomaly by default when requested', (
    tester,
  ) async {
    final snapshot = _snapshot();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.fromPalette(
          brightness: Brightness.light,
          colors: AppPalette.light,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AiInsightSection(
              snapshot: snapshot,
              explainer: const AiInsightExplainer(),
              defaultExpandRiskAndAnomaly: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('当前账本未设置预算'), findsOneWidget);
    expect(find.textContaining('未检测到明显异常消费。'), findsOneWidget);
    expect(find.textContaining('本月收入'), findsNothing);
  });

  testWidgets('shows inline answer when tapping preset question', (
    tester,
  ) async {
    final snapshot = _snapshot();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.fromPalette(
          brightness: Brightness.light,
          colors: AppPalette.light,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AiInsightSection(
              snapshot: snapshot,
              explainer: const AiInsightExplainer(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('我本月为什么超支？'));
    await tester.pumpAndSettle();

    expect(find.text('超支原因分析'), findsOneWidget);
  });

  testWidgets('notifies when budget risk or anomaly accordion is tapped', (
    tester,
  ) async {
    final snapshot = _snapshot();
    var budgetOpened = false;
    var anomalyOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.fromPalette(
          brightness: Brightness.light,
          colors: AppPalette.light,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AiInsightSection(
              snapshot: snapshot,
              explainer: const AiInsightExplainer(),
              onBudgetRiskOpened: () => budgetOpened = true,
              onAnomalyOpened: () => anomalyOpened = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('预算风险'));
    await tester.pumpAndSettle();
    expect(budgetOpened, isTrue);

    await tester.tap(find.text('异常消费'));
    await tester.pumpAndSettle();
    expect(anomalyOpened, isTrue);
  });
}

AiInsightSnapshot _snapshot() {
  return AiInsightSnapshot(
    overview: const AiOverviewInsight(
      totalIncome: 5000,
      totalExpense: 1200,
      balance: 3800,
      dailyAvgExpense: 60,
      topCategories: <AiCategoryShare>[
        AiCategoryShare(category: '餐饮', amount: 600, percent: 0.5),
      ],
      summary: 'summary',
    ),
    budgetRisk: const AiBudgetRiskInsight(
      hasBudget: false,
      monthlyBudget: 0,
      expense: 1200,
      usageRate: 0,
      timeProgress: 0.5,
      forecastOverrun: 0,
      riskLevel: AiRiskLevel.attention,
      summary: 'risk summary',
      suggestion: 'risk suggestion',
    ),
    anomalies: const AiAnomalyInsight(
      items: <AiAnomalyItem>[],
      summary: 'anomaly summary',
    ),
    budgetSuggestion: const AiBudgetSuggestionInsight(
      mode: AiSuggestionMode.balanced,
      totalSuggested: 3000,
      byCategory: <AiCategoryBudgetSuggestion>[
        AiCategoryBudgetSuggestion(
          category: '餐饮',
          currentMonthSpend: 1000,
          suggestedBudget: 900,
          delta: -100,
        ),
      ],
      summary: 'suggestion summary',
    ),
    generatedAt: DateTime(2026, 6, 1),
  );
}
