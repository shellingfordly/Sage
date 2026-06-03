import '../../models/ledger_record.dart';

enum MergeRecordDisposition { toMerge, filtered, suspected }

class AnalyzedMergeRecord {
  AnalyzedMergeRecord({
    required this.source,
    required this.initialDisposition,
    this.matchedTarget,
    this.matchedTargets = const [],
  });

  final LedgerRecord source;
  final MergeRecordDisposition initialDisposition;
  final LedgerRecord? matchedTarget;
  final List<LedgerRecord> matchedTargets;
  MergeRecordDisposition? userDisposition;

  MergeRecordDisposition get effectiveDisposition =>
      userDisposition ?? initialDisposition;

  bool get willMerge => effectiveDisposition == MergeRecordDisposition.toMerge;

  void resetOverride() => userDisposition = null;
}

class LedgerMergeAnalyzer {
  const LedgerMergeAnalyzer();

  List<AnalyzedMergeRecord> analyze({
    required List<LedgerRecord> sourceRecords,
    required List<LedgerRecord> targetRecords,
  }) {
    final exactIndex = <String, List<LedgerRecord>>{};
    final dayIndex = <String, List<LedgerRecord>>{};

    for (final record in targetRecords) {
      exactIndex
          .putIfAbsent(exactMergeKey(record), () => [])
          .add(record);
      dayIndex.putIfAbsent(dayMergeKey(record), () => []).add(record);
    }

    final result = <AnalyzedMergeRecord>[];
    for (final source in sourceRecords) {
      final exactMatches = exactIndex[exactMergeKey(source)] ?? const [];
      if (exactMatches.isNotEmpty) {
        result.add(
          AnalyzedMergeRecord(
            source: source,
            initialDisposition: MergeRecordDisposition.filtered,
            matchedTarget: exactMatches.first,
            matchedTargets: exactMatches,
          ),
        );
        continue;
      }

      final dayMatches = dayIndex[dayMergeKey(source)] ?? const [];
      if (dayMatches.isNotEmpty) {
        result.add(
          AnalyzedMergeRecord(
            source: source,
            initialDisposition: MergeRecordDisposition.suspected,
            matchedTarget: dayMatches.first,
            matchedTargets: dayMatches,
          ),
        );
        continue;
      }

      result.add(
        AnalyzedMergeRecord(
          source: source,
          initialDisposition: MergeRecordDisposition.toMerge,
        ),
      );
    }

    result.sort(
      (a, b) => b.source.createdAt.compareTo(a.source.createdAt),
    );
    return result;
  }
}

/// 精确到秒：类型 + 分类 + 金额 + 时间戳（秒）
String exactMergeKey(LedgerRecord record) {
  return '${record.type.name}|${record.category.trim()}|${_amountKey(record.amount)}|${_timeKey(record.createdAt)}';
}

/// 同日疑似：类型 + 分类 + 金额 + 日期
String dayMergeKey(LedgerRecord record) {
  final date = record.createdAt;
  return '${record.type.name}|${record.category.trim()}|${_amountKey(record.amount)}|${date.year}-${date.month}-${date.day}';
}

int _amountKey(double amount) => (amount * 100).round();

int _timeKey(DateTime dateTime) => dateTime.millisecondsSinceEpoch ~/ 1000;

String formatMergeDateTime(DateTime dateTime) {
  return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
}

String mergeDispositionLabel(MergeRecordDisposition disposition) {
  return switch (disposition) {
    MergeRecordDisposition.toMerge => '将合并',
    MergeRecordDisposition.filtered => '已过滤',
    MergeRecordDisposition.suspected => '疑似重复',
  };
}
