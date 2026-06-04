import '../../models/ledger_record.dart';

/// 从 PDF 提取的单行原始字段。
class BankBillRawRow {
  const BankBillRawRow({
    required this.date,
    required this.currency,
    required this.amount,
    required this.balance,
    required this.transactionSummary,
    this.sourceLine,
    this.importSource,
  });

  final DateTime date;
  final String currency;
  /// 原始金额，正数为收入，负数为支出。
  final double amount;
  final double balance;
  final String transactionSummary;
  final String? sourceLine;
  /// 导入方式，如银行卡、方式A 等。
  final String? importSource;
}

/// 解析并完成分类的单条记录。
class BankBillParsedRecord {
  const BankBillParsedRecord({
    required this.record,
    required this.categoryReason,
    required this.raw,
  });

  final LedgerRecord record;
  final String categoryReason;
  final BankBillRawRow raw;
}

/// 未能自动解析的原始行，可在审核页手动编辑后导入。
class BankBillSkippedRow {
  const BankBillSkippedRow({
    required this.sourceLine,
    required this.reason,
  });

  final String sourceLine;
  final String reason;
}

/// PDF 账单解析结果。
class BankBillParseResult {
  const BankBillParseResult({
    required this.templateId,
    required this.templateName,
    this.records = const [],
    this.skippedRows = const [],
    this.fatalError,
  });

  final String templateId;
  final String templateName;
  final List<BankBillParsedRecord> records;
  final List<BankBillSkippedRow> skippedRows;
  final String? fatalError;

  int get skippedCount => skippedRows.length;

  bool get hasRecords => records.isNotEmpty;
  bool get isCompleteFailure => fatalError != null && !hasRecords;
}

String normalizeBankBillTransactionSummary(String summary) {
  return summary.trim();
}

String buildBankBillNotes(BankBillRawRow raw) {
  final summary = normalizeBankBillTransactionSummary(raw.transactionSummary);
  if (summary.isEmpty) {
    return '';
  }
  return summary;
}
