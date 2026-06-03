import 'ledger_record.dart';

class ImportFailure {
  const ImportFailure({required this.rowNumber, required this.reason});

  final int rowNumber;
  final String reason;
}

class ImportParseResult {
  const ImportParseResult({
    required this.records,
    required this.failedRows,
    this.fatalError,
  });

  final List<LedgerRecord> records;
  final List<ImportFailure> failedRows;
  final String? fatalError;
}

class RecordRowParseResult {
  const RecordRowParseResult({this.record, this.failure});

  const RecordRowParseResult.empty() : record = null, failure = null;

  factory RecordRowParseResult.record(LedgerRecord record) {
    return RecordRowParseResult(record: record);
  }

  factory RecordRowParseResult.failure(int rowNumber, String reason) {
    return RecordRowParseResult(
      failure: ImportFailure(rowNumber: rowNumber, reason: reason),
    );
  }

  final LedgerRecord? record;
  final ImportFailure? failure;
}
