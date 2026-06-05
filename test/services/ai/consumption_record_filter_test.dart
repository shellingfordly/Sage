import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ledger_record.dart';
import 'package:ledger_app/services/ai/consumption_record_filter.dart';

void main() {
  group('consumption_record_filter', () {
    test('treats transfer and fixed deposit as non-consumption', () {
      expect(
        isNonConsumptionRecord(
          _expense(title: '内部转账', category: '转账', amount: 1000),
        ),
        isTrue,
      );
      expect(
        isNonConsumptionRecord(
          _expense(title: '定存开户', category: '存款', amount: 60000),
        ),
        isTrue,
      );
      expect(
        isConsumptionExpense(
          _expense(title: '午饭', category: '餐饮', amount: 35),
        ),
        isTrue,
      );
    });
  });
}

LedgerRecord _expense({
  required String title,
  required String category,
  required double amount,
}) {
  return LedgerRecord(
    id: '$title-$amount',
    title: title,
    amount: amount,
    type: LedgerRecordType.expense,
    category: category,
    createdAt: DateTime(2026, 6, 1),
  );
}
