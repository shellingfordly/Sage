import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ledger_record.dart';
import 'package:ledger_app/services/bank_bill/bank_bill_categorizer.dart';
import 'package:ledger_app/services/bank_bill/bank_bill_models.dart';
import 'package:ledger_app/services/bank_bill/bank_bill_subcategory_resolver.dart';
import 'package:ledger_app/services/bank_bill/templates/alipay_csv_template.dart';

void main() {
  const resolver = BankBillSubcategoryResolver();

  group('BankBillSubcategoryResolver', () {
    test('maps alipay dining takeaway to 早中晚餐', () {
      final result = resolver.refine(
        parentCategory: '餐饮',
        type: LedgerRecordType.expense,
        platformCategory: '餐饮美食',
        counterparty: '外卖平台A',
        description: '示例餐厅外卖订单',
      );
      expect(result.category, '早中晚餐');
      expect(result.detail, isNotEmpty);
    });

    test('maps alipay etc toll to 高速费', () {
      final result = resolver.refine(
        parentCategory: '交通',
        type: LedgerRecordType.expense,
        platformCategory: '爱车养车',
        description: '高速ETC通行费',
      );
      expect(result.category, '高速费');
    });

    test('maps alipay mobile recharge to 话费流量', () {
      final result = resolver.refine(
        parentCategory: '居住',
        type: LedgerRecordType.expense,
        platformCategory: '充值缴费',
        counterparty: '运营商A',
        description: '为示例号码话费充值',
      );
      expect(result.category, '话费流量');
    });

    test('maps pay-after-charging to 加油充电', () {
      final result = resolver.refine(
        parentCategory: '购物',
        type: LedgerRecordType.expense,
        platformCategory: '商户消费',
        counterparty: '充电平台A',
        description: '先充后付',
        summary: '先充后付',
      );
      expect(result.category, '加油充电');
    });

    test('maps wechat merchant charging order to 加油充电', () {
      final result = resolver.refine(
        parentCategory: '购物',
        type: LedgerRecordType.expense,
        platformCategory: '商户消费',
        counterparty: '示例新能源',
        description: '充电订单',
        summary: '充电订单',
      );
      expect(result.category, '加油充电');
      expect(result.detail, isNotEmpty);
    });

    test('maps convenience store under shopping to 日用百货', () {
      final result = resolver.refine(
        parentCategory: '购物',
        type: LedgerRecordType.expense,
        platformCategory: '日用百货',
        counterparty: '示例便利店',
      );
      expect(result.category, '日用百货');
    });

    test('maps payroll income to 基本工资', () {
      final result = resolver.refine(
        parentCategory: '工资',
        type: LedgerRecordType.income,
        summary: '代发工资',
      );
      expect(result.category, '基本工资');
    });

    test('keeps parent category when no subcategory matches', () {
      final result = resolver.refine(
        parentCategory: '其他',
        type: LedgerRecordType.expense,
        summary: '未知商户',
      );
      expect(result.category, '其他');
      expect(result.detail, isEmpty);
    });
  });

  group('AlipayCsvBillTemplate subcategory refinement', () {
    const template = AlipayCsvBillTemplate();

    test('parse refines dining takeaway to subcategory', () {
      const csv = '''
支付宝账单
交易时间,交易分类,交易对方,对方账号,商品说明,收/支,金额,收/付款方式,交易状态,交易订单号,商家订单号,备注,
2000-01-02 12:00:00,餐饮美食,外卖平台A,/,示例餐厅外卖订单,支出,26.00,方式A,交易成功,,,
''';

      final result = template.parseBytes(Uint8List.fromList(utf8.encode(csv)));
      expect(result.records.single.record.category, '早中晚餐');
      expect(result.records.single.categoryReason, contains('细分为'));
    });
  });

  group('BankBillCategorizer subcategory refinement', () {
    const categorizer = BankBillCategorizer();

    test('quick pay expense maps to 日用百货', () {
      final result = categorizer.categorize(
        BankBillRawRow(
          date: DateTime(2000, 1, 2),
          currency: 'CNY',
          amount: -100,
          balance: 900,
          transactionSummary: '快捷支付',
        ),
      );
      expect(result.category, '日用百货');
      expect(result.reason, contains('细分为'));
    });

    test('payroll income maps to 基本工资', () {
      final result = categorizer.categorize(
        BankBillRawRow(
          date: DateTime(2000, 1, 1),
          currency: 'CNY',
          amount: 5000,
          balance: 15000,
          transactionSummary: '代发工资',
        ),
      );
      expect(result.type, LedgerRecordType.income);
      expect(result.category, '基本工资');
    });
  });
}
