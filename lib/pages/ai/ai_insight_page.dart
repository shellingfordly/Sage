import 'package:flutter/material.dart';

import '../../models/ai_insight_models.dart';
import '../../models/ai_insight_scope.dart';
import '../../services/ai/ai_insight_cache.dart';
import '../../services/ai/ai_insight_engine.dart';
import 'widgets/ai_insight_section.dart';
import '../../data/ledger_store.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';

const _aiInsightEngine = AiInsightEngine();
final _aiInsightCache = AiInsightCache();

class AiInsightPage extends StatelessWidget {
  const AiInsightPage({
    super.key,
    required this.scope,
  });

  final AiInsightScope scope;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: ledgerStore,
        builder: (context, child) {
          final now = DateTime.now();
          final reference = scope.referenceDate(now);
          final budget = budgetForScope(
            scope,
            ledgerStore.monthlyBudgetFor,
          );
          final snapshot = _aiInsightCache.getOrBuild(
            ledgerId: ledgerStore.currentLedger.id,
            scope: scope,
            records: ledgerStore.records,
            budget: budget,
            mode: AiSuggestionMode.balanced,
            reference: reference,
            builder: () => _aiInsightEngine.buildSnapshot(
              records: ledgerStore.records,
              scope: scope,
              budget: budget,
              mode: AiSuggestionMode.balanced,
              now: reference,
            ),
          );

          return SingleChildScrollView(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scope.label,
                  style: AppTextStyles.pageTitle(context),
                ),
                const SizedBox(height: 4),
                Text(
                  '基于所选时段的消费诊断',
                  style: AppTextStyles.pageSubtitle(context),
                ),
                const SizedBox(height: 16),
                AiInsightSection(
                  snapshot: snapshot,
                  scope: scope,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
