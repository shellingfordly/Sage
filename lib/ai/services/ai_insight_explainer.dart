import '../models/ai_insight_models.dart';

class AiInsightExplainer {
  const AiInsightExplainer();

  static const List<AiQuestionOption> defaultQuestions = <AiQuestionOption>[
    AiQuestionOption(id: 'q_overspend_reason', label: '我本月为什么超支？'),
    AiQuestionOption(id: 'q_top_cut_targets', label: '最该控制的三项支出是什么？'),
    AiQuestionOption(id: 'q_fastest_growth', label: '哪一类支出上涨最快？'),
    AiQuestionOption(id: 'q_fixed_vs_variable', label: '固定和可变支出占比如何？'),
    AiQuestionOption(id: 'q_one_habit', label: '只改一个习惯先改什么？'),
    AiQuestionOption(id: 'q_gap_to_goal', label: '离预算目标还差多少？'),
    AiQuestionOption(id: 'q_next_month_plan', label: '下月预算该怎么分配？'),
    AiQuestionOption(id: 'q_recent_anomalies', label: '最近有哪些异常消费？'),
  ];

  String overviewCardText(AiInsightSnapshot snapshot) {
    return snapshot.overview.summary;
  }

  String budgetRiskCardText(AiInsightSnapshot snapshot) {
    return snapshot.budgetRisk.summary;
  }

  String anomalyCardText(AiInsightSnapshot snapshot) {
    return snapshot.anomalies.summary;
  }

  String suggestionCardText(AiInsightSnapshot snapshot) {
    return snapshot.budgetSuggestion.summary;
  }

  AiInsightAnswer answer({
    required String questionId,
    required AiInsightSnapshot snapshot,
  }) {
    return switch (questionId) {
      'q_overspend_reason' => _overspendReason(snapshot),
      'q_top_cut_targets' => _topCutTargets(snapshot),
      'q_fastest_growth' => _fastestGrowth(snapshot),
      'q_fixed_vs_variable' => _fixedVsVariable(snapshot),
      'q_one_habit' => _oneHabit(snapshot),
      'q_gap_to_goal' => _gapToGoal(snapshot),
      'q_next_month_plan' => _nextMonthPlan(snapshot),
      'q_recent_anomalies' => _recentAnomalies(snapshot),
      _ => AiInsightAnswer(
        questionId: questionId,
        title: '暂未支持',
        summary: '这个问题还在扩展中，你可以先使用其他问题查看已有分析。',
        suggestions: const <String>[],
      ),
    };
  }

  AiInsightAnswer _overspendReason(AiInsightSnapshot snapshot) {
    final budget = snapshot.budgetRisk;
    final top = snapshot.overview.topCategories.isEmpty
        ? null
        : snapshot.overview.topCategories.first;
    final overrun = budget.forecastOverrun;
    final summary = !budget.hasBudget
        ? '当前没有设置预算，无法精准判断超支原因。'
        : overrun > 0
        ? '主要原因是支出节奏快于时间进度，按当前趋势月末可能超支 ¥${overrun.toStringAsFixed(0)}。'
        : '目前支出节奏可控，暂未出现明显超支。';
    return AiInsightAnswer(
      questionId: 'q_overspend_reason',
      title: '超支原因分析',
      summary: summary,
      suggestions: <String>[
        if (top != null) '优先复盘“${top.category}”的高频消费场景。',
        '设置每周支出上限并在周末做一次对账。',
      ],
    );
  }

  AiInsightAnswer _topCutTargets(AiInsightSnapshot snapshot) {
    final tops = snapshot.overview.topCategories.take(3).toList();
    if (tops.isEmpty) {
      return const AiInsightAnswer(
        questionId: 'q_top_cut_targets',
        title: '控支优先项',
        summary: '当前数据不足，继续记录后再生成控支优先项。',
        suggestions: <String>[],
      );
    }
    return AiInsightAnswer(
      questionId: 'q_top_cut_targets',
      title: '控支优先项',
      summary:
          '建议优先控制支出占比最高的三类：${tops.map((item) => item.category).join('、')}。',
      suggestions: tops
          .map(
            (item) =>
                '将${item.category}预算控制在 ¥${(item.amount * 0.85).toStringAsFixed(0)} 左右。',
          )
          .toList(),
    );
  }

  AiInsightAnswer _fastestGrowth(AiInsightSnapshot snapshot) {
    AiAnomalyItem? anomaly;
    for (final item in snapshot.anomalies.items) {
      if (item.title.contains('激增')) {
        anomaly = item;
        break;
      }
    }
    if (anomaly == null) {
      return const AiInsightAnswer(
        questionId: 'q_fastest_growth',
        title: '增长最快分类',
        summary: '本月暂未发现明显分类激增，整体支出较平稳。',
        suggestions: <String>['继续观察每周分类变化，出现持续增长时优先处理。'],
      );
    }
    return AiInsightAnswer(
      questionId: 'q_fastest_growth',
      title: '增长最快分类',
      summary: '${anomaly.category}支出增长较快，${anomaly.reason}',
      suggestions: <String>['为${anomaly.category}设置单周上限，超额时暂缓非必要消费。'],
    );
  }

  AiInsightAnswer _fixedVsVariable(AiInsightSnapshot snapshot) {
    final fixedKeywords = <String>{'居住', '交通', '医疗'};
    final total = snapshot.overview.totalExpense;
    if (total <= 0) {
      return const AiInsightAnswer(
        questionId: 'q_fixed_vs_variable',
        title: '固定/可变支出',
        summary: '本月暂无支出记录，暂无法拆分固定和可变支出。',
        suggestions: <String>[],
      );
    }
    final fixedAmount = snapshot.overview.topCategories
        .where((item) => fixedKeywords.contains(item.category))
        .fold<double>(0, (sum, item) => sum + item.amount);
    final variable = (total - fixedAmount).clamp(0, total);
    final fixedPercent = (fixedAmount / total * 100).toStringAsFixed(0);
    final variablePercent = (variable / total * 100).toStringAsFixed(0);
    return AiInsightAnswer(
      questionId: 'q_fixed_vs_variable',
      title: '固定/可变支出',
      summary: '估算固定支出约 $fixedPercent%，可变支出约 $variablePercent%。',
      suggestions: const <String>['先从可变支出里挑 1-2 个高频场景做限额最有效。'],
    );
  }

  AiInsightAnswer _oneHabit(AiInsightSnapshot snapshot) {
    final top = snapshot.overview.topCategories.isEmpty
        ? null
        : snapshot.overview.topCategories.first;
    if (top == null) {
      return const AiInsightAnswer(
        questionId: 'q_one_habit',
        title: '一个关键习惯',
        summary: '当前数据不足，建议先连续记录两周再生成习惯建议。',
        suggestions: <String>[],
      );
    }
    return AiInsightAnswer(
      questionId: 'q_one_habit',
      title: '一个关键习惯',
      summary: '优先改变“${top.category}”消费前先看预算余额的习惯，通常最容易立即见效。',
      suggestions: <String>['每天首次消费前先查看当日可用额度。', '把${top.category}设置为重点提醒分类。'],
    );
  }

  AiInsightAnswer _gapToGoal(AiInsightSnapshot snapshot) {
    final risk = snapshot.budgetRisk;
    if (!risk.hasBudget) {
      return const AiInsightAnswer(
        questionId: 'q_gap_to_goal',
        title: '目标差距',
        summary: '你还没有设置预算目标，设置后才能计算差距。',
        suggestions: <String>['先在预算管理页设置每月预算。'],
      );
    }
    final gap = risk.monthlyBudget - risk.expense;
    final summary = gap >= 0
        ? '距离本月预算目标还剩 ¥${gap.toStringAsFixed(0)} 可用。'
        : '当前已超出预算目标 ¥${gap.abs().toStringAsFixed(0)}。';
    return AiInsightAnswer(
      questionId: 'q_gap_to_goal',
      title: '目标差距',
      summary: summary,
      suggestions: <String>[
        if (gap < 0) '接下来优先削减可变支出，尽量把日支出降低到当前的 70%-80%。',
        if (gap >= 0) '保持当前节奏，月底前仍建议预留 10% 缓冲。',
      ],
    );
  }

  AiInsightAnswer _nextMonthPlan(AiInsightSnapshot snapshot) {
    final suggestion = snapshot.budgetSuggestion;
    if (suggestion.byCategory.isEmpty) {
      return const AiInsightAnswer(
        questionId: 'q_next_month_plan',
        title: '下月预算规划',
        summary: '最近数据不足，暂无法生成下月预算规划。',
        suggestions: <String>[],
      );
    }
    final top3 = suggestion.byCategory.take(3).toList();
    return AiInsightAnswer(
      questionId: 'q_next_month_plan',
      title: '下月预算规划',
      summary:
          '建议下月总预算 ¥${suggestion.totalSuggested.toStringAsFixed(0)}，重点分配在${top3.map((item) => item.category).join('、')}。',
      suggestions: top3
          .map(
            (item) =>
                '${item.category}建议预算 ¥${item.suggestedBudget.toStringAsFixed(0)}。',
          )
          .toList(),
    );
  }

  AiInsightAnswer _recentAnomalies(AiInsightSnapshot snapshot) {
    if (snapshot.anomalies.items.isEmpty) {
      return const AiInsightAnswer(
        questionId: 'q_recent_anomalies',
        title: '最近异常',
        summary: '最近未识别到明显异常消费。',
        suggestions: <String>['继续保持当前消费节奏，每周复盘一次即可。'],
      );
    }
    final first = snapshot.anomalies.items.first;
    return AiInsightAnswer(
      questionId: 'q_recent_anomalies',
      title: '最近异常',
      summary: '最需要关注的是${first.title}，${first.reason}',
      suggestions: <String>['对该项消费设置提醒，连续两次超阈值时触发人工复盘。'],
    );
  }
}
