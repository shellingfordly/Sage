import 'package:flutter/material.dart';

import '../../components/pickers/record_date_picker.dart';
import 'package:ledger_app/components/time_range/export_range.dart';
import 'package:ledger_app/components/time_range/time_range_panel.dart';
import '../../data/ledger_store.dart';
import '../../models/ai_insight_scope.dart';
import '../ai/ai_insight_route.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/ledger_formatters.dart';
import 'analysis_navigation.dart';
import 'analysis_query.dart';
import 'widgets/analysis_filter_bar.dart';
import 'widgets/analysis_record_list.dart';
import 'widgets/analysis_record_toolbar.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  AnalysisFilters _filters = const AnalysisFilters();
  DateTimeRange? _customRange;
  int _visibleCount = analysisRecordPageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    analysisNavigationController.addListener(_onNavigationIntent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPendingDrillDownIfNeeded();
    });
  }

  @override
  void dispose() {
    analysisNavigationController.removeListener(_onNavigationIntent);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onNavigationIntent() {
    if (analysisNavigationController.pending == null) {
      return;
    }
    _applyPendingDrillDownIfNeeded();
  }

  void _applyPendingDrillDownIfNeeded() {
    final drillDown = analysisNavigationController.consumePending();
    if (drillDown == null || !mounted) {
      return;
    }
    _searchController.text = drillDown.searchQuery ?? '';
    setState(() {
      _customRange = drillDown.dateRange;
      _filters = drillDown.toFilters();
      _visibleCount = analysisRecordPageSize;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      _loadMoreRecords();
    }
  }

  void _loadMoreRecords() {
    final total = queryAnalysisRecords(ledgerStore.records, _filters)
        .records
        .length;
    if (_visibleCount >= total) {
      return;
    }
    setState(() {
      _visibleCount = (_visibleCount + analysisRecordPageSize).clamp(0, total);
    });
  }

  void _applyFilters(AnalysisFilters filters) {
    setState(() {
      _filters = filters;
      _visibleCount = analysisRecordPageSize;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onRangeChanged(ExportRange range) {
    if (range == ExportRange.custom && _customRange == null) {
      final now = DateTime.now();
      _customRange = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, now.day),
      );
    }
    _applyFilters(
      _filters.copyWith(range: range, customRange: _customRange),
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialRange = _customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );
    final picked = await pickCustomDateRange(
      context,
      initialStart: initialRange.start,
      initialEnd: initialRange.end,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: '选择查询时间范围',
    );
    if (picked == null) {
      return;
    }
    setState(() => _customRange = picked);
    _applyFilters(_filters.copyWith(customRange: picked));
  }

  void _onClearCustomRange() {
    setState(() => _customRange = null);
    _applyFilters(_filters.copyWith(customRange: null));
  }

  void _onTypeFilterChanged(AnalysisTypeFilter typeFilter) {
    _applyFilters(
      _filters.copyWith(typeFilter: typeFilter, category: null),
    );
  }

  void _onCategoryChanged(String? category) {
    _applyFilters(_filters.copyWith(category: category));
  }

  void _onSearchChanged() {
    _applyFilters(_filters.copyWith(searchQuery: _searchController.text));
  }

  void _onSortChanged(AnalysisSortOption sort) {
    _applyFilters(_filters.copyWith(sort: sort));
  }

  void _openAiInsightPage(DateTime now) {
    final scope = AiInsightScope.fromExportRange(
      range: _filters.range,
      customRange: _customRange,
      now: now,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AiInsightRoute(scope: scope),
      ),
    );
  }

  bool get _hasActiveFilters {
    return _filters.typeFilter != AnalysisTypeFilter.all ||
        _filters.category != null ||
        _filters.searchQuery.trim().isNotEmpty ||
        _filters.consumptionOnly;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: ledgerStore,
        builder: (context, child) {
          final today = DateTime.now();
          final periodRangeText = currentExportRangeText(
            range: _filters.range,
            customRange: _customRange,
            now: today,
          );
          final categories = analysisCategoriesInPeriod(
            ledgerStore.records,
            _filters.copyWith(category: null, searchQuery: ''),
            now: today,
          );
          final result = queryAnalysisRecords(
            ledgerStore.records,
            _filters.copyWith(customRange: _customRange),
            now: today,
          );
          final visibleRecords = result.records
              .take(_visibleCount)
              .toList(growable: false);
          final recordGroups = groupAnalysisRecords(
            visibleRecords,
            range: _filters.range,
            customRange: _customRange,
            now: today,
          );
          final hasMore = visibleRecords.length < result.records.length;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text('统计', style: AppTextStyles.pageTitle(context)),
                    const SizedBox(height: 4),
                    Text(
                      '按时段筛选收支，查看账单明细',
                      style: AppTextStyles.pageSubtitle(context),
                    ),
                    const SizedBox(height: 12),
                    TimeRangePanel(
                      selectedRange: _filters.range,
                      periodRangeText: periodRangeText,
                      customRange: _customRange,
                      onRangeChanged: _onRangeChanged,
                      onPickCustomRange: _pickCustomRange,
                      onClearCustomRange: _onClearCustomRange,
                    ),
                    const SizedBox(height: 12),
                    _AnalysisControlsPanel(
                      typeFilter: _filters.typeFilter,
                      selectedCategory: _filters.category,
                      availableCategories: categories,
                      onTypeFilterChanged: _onTypeFilterChanged,
                      onCategoryChanged: _onCategoryChanged,
                      searchController: _searchController,
                      count: result.records.length,
                      sort: _filters.sort,
                      onSortChanged: _onSortChanged,
                      onSearchChanged: _onSearchChanged,
                      onOpenAiInsight: () => _openAiInsightPage(today),
                    ),
                    const SizedBox(height: 12),
                    _SummaryTiles(
                      totalIncome: result.totalIncome,
                      totalExpense: result.totalExpense,
                    ),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),
              AnalysisRecordList(
                recordGroups: recordGroups,
                totalCount: result.records.length,
                hasActiveFilters: _hasActiveFilters,
                hasMore: hasMore,
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _AnalysisControlsPanel extends StatelessWidget {
  const _AnalysisControlsPanel({
    required this.typeFilter,
    required this.selectedCategory,
    required this.availableCategories,
    required this.onTypeFilterChanged,
    required this.onCategoryChanged,
    required this.searchController,
    required this.count,
    required this.sort,
    required this.onSortChanged,
    required this.onSearchChanged,
    required this.onOpenAiInsight,
  });

  final AnalysisTypeFilter typeFilter;
  final String? selectedCategory;
  final List<String> availableCategories;
  final ValueChanged<AnalysisTypeFilter> onTypeFilterChanged;
  final ValueChanged<String?> onCategoryChanged;
  final TextEditingController searchController;
  final int count;
  final AnalysisSortOption sort;
  final ValueChanged<AnalysisSortOption> onSortChanged;
  final VoidCallback onSearchChanged;
  final VoidCallback onOpenAiInsight;

  @override
  Widget build(BuildContext context) {
    final dividerColor = context.colors.divider.withValues(alpha: 0.85);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalysisFilterBar(
            typeFilter: typeFilter,
            selectedCategory: selectedCategory,
            availableCategories: availableCategories,
            onTypeFilterChanged: onTypeFilterChanged,
            onCategoryChanged: onCategoryChanged,
            showBottomDivider: false,
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          AnalysisRecordToolbar(
            searchController: searchController,
            count: count,
            sort: sort,
            onSortChanged: onSortChanged,
            onSearchChanged: onSearchChanged,
            onOpenAiInsight: onOpenAiInsight,
            decorated: false,
          ),
        ],
      ),
    );
  }
}

class _SummaryTiles extends StatelessWidget {
  const _SummaryTiles({
    required this.totalIncome,
    required this.totalExpense,
  });

  final double totalIncome;
  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            title: '支出',
            amount: formatCurrency(totalExpense),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            title: '收入',
            amount: formatCurrency(totalIncome),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.title,
    required this.amount,
  });

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyMuted(context)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(amount, style: AppTextStyles.tileValue(context)),
          ),
        ],
      ),
    );
  }
}
