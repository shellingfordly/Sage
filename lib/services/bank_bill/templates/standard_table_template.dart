import '../bank_bill_record_builder.dart';
import '../bank_bill_text_normalizer.dart';
import '../bank_bill_categorizer.dart';
import '../bank_bill_models.dart';
import '../bank_bill_template.dart';

class StandardTableBankBillTemplate implements BankBillTemplate {
  StandardTableBankBillTemplate({BankBillCategorizer? categorizer})
      : _categorizer = categorizer ?? const BankBillCategorizer();

  static const templateId = 'table-statement-v1';

  static final _datePrefixPattern = RegExp(
    r'^(\d{4})[-/.年](\d{1,2})[-/.月](\d{1,2})日?\s*',
  );

  static final _rowStartPattern = RegExp(
    r'(\d{4})[-/.年](\d{1,2})[-/.月](\d{1,2})日?\s+'
    r'(?:(CNY|RMB|人民币)\s+)?'
    r'(-?(?:\d{1,3}(?:,\s*\d{3})+(?:\.\d{2})?|\d+(?:\.\d{2})?))'
    r'(?:\s+(-?(?:\d{1,3}(?:,\s*\d{3})+(?:\.\d{2})?|\d+(?:\.\d{2})?)))?'
    r'\s*(.*)$',
  );

  static final _amountTokenPattern = RegExp(
    r'-?(?:\d{1,3}(?:,\s*\d{3})+(?:\.\d{2})?|\d+(?:\.\d{2})?)',
  );

  final BankBillCategorizer _categorizer;

  @override
  String get id => templateId;

  @override
  String get displayName => '标准表格流水';

  /// 供审核页对跳过行做二次解析或预填编辑表单。
  static BankBillRawRow? tryParseSourceLine(String line) {
    return StandardTableBankBillTemplate()._parseLine(line);
  }

  @override
  bool canParse(String extractedText) {
    final normalized = normalizeBankBillText(extractedText);
    if (_hasTableHeaders(normalized)) {
      return true;
    }
    if (_countTransactionRows(normalized) >= 1) {
      return true;
    }
    return _datePrefixPattern.hasMatch(compactBankBillText(normalized));
  }

  bool _hasTableHeaders(String text) {
    return bankBillTextContains(text, '记账日期') &&
        bankBillTextContains(text, '交易摘要');
  }

  int _countTransactionRows(String text) {
    var count = 0;
    for (final line in _normalizeLines(text)) {
      if (_rowStartPattern.hasMatch(line) || _datePrefixPattern.hasMatch(line)) {
        count++;
      }
    }
    return count;
  }

  @override
  BankBillParseResult parse(String extractedText) {
    final normalized = normalizeBankBillText(extractedText);
    final lines = _normalizeLines(normalized);
    final records = <BankBillParsedRecord>[];
    final skippedRows = <BankBillSkippedRow>[];
    var index = 0;

    while (index < lines.length) {
      final line = lines[index];
      if (!_rowStartPattern.hasMatch(line) && !_datePrefixPattern.hasMatch(line)) {
        index++;
        continue;
      }

      var mergedLine = line;
      var nextIndex = index + 1;
      while (nextIndex < lines.length &&
          !_rowStartPattern.hasMatch(lines[nextIndex]) &&
          !_datePrefixPattern.hasMatch(lines[nextIndex])) {
        mergedLine = '$mergedLine ${lines[nextIndex]}';
        nextIndex++;
      }

      final raw = _parseLine(mergedLine);
      if (raw == null) {
        skippedRows.add(
          BankBillSkippedRow(
            sourceLine: mergedLine,
            reason: _skipReasonForLine(mergedLine),
          ),
        );
      } else {
        records.add(
          buildBankBillParsedRecord(
            raw,
            id: 'bank-import-$index',
            categorizer: _categorizer,
          ),
        );
      }

      index = nextIndex;
    }

    if (records.isEmpty) {
      return BankBillParseResult(
        templateId: id,
        templateName: displayName,
        skippedRows: skippedRows,
        fatalError: skippedRows.isNotEmpty
            ? '未能从 PDF 中解析出有效账单行，请确认文件为$displayName格式'
            : '未能从 PDF 中识别账单内容，请确认文件为$displayName格式',
      );
    }

    return BankBillParseResult(
      templateId: id,
      templateName: displayName,
      records: records,
      skippedRows: skippedRows,
    );
  }

  String _skipReasonForLine(String line) {
    final dateMatch = _datePrefixPattern.firstMatch(line);
    if (dateMatch == null) {
      return '未识别日期';
    }
    final tail = line.substring(dateMatch.end).trim();
    if (tail.isEmpty) {
      return '缺少金额与交易摘要';
    }
    final amounts = _amountTokenPattern.allMatches(tail).toList();
    if (amounts.isEmpty) {
      return '未识别交易金额';
    }
    return '未识别交易摘要';
  }

  List<String> _normalizeLines(String extractedText) {
    final normalized = normalizeBankBillText(extractedText);
    final byNewline = normalized
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final rows = <String>[];
    for (final line in byNewline) {
      rows.addAll(_splitTransactionSegments(line));
    }

    if (rows.isNotEmpty) {
      return rows;
    }

    return _splitTransactionSegments(normalized);
  }

  List<String> _splitTransactionSegments(String text) {
    final segments = <String>[];
    final matches = _rowStartPattern.allMatches(text).toList();
    if (matches.isEmpty) {
      return const [];
    }

    for (var i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      final segment = text.substring(start, end).trim();
      if (segment.isNotEmpty) {
        segments.add(segment);
      }
    }
    return segments;
  }

  BankBillRawRow? _parseLine(String line) {
    final regexRow = _parseWithRowRegex(line);
    if (regexRow != null) {
      return regexRow;
    }
    return _parseWithAmountTokens(line);
  }

  BankBillRawRow? _parseWithRowRegex(String line) {
    final match = _rowStartPattern.firstMatch(line);
    if (match == null) {
      return null;
    }

    final date = _parseDate(match.group(1)!, match.group(2)!, match.group(3)!);
    final amount = _parseAmount(match.group(5)!);
    if (date == null || amount == null) {
      return null;
    }

    final balanceGroup = match.group(6);
    final balance = balanceGroup == null || balanceGroup.isEmpty
        ? 0.0
        : _parseAmount(balanceGroup) ?? 0.0;

    final summary = _cleanTransactionSummary(
      match.group(7)?.trim() ?? '',
      transactionAmount: amount,
      balance: balance,
    );
    if (summary.isEmpty) {
      return null;
    }

    return BankBillRawRow(
      date: date,
      currency: match.group(4) ?? 'CNY',
      amount: amount,
      balance: balance,
      transactionSummary: normalizeBankBillTransactionSummary(summary),
      sourceLine: line,
    );
  }

  BankBillRawRow? _parseWithAmountTokens(String line) {
    final dateMatch = _datePrefixPattern.firstMatch(line);
    if (dateMatch == null) {
      return null;
    }

    final date = _parseDate(
      dateMatch.group(1)!,
      dateMatch.group(2)!,
      dateMatch.group(3)!,
    );
    if (date == null) {
      return null;
    }

    var tail = line.substring(dateMatch.end).trim();
    tail = tail.replaceFirst(RegExp(r'^(CNY|RMB|人民币)\s*', caseSensitive: false), '');

    final amountMatches = _amountTokenPattern.allMatches(tail).toList();
    if (amountMatches.isEmpty) {
      return null;
    }

    final transactionAmount = _parseAmount(amountMatches.first.group(0)!);
    if (transactionAmount == null) {
      return null;
    }

    var summaryStart = amountMatches.first.end;
    double balance = 0;
    if (amountMatches.length >= 2) {
      final maybeBalance = _parseAmount(amountMatches[1].group(0)!);
      if (maybeBalance != null) {
        balance = maybeBalance;
        summaryStart = amountMatches[1].end;
      }
    }

    final summary = _cleanTransactionSummary(
      tail.substring(summaryStart).trim(),
      transactionAmount: transactionAmount,
      balance: balance,
    );
    if (summary.isEmpty) {
      return null;
    }

    return BankBillRawRow(
      date: date,
      currency: 'CNY',
      amount: transactionAmount,
      balance: balance,
      transactionSummary: normalizeBankBillTransactionSummary(summary),
      sourceLine: line,
    );
  }

  String _cleanTransactionSummary(
    String remainder, {
    required double transactionAmount,
    required double balance,
  }) {
    var summary = normalizeBankBillText(remainder);
    if (summary.isEmpty) {
      return '';
    }

    while (summary.isNotEmpty) {
      final leadingAmount = _amountTokenPattern.matchAsPrefix(summary);
      if (leadingAmount == null) {
        break;
      }
      final parsed = _parseAmount(leadingAmount.group(0)!);
      if (parsed == null) {
        break;
      }
      final isBalance = balance != 0 && (parsed - balance).abs() < 0.01;
      final isDuplicateAmount =
          (parsed - transactionAmount).abs() < 0.01 ||
          (parsed - transactionAmount.abs()).abs() < 0.01;
      if (!isBalance && !isDuplicateAmount) {
        break;
      }
      summary = summary.substring(leadingAmount.end).trim();
    }

    if (summary.isEmpty) {
      return '';
    }
    if (RegExp(r'^-?[\d,.]+$').hasMatch(summary.replaceAll(' ', ''))) {
      return '';
    }
    return summary;
  }

  DateTime? _parseDate(String year, String month, String day) {
    final y = int.tryParse(year);
    final m = int.tryParse(month);
    final d = int.tryParse(day);
    if (y == null || m == null || d == null) {
      return null;
    }
    return DateTime(y, m, d);
  }

  double? _parseAmount(String raw) {
    final normalized = raw
        .replaceAll(RegExp(r',\s*'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
    return double.tryParse(normalized);
  }
}
