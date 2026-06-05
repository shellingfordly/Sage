import '../../models/ledger_category.dart';
import '../../models/ledger_record.dart';
import '../../models/wealth_meta.dart';

class WealthSummary {
  const WealthSummary({
    required this.principalTotal,
    required this.monthNet,
    required this.yearNet,
    required this.monthlyTarget,
    required this.yearlyTarget,
    required this.projectedInterestTotal,
    required this.upcomingItems,
    required this.monthlyTrend,
  });

  final double principalTotal;
  final double monthNet;
  final double yearNet;
  final double monthlyTarget;
  final double yearlyTarget;
  final double projectedInterestTotal;
  final List<WealthMaturityItem> upcomingItems;
  final List<WealthMonthTotal> monthlyTrend;
}

class WealthMaturityItem {
  const WealthMaturityItem({
    required this.record,
    required this.projectedInterest,
    required this.daysUntilMaturity,
  });

  final LedgerRecord record;
  final double projectedInterest;
  final int daysUntilMaturity;
}

class WealthMonthTotal {
  const WealthMonthTotal({
    required this.month,
    required this.netAmount,
  });

  final DateTime month;
  final double netAmount;
}

class WealthAnalyzer {
  const WealthAnalyzer();

  WealthSummary analyze({
    required List<LedgerRecord> records,
    required double monthlyTarget,
    required double yearlyTarget,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final currentMonth = DateTime(reference.year, reference.month, 1);
    final wealthRecords =
        records.where((record) => record.isWealth).toList(growable: false);

    final principalTotal = wealthRecords.fold<double>(
      0,
      (sum, record) => sum + record.amount,
    );

    final monthNet = _netForMonth(wealthRecords, currentMonth);
    final yearNet = _netForYear(wealthRecords, reference.year);

    final projectedInterestTotal = wealthRecords.fold<double>(
      0,
      (sum, record) => sum + projectedInterestForRecord(record, now: reference),
    );

    final upcomingItems = _upcomingMaturities(
      wealthRecords,
      reference: reference,
    );

    final monthlyTrend = _monthlyTrendForYear(
      wealthRecords,
      year: reference.year,
    );

    return WealthSummary(
      principalTotal: principalTotal,
      monthNet: monthNet,
      yearNet: yearNet,
      monthlyTarget: monthlyTarget,
      yearlyTarget: yearlyTarget,
      projectedInterestTotal: projectedInterestTotal,
      upcomingItems: upcomingItems,
      monthlyTrend: monthlyTrend,
    );
  }

  double projectedInterestForRecord(
    LedgerRecord record, {
    DateTime? now,
  }) {
    if (!record.isWealth) {
      return 0;
    }
    final meta = record.wealthMeta;
    if (!meta.hasRate || record.amount <= 0) {
      return 0;
    }

    final start = DateTime(
      record.createdAt.year,
      record.createdAt.month,
      record.createdAt.day,
    );
    final end = meta.hasMaturity
        ? DateTime(
            meta.maturityDate!.year,
            meta.maturityDate!.month,
            meta.maturityDate!.day,
          )
        : (now ?? DateTime.now());
    final effectiveEnd = end.isBefore(start) ? start : end;
    final days = effectiveEnd.difference(start).inDays;
    if (days <= 0) {
      return 0;
    }
    return record.amount * (meta.annualRate! / 100) * days / 365;
  }

  List<WealthMaturityItem> _upcomingMaturities(
    List<LedgerRecord> records, {
    required DateTime reference,
    int withinDays = 90,
  }) {
    final today = DateTime(reference.year, reference.month, reference.day);
    final items = <WealthMaturityItem>[];

    for (final record in records) {
      final maturity = record.wealthMeta.maturityDate;
      if (maturity == null || record.amount <= 0) {
        continue;
      }
      final maturityDay = DateTime(maturity.year, maturity.month, maturity.day);
      final days = maturityDay.difference(today).inDays;
      if (days < 0 || days > withinDays) {
        continue;
      }
      items.add(
        WealthMaturityItem(
          record: record,
          projectedInterest: projectedInterestForRecord(
            record,
            now: maturityDay,
          ),
          daysUntilMaturity: days,
        ),
      );
    }

    items.sort(
      (a, b) => a.daysUntilMaturity.compareTo(b.daysUntilMaturity),
    );
    return items;
  }

  List<WealthMonthTotal> _monthlyTrendForYear(
    List<LedgerRecord> records, {
    required int year,
  }) {
    return [
      for (var month = 1; month <= 12; month++)
        WealthMonthTotal(
          month: DateTime(year, month, 1),
          netAmount: _netForMonth(records, DateTime(year, month, 1)),
        ),
    ];
  }

  double _netForMonth(List<LedgerRecord> records, DateTime month) {
    return records
        .where(
          (record) =>
              record.createdAt.year == month.year &&
              record.createdAt.month == month.month,
        )
        .fold<double>(0, (sum, record) => sum + record.amount);
  }

  double _netForYear(List<LedgerRecord> records, int year) {
    return records
        .where((record) => record.createdAt.year == year)
        .fold<double>(0, (sum, record) => sum + record.amount);
  }
}

bool isLegacyWealthCategoryRecord(LedgerRecord record) {
  return record.category == '理财' && !record.isWealth;
}

LedgerRecord migrateLegacyWealthRecord(LedgerRecord record) {
  if (!isLegacyWealthCategoryRecord(record)) {
    return record;
  }
  final category = record.isIncome ? '收益' : '定期存款';
  return record.copyWith(
    type: LedgerRecordType.wealth,
    category: category,
    wealthMeta: const WealthMeta(),
  );
}

List<LedgerCategory> migrateLegacyCategories(List<LedgerCategory> categories) {
  final result = categories
      .where(
        (category) =>
            !(category.name == '理财' &&
                category.type != LedgerRecordType.wealth),
      )
      .toList();

  for (final defaultCategory in defaultWealthCategories()) {
    final exists = result.any(
      (category) =>
          category.type == LedgerRecordType.wealth &&
          category.name == defaultCategory.name,
    );
    if (!exists) {
      result.add(defaultCategory);
    }
  }
  return result;
}

List<LedgerCategory> defaultWealthCategories() {
  return defaultCategories()
      .where((category) => category.type == LedgerRecordType.wealth)
      .toList();
}
