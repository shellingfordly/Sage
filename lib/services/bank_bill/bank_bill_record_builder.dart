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
  final amount = category.type == LedgerRecordType.wealth
      ? (raw.amount >= 0 ? raw.amount.abs() : -raw.amount.abs())
      : raw.amount.abs();
  return BankBillParsedRecord(
    record: LedgerRecord(
      id: id,
      title: bankBillRecordTitle(raw),
      amount: amount,
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
