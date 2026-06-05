import 'package:flutter/material.dart';

import 'package:ledger_app/components/time_range/export_range.dart';
import 'analysis_query.dart';

/// 从分析等页面跳转到统计 Tab 时携带的筛选意图。
class AnalysisDrillDown {
  const AnalysisDrillDown({
    required this.dateRange,
    this.typeFilter = AnalysisTypeFilter.expense,
    this.category,
    this.searchQuery,
    this.sort = AnalysisSortOption.timeDesc,
    this.consumptionOnly = false,
  });

  final DateTimeRange dateRange;
  final AnalysisTypeFilter typeFilter;
  final String? category;
  final String? searchQuery;
  final AnalysisSortOption sort;
  final bool consumptionOnly;

  AnalysisFilters toFilters() {
    return AnalysisFilters(
      range: ExportRange.custom,
      customRange: dateRange,
      typeFilter: typeFilter,
      category: category,
      searchQuery: searchQuery ?? '',
      sort: sort,
      consumptionOnly: consumptionOnly,
    );
  }
}

/// 跨 Tab 传递统计页下钻意图；由 [MainShell] 切 Tab，[AnalysisPage] 消费。
class AnalysisNavigationController extends ChangeNotifier {
  AnalysisDrillDown? _pending;

  AnalysisDrillDown? get pending => _pending;

  void open(AnalysisDrillDown drillDown) {
    _pending = drillDown;
    notifyListeners();
  }

  /// 统计页应用筛选后调用，避免重复触发。
  AnalysisDrillDown? consumePending() {
    final value = _pending;
    _pending = null;
    return value;
  }
}

final analysisNavigationController = AnalysisNavigationController();

/// 提交下钻意图并关闭当前路由（通常为分析页）。
void navigateToAnalysisDrillDown(
  BuildContext context,
  AnalysisDrillDown drillDown,
) {
  analysisNavigationController.open(drillDown);
  Navigator.of(context).pop();
}

/// 将 [AiInsightScope] 或子区间转为统计页可用的 [DateTimeRange]。
DateTimeRange drillDownRange({
  required DateTime start,
  required DateTime end,
}) {
  final startDay = DateTime(start.year, start.month, start.day);
  final endDay = DateTime(end.year, end.month, end.day);
  return DateTimeRange(
    start: startDay,
    end: DateTime(endDay.year, endDay.month, endDay.day, 23, 59, 59),
  );
}

DateTimeRange monthDrillDownRange(DateTime month) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  return DateTimeRange(start: start, end: end);
}
