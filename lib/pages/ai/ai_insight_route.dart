import 'package:flutter/material.dart';

import '../../utils/ledger_formatters.dart';
import 'ai_insight_page.dart';

/// 独立路由包装，供首页 AI 预警卡片跳转，不影响底部导航。
class AiInsightRoute extends StatefulWidget {
  const AiInsightRoute({
    super.key,
    required this.initialMonth,
  });

  final DateTime initialMonth;

  @override
  State<AiInsightRoute> createState() => _AiInsightRouteState();
}

class _AiInsightRouteState extends State<AiInsightRoute> {
  late DateTime _selectedMonth = monthStart(widget.initialMonth);

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });
  }

  bool get _canGoNextMonth =>
      _selectedMonth.isBefore(monthStart(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 分析')),
      body: AiInsightPage(
        selectedMonth: _selectedMonth,
        canGoNextMonth: _canGoNextMonth,
        onPreviousMonth: () => _changeMonth(-1),
        onNextMonth: () => _changeMonth(1),
      ),
    );
  }
}
