import 'package:flutter/material.dart';

import '../ai/models/ai_insight_models.dart';
import '../ai/services/ai_insight_cache.dart';
import '../ai/services/ai_insight_engine.dart';
import '../ai/services/ai_insight_explainer.dart';
import '../ai/widgets/ai_insight_section.dart';
import '../data/ledger_store.dart';
import '../theme/app_styles.dart';
import '../theme/app_text_styles.dart';

const _aiInsightEngine = AiInsightEngine();
const _aiInsightExplainer = AiInsightExplainer();
final _aiInsightCache = AiInsightCache();

class AiInsightPage extends StatefulWidget {
  const AiInsightPage({
    super.key,
    this.entrySequence = 0,
    this.expandRiskAndAnomalyOnEntry = false,
  });

  final int entrySequence;
  final bool expandRiskAndAnomalyOnEntry;

  @override
  State<AiInsightPage> createState() => _AiInsightPageState();
}

class _AiInsightPageState extends State<AiInsightPage> {
  final _scrollController = ScrollController();
  final _riskSectionKey = GlobalKey();
  final _anomalySectionKey = GlobalKey();

  bool _highlightRiskAndAnomaly = false;

  @override
  void initState() {
    super.initState();
    _applyEntryBehaviorIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AiInsightPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entrySequence != oldWidget.entrySequence ||
        widget.expandRiskAndAnomalyOnEntry !=
            oldWidget.expandRiskAndAnomalyOnEntry) {
      _applyEntryBehaviorIfNeeded();
    }
  }

  void _applyEntryBehaviorIfNeeded() {
    if (!widget.expandRiskAndAnomalyOnEntry) {
      if (_highlightRiskAndAnomaly) {
        setState(() => _highlightRiskAndAnomaly = false);
      }
      return;
    }
    setState(() => _highlightRiskAndAnomaly = true);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final context = _riskSectionKey.currentContext;
      if (context != null) {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          alignment: 0.15,
        );
      } else {
        await _scrollController.animateTo(
          180,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
      if (!mounted) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) {
        return;
      }
      setState(() => _highlightRiskAndAnomaly = false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: ledgerStore,
        builder: (context, child) {
          final now = DateTime.now();
          final budget = ledgerStore.monthlyBudgetFor(now);
          final snapshot = _aiInsightCache.getOrBuild(
            ledgerId: ledgerStore.currentLedger.id,
            records: ledgerStore.records,
            monthlyBudget: budget,
            mode: AiSuggestionMode.balanced,
            now: now,
            builder: () => _aiInsightEngine.buildSnapshot(
              records: ledgerStore.records,
              monthlyBudget: budget,
              mode: AiSuggestionMode.balanced,
              now: now,
            ),
          );
          return SingleChildScrollView(
            controller: _scrollController,
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI 分析', style: AppTextStyles.pageTitle(context)),
                const SizedBox(height: 4),
                Text(
                  '预算预警、异常消费与优化建议',
                  style: AppTextStyles.pageSubtitle(context),
                ),
                const SizedBox(height: 16),
                AiInsightSection(
                  key: ValueKey('ai-insight-section-${widget.entrySequence}'),
                  snapshot: snapshot,
                  explainer: _aiInsightExplainer,
                  defaultExpandRiskAndAnomaly:
                      widget.expandRiskAndAnomalyOnEntry,
                  highlightRiskAndAnomaly: _highlightRiskAndAnomaly,
                  budgetRiskSectionKey: _riskSectionKey,
                  anomalySectionKey: _anomalySectionKey,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
