import 'package:flutter/material.dart';

import '../../models/ai_insight_scope.dart';
import 'ai_insight_page.dart';

/// 独立路由包装，供首页或统计页跳转，不影响底部导航。
class AiInsightRoute extends StatelessWidget {
  const AiInsightRoute({
    super.key,
    required this.scope,
  });

  final AiInsightScope scope;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分析')),
      body: AiInsightPage(scope: scope),
    );
  }
}
