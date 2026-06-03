import 'package:flutter/material.dart';

import '../../components/pickers/record_date_picker.dart';
import 'package:ledger_app/components/time_range/export_range.dart';
import 'package:ledger_app/components/time_range/time_range_panel.dart';
import '../../data/ledger_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/ledger_formatters.dart';
import 'analysis_query.dart';
import 'widgets/analysis_filter_bar.dart';
import 'widgets/analysis_record_list.dart';

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
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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

  bool get _hasActiveFilters {
    return _filters.typeFilter != AnalysisTypeFilter.all ||
        _filters.category != null ||
        _filters.searchQuery.trim().isNotEmpty;
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
          final hasMore = visibleRecords.length < result.records.length;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text('账单分析', style: AppTextStyles.pageTitle(context)),
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
                    AnalysisFilterBar(
                      searchController: _searchController,
                      typeFilter: _filters.typeFilter,
                      selectedCategory: _filters.category,
                      availableCategories: categories,
                      onTypeFilterChanged: _onTypeFilterChanged,
                      onCategoryChanged: _onCategoryChanged,
                      onSearchChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 12),
                    _ResultSummary(
                      count: result.records.length,
                      totalIncome: result.totalIncome,
                      totalExpense: result.totalExpense,
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
              AnalysisRecordList(
                records: visibleRecords,
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

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({
    required this.count,
    required this.totalIncome,
    required this.totalExpense,
  });

  final int count;
  final double totalIncome;
  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecorations.surface(context),
      child: Row(
        children: [
          Text(
            '$count 条记录',
            style: AppTextStyles.bodyStrong(context),
          ),
          const Spacer(),
          Text(
            '支出 ${formatCurrency(totalExpense)}',
            style: AppTextStyles.bodyMuted(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '收入 ${formatCurrency(totalIncome)}',
            style: AppTextStyles.bodyMuted(context).copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
