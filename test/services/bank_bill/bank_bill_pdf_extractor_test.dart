import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/services/bank_bill/bank_bill_text_normalizer.dart';

void main() {
  test('normalizeBankBillText is applied after pdfrx extraction', () {
    const raw = '记 账 日 期  2000-05-01  CNY';
    final normalized = normalizeBankBillText(raw);
    expect(normalized, contains('记账日期'));
    expect(normalized, contains('2000-05-01'));
  });
}
