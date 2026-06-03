enum StatisticsPeriod { month, year }

class StatisticsDateRange {
  const StatisticsDateRange({
    required this.start,
    required this.endExclusive,
  });

  final DateTime start;
  final DateTime endExclusive;
}

class TrendBucket {
  const TrendBucket({
    required this.label,
    required this.summaryLabel,
    required this.amount,
    required this.isToday,
  });

  final String label;
  final String summaryLabel;
  final double amount;
  final bool isToday;
}

const trendBarItemWidth = 34.0;
const trendBarMinSpacing = 8.0;
