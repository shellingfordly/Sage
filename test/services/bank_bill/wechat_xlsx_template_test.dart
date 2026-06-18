import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ledger_record.dart';
import 'package:ledger_app/services/bank_bill/bank_bill_import_service.dart';
import 'package:ledger_app/services/bank_bill/templates/wechat_xlsx_template.dart';

/// 虚构微信账单行数据（无真实隐私信息）。
List<List<String>> get _sampleRows => [
  ['----------------------微信支付账单明细列表----------------------'],
  ['起始时间', '2000-01-01', '终止时间', '2000-01-31'],
  [
    '交易时间',
    '交易类型',
    '交易对方',
    '商品',
    '收/支',
    '金额(元)',
    '支付方式',
    '当前状态',
    '交易单号',
    '商户单号',
    '备注',
  ],
  [
    '2000-01-02 12:00:00',
    '商户消费',
    '商户A',
    '商品A',
    '支出',
    '10.00',
    '方式A',
    '支付成功',
    '',
    '',
    '',
  ],
  [
    '2000-01-02 11:00:00',
    '商户A-退款',
    '商户A',
    '商户A',
    '收入',
    '5.00',
    '方式A',
    '已退款¥5.00',
    '',
    '',
    '',
  ],
  [
    '2000-01-01 10:00:00',
    '商户消费',
    '商户A',
    '订单B',
    '支出',
    '30.00',
    '方式A',
    '已退款(¥5.00)',
    '',
    '',
    '',
  ],
  [
    '2000-01-01 09:00:00',
    '其他',
    '奖励来源A',
    '/',
    '收入',
    '1.00',
    '/',
    '已到账',
    '',
    '',
    '',
  ],
  [
    '2000-01-01 08:00:00',
    '转账',
    '用户A',
    '示例转账',
    '支出',
    '200.00',
    '方式A',
    '对方已收钱',
    '',
    '',
    '',
  ],
];

void main() {
  group('WeChatXlsxBillTemplate', () {
    const template = WeChatXlsxBillTemplate();

    test('canParseRows detects wechat export header', () {
      expect(template.canParseRows(_sampleRows), isTrue);
      expect(template.canParseRows([['date', 'amount']]), isFalse);
    });

    test('parseRows merges partial refund pairs into one expense record', () {
      final result = template.parseRows(_sampleRows);

      expect(result.templateName, '微信支付账单明细');
      expect(result.records.length, 4);
      expect(result.skippedRows, isEmpty);

      final expense = result.records[0].record;
      expect(expense.title, '商品A');
      expect(expense.amount, 10);
      expect(expense.type, LedgerRecordType.expense);
      expect(expense.category, '购物');
      expect(expense.createdAt, DateTime(2000, 1, 2, 12));
      expect(expense.source, '方式A');
      expect(expense.notes, contains('商户消费'));

      final mergedRefund = result.records[1].record;
      expect(mergedRefund.title, '订单B');
      expect(mergedRefund.amount, 25);
      expect(mergedRefund.type, LedgerRecordType.expense);
      expect(mergedRefund.category, '购物');
      expect(mergedRefund.notes, contains('付款¥30，退款¥5'));
      expect(result.records[1].categoryReason, contains('实付 ¥25'));

      final reward = result.records[2].record;
      expect(reward.title, '奖励来源A');
      expect(reward.amount, 1);
      expect(reward.type, LedgerRecordType.income);
      expect(reward.source, '未知');

      final transfer = result.records[3].record;
      expect(transfer.title, '示例转账');
      expect(transfer.amount, 200);
      expect(transfer.type, LedgerRecordType.expense);
      expect(transfer.category, '其他');
    });

    test('parseRows merges refund pair with decimal amounts', () {
      final rows = [
        ['微信支付账单明细'],
        [
          '交易时间',
          '交易类型',
          '交易对方',
          '商品',
          '收/支',
          '金额(元)',
          '支付方式',
          '当前状态',
        ],
        [
          '2000-01-04 19:10:40',
          '商户消费',
          '示例五金店',
          '示例五金店',
          '支出',
          '1.00',
          '方式A',
          '已退款(¥0.09)',
        ],
        [
          '2000-01-05 01:16:11',
          '示例五金店-退款',
          '示例五金店',
          '示例五金店',
          '收入',
          '0.09',
          '方式A',
          '已退款¥0.09',
        ],
      ];

      final result = template.parseRows(rows);
      expect(result.records.length, 1);
      expect(result.records.first.record.amount, closeTo(0.91, 0.001));
      expect(result.records.first.record.notes, contains('付款¥1，退款¥0.09'));
      expect(result.records.first.record.type, LedgerRecordType.expense);
    });

    test('parseRows merges full refund pair with zero net expense', () {
      final rows = [
        ['微信支付账单明细'],
        [
          '交易时间',
          '交易类型',
          '交易对方',
          '商品',
          '收/支',
          '金额(元)',
          '支付方式',
          '当前状态',
        ],
        [
          '2000-01-05 09:19:27',
          '示例新能源-退款',
          '示例新能源',
          '示例新能源',
          '收入',
          '40.00',
          '方式C',
          '已全额退款',
        ],
        [
          '2000-01-05 09:18:29',
          '商户消费',
          '示例新能源',
          '充电订单',
          '支出',
          '40.00',
          '方式C',
          '已全额退款',
        ],
      ];

      final result = template.parseRows(rows);
      expect(result.records.length, 1);

      final merged = result.records.first.record;
      expect(merged.amount, 0);
      expect(merged.type, LedgerRecordType.expense);
      expect(merged.title, '充电订单');
      expect(merged.category, '加油充电');
      expect(merged.notes, contains('付款¥40，退款¥40'));
      expect(result.records.first.categoryReason, contains('全额退款'));
    });

    test('parseRows categorizes pay-after-charging as 加油充电', () {
      final rows = [
        ['微信支付账单明细'],
        [
          '交易时间',
          '交易类型',
          '交易对方',
          '商品',
          '收/支',
          '金额(元)',
          '支付方式',
          '当前状态',
        ],
        [
          '2000-01-06 13:00:00',
          '商户消费',
          '充电平台A',
          '先充后付',
          '支出',
          '8.00',
          '方式C',
          '支付成功',
        ],
      ];

      final result = template.parseRows(rows);
      expect(result.records.length, 1);
      expect(result.records.first.record.title, '先充后付');
      expect(result.records.first.record.category, '加油充电');
    });

    test('parseRows uses counterparty when product is empty', () {
      final rows = [
        ['微信支付账单明细'],
        [
          '交易时间',
          '交易类型',
          '交易对方',
          '商品',
          '收/支',
          '金额(元)',
          '支付方式',
          '当前状态',
        ],
        [
          '2000-01-03 12:00:00',
          '扫二维码付款',
          '商户B',
          '/',
          '支出',
          '5.00',
          '方式B',
          '支付成功',
        ],
      ];

      final result = template.parseRows(rows);
      expect(result.records.length, 1);
      expect(result.records.first.record.title, '商户B');
      expect(result.records.first.record.source, '方式B');
    });

    test('parseRows returns fatal error for unsupported format', () {
      final result = template.parseRows([['date', 'amount']]);
      expect(result.hasRecords, isFalse);
      expect(result.fatalError, isNotNull);
    });
  });

  group('BankBillImportService.parseWechatXlsx', () {
    test('rejects non-wechat xlsx bytes', () {
      const service = BankBillImportService();
      final bytes = Uint8List.fromList('not an xlsx'.codeUnits);
      final result = service.parseWechatXlsx(bytes);
      expect(result.hasRecords, isFalse);
      expect(result.fatalError, contains('微信'));
    });
  });
}
