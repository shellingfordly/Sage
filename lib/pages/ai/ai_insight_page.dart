import 'package:flutter/material.dart';

import '../../models/ai_insight_models.dart';
import '../../services/ai/ai_alert_ack_store.dart';
import '../../services/ai/ai_insight_cache.dart';
import '../../services/ai/ai_insight_engine.dart';
import '../../services/ai/ai_insight_explainer.dart';
import 'widgets/ai_insight_section.dart';
import '../../data/ledger_store.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/ledger_formatters.dart';
import '../../components/nav/month_nav_row.dart';

const _aiInsightEngine = AiInsightEngine();
const _aiInsightExplainer = AiInsightExplainer();
final _aiInsightCache = AiInsightCache();

class AiInsightPage extends StatefulWidget {
  const AiInsightPage({
    super.key,
    required this.selectedMonth,
    required this.canGoNextMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.entrySequence = 0,
    this.expandRiskAndAnomalyOnEntry = false,
  });

  final DateTime selectedMonth;
  final bool canGoNextMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final int entrySequence;
  final bool expandRiskAndAnomalyOnEntry;

  @override
  State<AiInsightPage> createState() => _AiInsightPageState();
}

class _AiInsightPageState extends State<AiInsightPage> {
  final _scrollController = ScrollController();

  bool _highlightRiskAndAnomaly = false;
  int _entryBehaviorToken = 0;

  @override
  void initState() {
    super.initState();
    _applyEntryBehaviorIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AiInsightPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMonth != oldWidget.selectedMonth) {
      _entryBehaviorToken++;
      if (_highlightRiskAndAnomaly) {
        _highlightRiskAndAnomaly = false;
      }
    }
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
    final token = ++_entryBehaviorToken;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || token != _entryBehaviorToken) {
        return;
      }
      await _scrollController.animateTo(
        180,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      if (!mounted || token != _entryBehaviorToken) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted || token != _entryBehaviorToken) {
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
          final monthReference = monthReferenceDate(
            widget.selectedMonth,
            now: now,
          );
          final budget = ledgerStore.monthlyBudgetFor(widget.selectedMonth);
          final snapshot = _aiInsightCache.getOrBuild(
            ledgerId: ledgerStore.currentLedger.id,
            records: ledgerStore.records,
            monthlyBudget: budget,
            mode: AiSuggestionMode.balanced,
            now: monthReference,
            builder: () => _aiInsightEngine.buildSnapshot(
              records: ledgerStore.records,
              monthlyBudget: budget,
              mode: AiSuggestionMode.balanced,
              now: monthReference,
            ),
          );

          return SingleChildScrollView(
            controller: _scrollController,
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonthNavRow(
                  title: formatAiAnalysisTitle(widget.selectedMonth, now: now),
                  canGoPrevious: true,
                  canGoNext: widget.canGoNextMonth,
                  onPrevious: widget.onPreviousMonth,
                  onNext: widget.onNextMonth,
                ),
                const SizedBox(height: 4),
                Text(
                  aiAnalysisSubtitleForMonth(widget.selectedMonth, now: now),
                  style: AppTextStyles.pageSubtitle(context),
                ),
                const SizedBox(height: 16),
                AiInsightSection(
                  key: ValueKey('ai-insight-section-${widget.entrySequence}'),
                  snapshot: snapshot,
                  explainer: _aiInsightExplainer,
                  selectedMonth: widget.selectedMonth,
                  defaultExpandRiskAndAnomaly:
                      widget.expandRiskAndAnomalyOnEntry,
                  highlightRiskAndAnomaly: _highlightRiskAndAnomaly,
                  onBudgetRiskOpened: () {
                    aiAlertAckStore.acknowledgeBudget(
                      ledgerId: ledgerStore.currentLedger.id,
                      snapshot: snapshot,
                    );
                  },
                  onAnomalyOpened: () {
                    aiAlertAckStore.acknowledgeAnomaly(
                      ledgerId: ledgerStore.currentLedger.id,
                      snapshot: snapshot,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
