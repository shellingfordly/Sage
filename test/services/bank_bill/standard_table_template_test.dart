import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ledger_record.dart';
import 'package:ledger_app/services/bank_bill/bank_bill_categorizer.dart';
import 'package:ledger_app/services/bank_bill/bank_bill_models.dart';
import 'package:ledger_app/services/bank_bill/bank_bill_record_builder.dart';
import 'package:ledger_app/services/bank_bill/bank_bill_text_normalizer.dart';
import 'package:ledger_app/services/bank_bill/templates/standard_table_template.dart';

void main() {
  group('StandardTableBankBillTemplate', () {
    final template = StandardTableBankBillTemplate();

    test('canParse detects required table headers', () {
      const text = '''
记账日期 货币 交易金额 联机余额 交易摘要
2000-01-01 CNY 100.00 500.00 摘要甲
''';
      expect(template.canParse(text), isTrue);
    });

    test('canParse accepts spaced CJK headers from PDF text', () {
      const text = '''
记 账 日 期 货 币 交 易 金 额 联 机 余 额 交 易 摘 要
2000-01-01 CNY 10.00 90.00 摘 要 A
2000-01-02 CNY -2.00 88.00 摘 要 B
''';
      expect(template.canParse(text), isTrue);
      final result = template.parse(text);
      expect(result.records.length, 2);
    });

    test('tryParseSourceLine parses positive signed row', () {
      const line = '2000-06-01 CNY 12.50 34.00 摘要正向';
      final raw = StandardTableBankBillTemplate.tryParseSourceLine(line);
      expect(raw, isNotNull);
      expect(raw!.amount, 12.5);
      expect(raw.transactionSummary, '摘要正向');
    });

    test('parse keeps transaction summary for income categorization', () {
      const line = '2000-06-01 CNY 10.00 20.00 工资';
      final raw = StandardTableBankBillTemplate.tryParseSourceLine(line);
      expect(raw, isNotNull);
      expect(raw!.transactionSummary, '工资');
      final built = buildBankBillParsedRecord(raw, id: 't1');
      expect(built.record.title, '工资');
      expect(built.record.category, '基本工资');
      expect(built.record.type, LedgerRecordType.income);
      expect(built.record.source, '银行卡');
    });

    test('parse maps sign to record type and strips balance from summary', () {
      const text = '''
记账日期 货币 交易金额 联机余额 交易摘要
2000-06-01 CNY 10.00 20.00 摘要收入
2000-06-30 CNY 8.00 18.00 摘要转入
2000-01-02 CNY -3.00 15.00 摘要支出
''';

      final result = template.parse(text);
      expect(result.records.length, 3);
      expect(result.skippedRows, isEmpty);

      final incomeRow = result.records[0];
      expect(incomeRow.record.type, LedgerRecordType.income);
      expect(incomeRow.record.title, '摘要收入');
      expect(incomeRow.record.amount, 10);

      final secondIncomeRow = result.records[1];
      expect(secondIncomeRow.record.type, LedgerRecordType.income);
      expect(secondIncomeRow.record.title, '摘要转入');

      final expenseRow = result.records[2];
      expect(expenseRow.record.type, LedgerRecordType.expense);
      expect(expenseRow.record.title, '摘要支出');
      expect(expenseRow.record.amount, 3);
    });

    test('parse collects skipped rows with source line', () {
      const text = '''
记账日期 货币 交易金额 联机余额 交易摘要
2000-01-01 CNY 10.00 50.00 摘要甲
2000-01-03 CNY -1.00 49.00
''';

      final result = template.parse(text);
      expect(result.records.length, 1);
      expect(result.skippedRows.length, 1);
      expect(result.skippedRows.first.sourceLine, contains('2000-01-03'));
    });

    test('parse returns fatal error when no transaction rows', () {
      const text = '''
记账日期 货币 交易金额 联机余额 交易摘要
无有效流水数据
''';

      final result = template.parse(text);
      expect(result.hasRecords, isFalse);
      expect(result.fatalError, isNotNull);
    });
  });

  group('BankBillCategorizer', () {
    const categorizer = BankBillCategorizer();

    test('income with 工资 in summary maps to 基本工资 subcategory', () {
      final result = categorizer.categorize(
        BankBillRawRow(
          date: DateTime(2000, 6, 1),
          currency: 'CNY',
          amount: 10,
          balance: 20,
          transactionSummary: '工资',
        ),
      );
      expect(result.type, LedgerRecordType.income);
      expect(result.category, '基本工资');
    });

    test('expense with 工资 in summary stays 其他', () {
      final result = categorizer.categorize(
        BankBillRawRow(
          date: DateTime(2000, 1, 2),
          currency: 'CNY',
          amount: -3,
          balance: 15,
          transactionSummary: '工资',
        ),
      );
      expect(result.type, LedgerRecordType.expense);
      expect(result.category, '其他');
    });
  });

  group('normalizeBankBillTransactionSummary', () {
    test('trims surrounding whitespace', () {
      expect(normalizeBankBillTransactionSummary('  工资  '), '工资');
      expect(normalizeBankBillTransactionSummary('摘要甲'), '摘要甲');
    });
  });

  group('bankBillTextNormalizer', () {
    test('merges spaced CJK characters', () {
      expect(
        compactBankBillText('记 账 日 期 交 易 摘 要'),
        '记账日期交易摘要',
      );
    });
  });
}
