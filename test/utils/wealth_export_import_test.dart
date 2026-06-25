import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ledger_category.dart';
import 'package:ledger_app/models/ledger_record.dart';
import 'package:ledger_app/models/wealth_meta.dart';
import 'package:ledger_app/pages/profile/data_backup/export/export_service.dart';
import 'package:ledger_app/utils/excel_record_parser.dart';
import 'package:ledger_app/utils/record_import_parser.dart';

void main() {
  const exportService = ExportService();
  final categories = defaultCategories();

  String categoryLabel(LedgerRecord record) {
    return exportCategoryLabelForRecord(record, categories);
  }

  test('wealth sheet round-trips annual rate and maturity metadata', () {
    final record = LedgerRecord(
      id: 'wealth-1',
      title: '工商定存',
      amount: 30000,
      type: LedgerRecordType.wealth,
      category: '定期存款',
      createdAt: DateTime(2026, 5, 7, 10, 30),
      source: '银行卡',
      wealthMeta: WealthMeta(
        annualRate: 2.35,
        maturityDate: DateTime(2027, 5, 7),
        remindOnMaturity: true,
      ),
    );

    final bytes = exportService.buildExcelBytes(
      [record],
      categoryLabelBuilder: categoryLabel,
    );
    final parsed = parseExcelRecords(bytes);

    expect(parsed.fatalError, isNull);
    expect(parsed.records, hasLength(1));
    expect(parsed.records.single.type, LedgerRecordType.wealth);
    expect(parsed.records.single.title, '工商定存');
    expect(parsed.records.single.source, '银行卡');
    expect(parsed.records.single.wealthMeta.annualRate, 2.35);
    expect(parsed.records.single.wealthMeta.maturityDate, DateTime(2027, 5, 7));
    expect(parsed.records.single.wealthMeta.remindOnMaturity, isTrue);
  });

  test('cashflow and wealth export to separate sheets', () {
    final records = [
      LedgerRecord(
        id: 'expense-1',
        title: '午餐',
        amount: 28,
        type: LedgerRecordType.expense,
        category: '餐饮',
        createdAt: DateTime(2026, 5, 7),
      ),
      LedgerRecord(
        id: 'wealth-1',
        title: '基金定投',
        amount: 1000,
        type: LedgerRecordType.wealth,
        category: '基金',
        createdAt: DateTime(2026, 5, 8),
        wealthMeta: const WealthMeta(annualRate: 4.5),
      ),
    ];

    final bytes = exportService.buildExcelBytes(
      records,
      categoryLabelBuilder: categoryLabel,
    );
    final excel = xl.Excel.decodeBytes(bytes);

    expect(excel.tables.containsKey('records'), isTrue);
    expect(excel.tables.containsKey('wealth'), isTrue);
    expect(excel.tables['records']!.rows.length, 2);
    expect(excel.tables['wealth']!.rows.length, 2);
    expect(
      excel.tables['records']!.rows[1][1]?.value.toString(),
      contains('支出'),
    );
    expect(
      excel.tables['wealth']!.rows[1][1]?.value.toString(),
      contains('理财'),
    );
  });

  test('subcategory exports as parent·child label and imports back to leaf', () {
    final record = LedgerRecord(
      id: 'expense-sub',
      title: '义乌小商品超市',
      amount: 9,
      type: LedgerRecordType.expense,
      category: '零食水果',
      createdAt: DateTime(2026, 5, 7, 12, 30),
    );

    final bytes = exportService.buildExcelBytes(
      [record],
      categoryLabelBuilder: categoryLabel,
    );
    final parsed = parseExcelRecords(bytes);

    expect(parsed.fatalError, isNull);
    expect(parsed.records, hasLength(1));
    expect(parsed.records.single.category, '餐饮·零食水果');
    expect(
      parseImportCategoryText(parsed.records.single.category).leafName,
      '零食水果',
    );
    expect(
      parseImportCategoryText(parsed.records.single.category).parentName,
      '餐饮',
    );
  });
}
