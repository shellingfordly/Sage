import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ai_insight_models.dart';
import 'package:ledger_app/models/ai_insight_scope.dart';
import 'package:ledger_app/pages/ai/widgets/ai_insight_section.dart';
import 'package:ledger_app/theme/app_colors.dart';
import 'package:ledger_app/theme/app_theme.dart';
import '../../../services/ai/ai_insight_test_helpers.dart';

void main() {
  testWidgets('shows headline and comparison panels', (tester) async {
    final snapshot = testInsightSnapshot();

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
              scope: AiInsightScope.fromMonth(DateTime(2026, 6, 1)),
            ),
          ),
        ),
      ),
    );

    expect(find.text('核心结论'), findsOneWidget);
    expect(find.text('时段对比'), findsOneWidget);
    expect(find.text('值得关注'), findsOneWidget);
    expect(find.text('查看账单'), findsOneWidget);
  });

  testWidgets('shows next month budget panel only for single month scope', (
    tester,
  ) async {
    final snapshot = testInsightSnapshot();

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
              scope: AiInsightScope.fromMonth(DateTime(2026, 6, 1)),
            ),
          ),
        ),
      ),
    );

    expect(find.text('下月预算建议'), findsOneWidget);
  });

  testWidgets('hides next month budget panel for multi-month scope', (
    tester,
  ) async {
    final snapshot = testInsightSnapshot(
      comparison: testComparison(currentExpense: 5000, previousExpense: 4000),
    );

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
              scope: AiInsightScope(
                start: DateTime(2026, 1, 1),
                end: DateTime(2026, 12, 31, 23, 59, 59),
                label: '2026/01/01 - 2026/12/31',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('下月预算建议'), findsNothing);
  });

  testWidgets('shows monthly volatility panel for multi-month data', (
    tester,
  ) async {
    final snapshot = testInsightSnapshot(
      monthlyVolatility: testMonthlyVolatility(
        peakMonth: FinanceMonthExpense(
          month: DateTime(2026, 6, 1),
          expense: 3000,
          deviationFromAverage: 2000,
          deviationPercent: 2.0,
          topCategory: '餐饮',
          topCategoryAmount: 1800,
        ),
        monthlyTotals: <FinanceMonthExpense>[
          FinanceMonthExpense(
            month: DateTime(2026, 6, 1),
            expense: 3000,
            deviationFromAverage: 2000,
            deviationPercent: 2.0,
            topCategory: '餐饮',
            topCategoryAmount: 1800,
          ),
          FinanceMonthExpense(
            month: DateTime(2026, 5, 1),
            expense: 1000,
            deviationFromAverage: 0,
            deviationPercent: 0,
          ),
        ],
        periodAverage: 1000,
      ),
    );

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
              scope: AiInsightScope(
                start: DateTime(2026, 1, 1),
                end: DateTime(2026, 12, 31, 23, 59, 59),
                label: '2026/01/01 - 2026/12/31',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('波动最大月份'), findsOneWidget);
    expect(find.textContaining('2026年6月'), findsOneWidget);
    expect(find.text('查看该月账单'), findsOneWidget);
    expect(find.text('查看该月餐饮'), findsOneWidget);
  });

  testWidgets('shows drill-down link on category change row', (tester) async {
    final snapshot = testInsightSnapshot(
      comparison: FinanceComparisonInsight(
        currentExpense: 1500,
        previousExpense: 1000,
        changeAmount: 500,
        changePercent: 0.5,
        previousPeriodLabel: '上一时段',
        categoryChanges: const <FinanceCategoryChange>[
          FinanceCategoryChange(
            category: '餐饮',
            currentAmount: 900,
            previousAmount: 400,
            changeAmount: 500,
            changePercent: 1.25,
          ),
        ],
        summary: 'summary',
      ),
    );

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
              scope: AiInsightScope.fromMonth(DateTime(2026, 6, 1)),
            ),
          ),
        ),
      ),
    );

    expect(find.text('分类变化'), findsOneWidget);
    expect(find.text('查看账单'), findsWidgets);
  });
}
