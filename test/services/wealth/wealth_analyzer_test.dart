import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ledger_record.dart';
import 'package:ledger_app/models/wealth_meta.dart';
import 'package:ledger_app/services/wealth/wealth_analyzer.dart';

void main() {
  group('WealthAnalyzer', () {
    const analyzer = WealthAnalyzer();

    test('computes principal and period nets excluding cashflow types', () {
      final summary = analyzer.analyze(
        records: <LedgerRecord>[
          LedgerRecord(
            id: '1',
            title: '定存',
            amount: 10000,
            type: LedgerRecordType.wealth,
            category: '定期存款',
            createdAt: DateTime(2026, 6, 1),
          ),
          LedgerRecord(
            id: '2',
            title: '午饭',
            amount: 30,
            type: LedgerRecordType.expense,
            category: '餐饮',
            createdAt: DateTime(2026, 6, 2),
          ),
          LedgerRecord(
            id: '3',
            title: '追加',
            amount: 2000,
            type: LedgerRecordType.wealth,
            category: '基金',
            createdAt: DateTime(2026, 5, 10),
          ),
        ],
        monthlyTarget: 5000,
        yearlyTarget: 20000,
        now: DateTime(2026, 6, 15),
      );

      expect(summary.principalTotal, 12000);
      expect(summary.monthNet, 10000);
      expect(summary.yearNet, 12000);
      expect(summary.monthlyTarget, 5000);
      expect(summary.yearlyTarget, 20000);
    });

    test('projects interest until maturity date', () {
      final record = LedgerRecord(
        id: '1',
        title: '一年定存',
        amount: 10000,
        type: LedgerRecordType.wealth,
        category: '定期存款',
        createdAt: DateTime(2026, 1, 1),
        wealthMeta: WealthMeta(
          annualRate: 2.5,
          maturityDate: DateTime(2027, 1, 1),
        ),
      );

      final interest = analyzer.projectedInterestForRecord(
        record,
        now: DateTime(2027, 1, 1),
      );

      expect(interest, closeTo(250, 0.01));
    });

    test('migrates legacy wealth category records to wealth type', () {
      final migrated = migrateLegacyWealthRecord(
        LedgerRecord(
          id: '1',
          title: '旧记录',
          amount: 1000,
          type: LedgerRecordType.income,
          category: '理财',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      expect(migrated.type, LedgerRecordType.wealth);
      expect(migrated.category, '收益');
    });
  });
}
