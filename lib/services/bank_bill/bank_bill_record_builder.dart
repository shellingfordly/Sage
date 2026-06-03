import '../../models/ledger_record.dart';
import 'bank_bill_categorizer.dart';
import 'bank_bill_models.dart';

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
    ),
    categoryReason: category.reason,
    raw: raw,
  );
}
