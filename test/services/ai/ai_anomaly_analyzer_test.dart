import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ai_insight_models.dart';
import 'package:ledger_app/services/ai/ai_anomaly_analyzer.dart';
import 'package:ledger_app/models/ledger_record.dart';

void main() {
  group('AiAnomalyAnalyzer', () {
    const analyzer = AiAnomalyAnalyzer();

    test(
      'returns sample-size warning when expense records are insufficient',
      () {
        final result = analyzer.analyze(
          records: <LedgerRecord>[
            _expense('餐饮', 20, DateTime(2026, 6, 1)),
            _expense('交通', 30, DateTime(2026, 6, 2)),
          ],
          now: DateTime(2026, 6, 10),
        );

        expect(result.items, isEmpty);
        expect(result.summary, contains('样本较少'));
      },
    );

    test('detects large single expense as anomaly', () {
      final records = <LedgerRecord>[
        for (var i = 0; i < 11; i++)
          _expense('餐饮', 20 + i.toDouble(), DateTime(2026, 6, i + 1)),
        _expense('购物', 500, DateTime(2026, 6, 12)),
      ];

      final result = analyzer.analyze(
        records: records,
        now: DateTime(2026, 6, 20),
      );

      expect(result.items, isNotEmpty);
      expect(result.items.first.reason, contains('单笔金额明显高于历史均值'));
      expect(result.items.first.records, isNotEmpty);
    });

    test(
      'AiAnomalyItem records getter falls back when runtime value is null',
      () {
        final item = AiAnomalyItem(
          title: '异常',
          category: '餐饮',
          amount: 100,
          reason: '波动',
          severity: AiSeverity.medium,
          records: null as dynamic,
        );

        expect(item.records, isEmpty);
      },
    );
  });
}

LedgerRecord _expense(String category, double amount, DateTime createdAt) {
  return LedgerRecord(
    id: '$category-${createdAt.microsecondsSinceEpoch}',
    title: category,
    amount: amount,
    type: LedgerRecordType.expense,
    category: category,
    createdAt: createdAt,
  );
}
