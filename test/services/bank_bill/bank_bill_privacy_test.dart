import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/services/bank_bill/bank_bill_privacy.dart';

void main() {
  test('redactBankBillSourceLine masks alipay account and order columns', () {
    const line =
        '2000-01-02 12:00:00,餐饮美食,商户A,13800138000,订单A,支出,26.00,方式A,交易成功,2020010212345678,SHOP001,';

    final redacted = redactBankBillSourceLine(line);

    expect(redacted, isNot(contains('13800138000')));
    expect(redacted, isNot(contains('2020010212345678')));
    expect(redacted, contains('***'));
    expect(redacted, contains('商户A'));
  });

  test('redactBankBillSourceLine masks long digit sequences in plain text', () {
    const line = '2024-01-01 CNY 10.00 6222021234567890123 摘要';

    final redacted = redactBankBillSourceLine(line);

    expect(redacted, isNot(contains('6222021234567890123')));
    expect(redacted, contains('***'));
  });
}
