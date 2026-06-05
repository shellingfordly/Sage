import '../../models/ai_insight_models.dart';
import '../../models/ai_insight_scope.dart';
import '../../utils/ledger_formatters.dart';
import '../../utils/record_import_parser.dart';

class FinanceHeadlineAnalyzer {
  const FinanceHeadlineAnalyzer();

  List<FinanceHeadline> analyze({
    required AiInsightScope scope,
    required FinanceComparisonInsight comparison,
    required FinanceMonthlyVolatilityInsight monthlyVolatility,
    required AiOverviewInsight overview,
    required AiBudgetRiskInsight budgetRisk,
    required AiAnomalyInsight anomalies,
  }) {
    final headlines = <FinanceHeadline>[];

    if (comparison.currentExpense > 0 || comparison.previousExpense > 0) {
      headlines.add(
        FinanceHeadline(
          kind: FinanceHeadlineKind.comparison,
          text: comparison.summary,
        ),
      );
    }

    if (monthlyVolatility.hasMultiMonthData &&
        monthlyVolatility.summary.isNotEmpty) {
      headlines.add(
        FinanceHeadline(
          kind: FinanceHeadlineKind.monthlyPeak,
          text: monthlyVolatility.summary,
        ),
      );
    } else {
      final topIncrease = comparison.categoryChanges
          .where((item) => item.changeAmount >= 80)
          .toList();
      if (topIncrease.isNotEmpty) {
        final change = topIncrease.first;
        final cluster = change.cluster;
        final percent = (change.changePercent.abs() * 100).toStringAsFixed(0);
        var text =
            '${change.category} 较上一时段增加 $percent%，增加 ${formatCurrency(change.changeAmount)}。';
        if (cluster != null) {
          text +=
              ' 其中 ${cluster.count} 笔集中在 ${formatDateSlash(cluster.start)}-${formatDateSlash(cluster.end)}。';
        }
        headlines.add(
          FinanceHeadline(
            kind: FinanceHeadlineKind.categoryShift,
            text: text,
          ),
        );
      } else if (overview.topCategories.isNotEmpty &&
          overview.totalExpense > 0) {
        final top = overview.topCategories.first;
        final percent = (top.percent * 100).toStringAsFixed(0);
        headlines.add(
          FinanceHeadline(
            kind: FinanceHeadlineKind.structure,
            text:
                '${scope.label} 消费支出最高的是 ${top.category}，占比约 $percent%，共 ${formatCurrency(top.amount)}。',
          ),
        );
      }
    }

    if (budgetRisk.hasBudget && budgetRisk.riskLevel != AiRiskLevel.safe) {
      headlines.add(
        FinanceHeadline(
          kind: FinanceHeadlineKind.budget,
          text: budgetRisk.summary,
        ),
      );
    } else if (anomalies.items.isNotEmpty) {
      final first = anomalies.items.first;
      headlines.add(
        FinanceHeadline(
          kind: FinanceHeadlineKind.notable,
          text: '值得关注：${first.title} ${formatCurrency(first.amount)}，${first.reason}',
        ),
      );
    } else if (!budgetRisk.hasBudget && headlines.length < 3) {
      headlines.add(
        const FinanceHeadline(
          kind: FinanceHeadlineKind.tip,
          text: '尚未设置预算，可在「我的 - 预算管理」中设置后获得超支预警。',
        ),
      );
    }

    return headlines.take(3).toList();
  }
}
