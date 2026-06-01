import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/ai/services/ai_overview_analyzer.dart';
import 'package:ledger_app/models/ledger_record.dart';

void main() {
  group('AiOverviewAnalyzer', () {
    const analyzer = AiOverviewAnalyzer();

    test('returns empty-expense summary when month has no expense', () {
      final result = analyzer.analyze(
        records: <LedgerRecord>[
          _record(
            title: '工资',
            amount: 5000,
            type: LedgerRecordType.income,
            category: '工资',
            createdAt: DateTime(2026, 6, 2),
          ),
        ],
        now: DateTime(2026, 6, 10),
      );

      expect(result.totalIncome, 5000);
      expect(result.totalExpense, 0);
      expect(result.topCategories, isEmpty);
      expect(result.summary, contains('暂未记录支出'));
    });

    test('computes top categories and daily average for current month', () {
      final result = analyzer.analyze(
        records: <LedgerRecord>[
          _record(
            title: '午饭',
            amount: 120,
            type: LedgerRecordType.expense,
            category: '餐饮',
            createdAt: DateTime(2026, 6, 2),
          ),
          _record(
            title: '晚饭',
            amount: 180,
            type: LedgerRecordType.expense,
            category: '餐饮',
            createdAt: DateTime(2026, 6, 4),
          ),
          _record(
            title: '打车',
            amount: 100,
            type: LedgerRecordType.expense,
            category: '交通',
            createdAt: DateTime(2026, 6, 5),
          ),
          _record(
            title: '上月不应计入',
            amount: 500,
            type: LedgerRecordType.expense,
            category: '购物',
            createdAt: DateTime(2026, 5, 20),
          ),
        ],
        now: DateTime(2026, 6, 10),
      );

      expect(result.totalExpense, 400);
      expect(result.dailyAvgExpense, 40);
      expect(result.topCategories.first.category, '餐饮');
      expect(result.topCategories.first.amount, 300);
      expect(result.topCategories.first.percent, closeTo(0.75, 0.001));
    });
  });
}

LedgerRecord _record({
  required String title,
  required double amount,
  required LedgerRecordType type,
  required String category,
  required DateTime createdAt,
}) {
  return LedgerRecord(
    id: '$title-${createdAt.microsecondsSinceEpoch}',
    title: title,
    amount: amount,
    type: type,
    category: category,
    createdAt: createdAt,
  );
}
