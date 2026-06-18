import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/services/bank_bill/bank_bill_privacy.dart';

void main() {
  test('redactBankBillSourceLine masks alipay account and order columns', () {
    const sensitivePhone = '11111111111';
    const sensitiveOrder = '1111111111111';
    final line =
        '2000-01-02 12:00:00,餐饮美食,商户A,$sensitivePhone,订单A,支出,26.00,方式A,交易成功,$sensitiveOrder,ORD-TEST,';

    final redacted = redactBankBillSourceLine(line);

    expect(redacted, isNot(contains(sensitivePhone)));
    expect(redacted, isNot(contains(sensitiveOrder)));
    expect(redacted, contains('***'));
    expect(redacted, contains('商户A'));
  });

  test('redactBankBillSourceLine masks long digit sequences in plain text', () {
    const sensitiveCard = '0000000000000000000';
    final line = '2000-01-01 CNY 10.00 $sensitiveCard 摘要';

    final redacted = redactBankBillSourceLine(line);

    expect(redacted, isNot(contains(sensitiveCard)));
    expect(redacted, contains('***'));
  });
}
