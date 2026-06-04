import '../../models/ledger_record.dart';
import 'bank_bill_categorizer.dart';
import 'bank_bill_models.dart';
import 'bill_import_source.dart';

BankBillParsedRecord buildBankBillParsedRecord(
  BankBillRawRow raw, {
  required String id,
  BankBillCategorizer categorizer = const BankBillCategorizer(),
}) {
  final category = categorizer.categorize(raw);
  return BankBillParsedRecord(
    record: LedgerRecord(
      id: id,
      title: bankBillRecordTitle(raw),
      amount: raw.amount.abs(),
      type: category.type,
      category: category.category,
      createdAt: raw.date,
      notes: buildBankBillNotes(raw),
      source: BillImportSource.bankCard,
    ),
    categoryReason: category.reason,
    raw: raw,
  );
}
