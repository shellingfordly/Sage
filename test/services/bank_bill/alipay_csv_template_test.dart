import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ledger_record.dart';
import 'package:ledger_app/services/bank_bill/alipay_csv_parser.dart';
import 'package:ledger_app/services/bank_bill/bank_bill_import_service.dart';
import 'package:ledger_app/services/bank_bill/templates/alipay_csv_template.dart';

const _sampleCsv = '''
支付宝账单（测试数据）
交易时间,交易分类,交易对方,对方账号,商品说明,收/支,金额,收/付款方式,交易状态,备注,
2000-01-02 12:00:00,餐饮美食,商户A,/,订单A,支出,26.00,方式A,交易成功,,
2000-01-01 12:00:00,转账红包,用户A,/,收款,收入,100.00,方式B,交易成功,,
2000-01-01 10:00:00,信用借还,信用A,/,主动还款,不计收支,1000.00,方式C,还款成功,,
1999-12-31 18:00:00,数码电器,店铺A,/,商品A,支出,500.00,方式A,交易关闭,,
1999-12-31 19:00:00,退款,店铺A,/,退款-商品A,不计收支,500.00,方式A,退款成功,,
''';

void main() {
  final sampleBytes = Uint8List.fromList(utf8.encode(_sampleCsv));

  group('parseAlipayCsvLine', () {
    test('splits comma-separated fields', () {
      expect(
        parseAlipayCsvLine('a,b,c'),
        ['a', 'b', 'c'],
      );
    });

    test('handles quoted commas', () {
      expect(
        parseAlipayCsvLine('"hello, world",b'),
        ['hello, world', 'b'],
      );
    });
  });

  group('AlipayCsvBillTemplate', () {
    const template = AlipayCsvBillTemplate();

    test('canParse detects alipay export header', () {
      expect(template.canParse(_sampleCsv), isTrue);
      expect(template.canParse('date,type,amount'), isFalse);
    });

    test('parse imports successful expense and skips neutral rows', () {
      final result = template.parseBytes(sampleBytes);

      expect(result.templateName, '支付宝交易明细');
      expect(result.records.length, 2);
      expect(result.skippedRows.length, 3);

      final expense = result.records[0].record;
      expect(expense.title, '订单A');
      expect(expense.amount, 26);
      expect(expense.type, LedgerRecordType.expense);
      expect(expense.category, '餐饮');
      expect(expense.createdAt, DateTime(2000, 1, 2, 12));
      expect(expense.source, '方式A');
      expect(expense.notes, contains('餐饮美食'));

      final income = result.records[1].record;
      expect(income.title, '收款');
      expect(income.amount, 100);
      expect(income.type, LedgerRecordType.income);
      expect(income.category, '其他');

      final reasons = result.skippedRows.map((row) => row.reason).toSet();
      expect(reasons, contains('不计收支（还款/退款/充值提现等）'));
      expect(reasons, contains('交易已关闭'));
    });

    test('parse reads payment method as source with extended alipay columns', () {
      const row =
          '2000-01-02 12:00:00,餐饮美食,商户A,/,订单A,支出,26.00,方式D,交易成功,,,';

      final result = template.parse('''
支付宝账单（测试数据）
交易时间,交易分类,交易对方,对方账号,商品说明,收/支,金额,收/付款方式,交易状态,交易订单号,商家订单号,备注,
$row
''');

      expect(result.records.length, 1);
      expect(result.records.first.record.source, '方式D');
    });

    test('parse uses unknown when payment method is missing', () {
      const row =
          '2000-01-02 12:00:00,餐饮美食,商户A,/,订单A,支出,26.00,,交易成功,,';

      final result = template.parse('''
支付宝账单（测试数据）
交易时间,交易分类,交易对方,对方账号,商品说明,收/支,金额,收/付款方式,交易状态,备注,
$row
''');

      expect(result.records.length, 1);
      expect(result.records.first.record.source, '未知');
    });

    test('parse returns fatal error for unsupported csv', () {
      final result = template.parse('date,amount\n1999-01-01,10');
      expect(result.hasRecords, isFalse);
      expect(result.fatalError, isNotNull);
    });
  });

  group('BankBillImportService.parseCsv', () {
    const service = BankBillImportService();

    test('routes alipay csv to alipay template', () {
      final result = service.parseCsv(sampleBytes);
      expect(result.hasRecords, isTrue);
      expect(result.templateId, AlipayCsvBillTemplate.templateId);
    });

    test('rejects non-alipay csv', () {
      final bytes = Uint8List.fromList('date,amount\n1999-01-01,10'.codeUnits);
      final result = service.parseCsv(bytes);
      expect(result.hasRecords, isFalse);
      expect(result.fatalError, contains('支付宝'));
    });
  });
}
