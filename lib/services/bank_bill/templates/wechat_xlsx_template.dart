import 'dart:typed_data';

import '../../../models/ledger_record.dart';
import '../../../utils/record_import_parser.dart';
import '../bank_bill_models.dart';
import '../bank_bill_subcategory_resolver.dart';
import '../bill_import_source.dart';
import '../wechat_xlsx_reader.dart';

class WeChatXlsxBillTemplate {
  const WeChatXlsxBillTemplate();

  static const _subcategoryResolver = BankBillSubcategoryResolver();

  static const templateId = 'wechat-xlsx-v1';

  static const _titleMarker = '微信支付账单明细';
  static const _headerMarker = '交易时间';

  static const _columnTime = 0;
  static const _columnType = 1;
  static const _columnCounterparty = 2;
  static const _columnProduct = 3;
  static const _columnDirection = 4;
  static const _columnAmount = 5;
  static const _columnPaymentMethod = 6;
  static const _columnStatus = 7;

  static const _categoryMap = {
    '商户消费': '购物',
    '扫二维码付款': '购物',
    '转账': '其他',
    '其他': '其他',
  };

  String get id => templateId;

  String get displayName => '微信支付账单明细';

  bool canParseRows(List<List<String>> rows) {
    final flat = rows.expand((row) => row).join('\n');
    return flat.contains(_titleMarker) && _findHeaderRowIndex(rows) >= 0;
  }

  bool canParseBytes(Uint8List bytes) {
    return canParseRows(readWeChatXlsxRows(bytes));
  }

  BankBillParseResult parseBytes(Uint8List bytes) {
    return parseRows(readWeChatXlsxRows(bytes));
  }

  BankBillParseResult parseRows(List<List<String>> rows) {
    if (!canParseRows(rows)) {
      return BankBillParseResult(
        templateId: id,
        templateName: displayName,
        fatalError: '不是微信支付账单 xlsx 格式',
      );
    }

    final headerIndex = _findHeaderRowIndex(rows);
    if (headerIndex < 0) {
      return BankBillParseResult(
        templateId: id,
        templateName: displayName,
        fatalError: '未找到微信支付账单表头',
      );
    }

    final pendingRows = <_WeChatRowContext>[];
    final skippedRows = <BankBillSkippedRow>[];

    for (var i = headerIndex + 1; i < rows.length; i++) {
      final columns = rows[i];
      if (columns.every((value) => value.trim().isEmpty)) {
        continue;
      }

      final sourceLine = columns.join(',');
      if (columns.length < 8) {
        skippedRows.add(
          BankBillSkippedRow(sourceLine: sourceLine, reason: '列数不足'),
        );
        continue;
      }

      final skipReason = _skipReason(columns);
      if (skipReason != null) {
        skippedRows.add(
          BankBillSkippedRow(sourceLine: sourceLine, reason: skipReason),
        );
        continue;
      }

      final raw = _parseRow(columns, sourceLine: sourceLine);
      if (raw == null) {
        skippedRows.add(
          BankBillSkippedRow(sourceLine: sourceLine, reason: '字段解析失败'),
        );
        continue;
      }

      pendingRows.add(
        _WeChatRowContext(
          columns: columns,
          sourceLine: sourceLine,
          rowIndex: i,
          raw: raw,
        ),
      );
    }

    final records = _mergeRefundPairs(pendingRows);

    if (records.isEmpty) {
      return BankBillParseResult(
        templateId: id,
        templateName: displayName,
        skippedRows: skippedRows,
        fatalError: skippedRows.isNotEmpty
            ? '未能从 xlsx 中解析出可导入记录，请确认文件为$displayName格式'
            : 'xlsx 中未找到交易记录',
      );
    }

    return BankBillParseResult(
      templateId: id,
      templateName: displayName,
      records: records,
      skippedRows: skippedRows,
    );
  }

  int _findHeaderRowIndex(List<List<String>> rows) {
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].isNotEmpty && rows[i].first.trim() == _headerMarker) {
        return i;
      }
    }
    return -1;
  }

  String? _skipReason(List<String> columns) {
    final direction = columns[_columnDirection].trim();

    if (direction != '支出' && direction != '收入') {
      return '未知收支类型：$direction';
    }
    return null;
  }

  BankBillRawRow? _parseRow(List<String> columns, {required String sourceLine}) {
    final date = parseImportDate(columns[_columnTime].trim());
    final amount = _parseAmount(columns[_columnAmount]);
    if (date == null || amount == null || amount <= 0) {
      return null;
    }

    final direction = columns[_columnDirection].trim();
    final signedAmount = direction == '收入' ? amount : -amount;
    final summary = _buildSummary(
      counterparty: columns[_columnCounterparty],
      product: columns[_columnProduct],
    );
    if (summary.isEmpty) {
      return null;
    }

    final paymentMethod = _normalizePaymentMethod(columns[_columnPaymentMethod]);

    return BankBillRawRow(
      date: date,
      currency: 'CNY',
      amount: signedAmount,
      balance: 0,
      transactionSummary: summary,
      sourceLine: sourceLine,
      importSource: paymentMethod,
    );
  }

  List<BankBillParsedRecord> _mergeRefundPairs(List<_WeChatRowContext> rows) {
    final consumed = <int>{};
    final mergedByExpenseIndex = <int, BankBillParsedRecord>{};

    for (var refundIndex = 0; refundIndex < rows.length; refundIndex++) {
      final refundRow = rows[refundIndex];
      if (!refundRow.isRefundIncome || consumed.contains(refundIndex)) {
        continue;
      }

      final merchant = refundRow.refundMerchantName;
      if (merchant == null || merchant.isEmpty) {
        continue;
      }

      final refundAmount = refundRow.absoluteAmount;
      var expenseIndex = -1;
      for (var i = 0; i < rows.length; i++) {
        if (i == refundIndex || consumed.contains(i)) {
          continue;
        }
        final expenseRow = rows[i];
        if (!expenseRow.isRefundedExpense) {
          continue;
        }
        if (expenseRow.counterparty != merchant) {
          continue;
        }

        final statusRefund = _parseRefundAmountFromStatus(
          expenseRow.status,
          expenseRow.absoluteAmount,
        );
        if (statusRefund == null) {
          continue;
        }
        if ((statusRefund - refundAmount).abs() > 0.001) {
          continue;
        }

        expenseIndex = i;
        break;
      }

      if (expenseIndex < 0) {
        continue;
      }

      consumed
        ..add(refundIndex)
        ..add(expenseIndex);
      mergedByExpenseIndex[expenseIndex] = _buildMergedRecord(
        expense: rows[expenseIndex],
        paidAmount: rows[expenseIndex].absoluteAmount,
        refundAmount: refundAmount,
      );
    }

    final records = <BankBillParsedRecord>[];
    for (var i = 0; i < rows.length; i++) {
      if (consumed.contains(i)) {
        final merged = mergedByExpenseIndex[i];
        if (merged != null) {
          records.add(merged);
        }
        continue;
      }
      records.add(_buildRecord(rows[i].raw, rowIndex: rows[i].rowIndex));
    }
    return records;
  }

  BankBillParsedRecord _buildMergedRecord({
    required _WeChatRowContext expense,
    required double paidAmount,
    required double refundAmount,
  }) {
    final netAmount = paidAmount - refundAmount;
    final wechatType = expense.type;
    final parentCategory = _mapCategory(wechatType, false);
    final refined = _subcategoryResolver.refine(
      parentCategory: parentCategory,
      type: LedgerRecordType.expense,
      platformCategory: wechatType,
      counterparty: expense.counterparty,
      description: expense.columns.elementAtOrNull(_columnProduct),
      summary: expense.raw.transactionSummary,
    );
    final recordSource = expense.raw.importSource?.trim() ?? '';
    final paidText = _formatWeChatAmount(paidAmount);
    final refundText = _formatWeChatAmount(refundAmount);
    final baseNotes = wechatType.isEmpty ? '' : '交易类型：$wechatType';
    final refundNotes = '付款¥$paidText，退款¥$refundText';
    final notes = baseNotes.isEmpty ? refundNotes : '$baseNotes；$refundNotes';
    final displayAmount = netAmount > 0 ? netAmount : 0.0;

    return BankBillParsedRecord(
      record: LedgerRecord(
        id: 'wechat-import-${expense.rowIndex}',
        title: _recordTitle(expense.raw),
        amount: displayAmount,
        type: LedgerRecordType.expense,
        category: refined.category,
        createdAt: expense.raw.date,
        notes: notes,
        source: recordSource.isNotEmpty
            ? recordSource
            : BillImportSource.unknown,
      ),
      categoryReason: netAmount > 0
          ? '微信退款订单合并：实付 ¥${_formatWeChatAmount(netAmount)}'
          : '微信退款订单合并：全额退款',
      raw: BankBillRawRow(
        date: expense.raw.date,
        currency: expense.raw.currency,
        amount: displayAmount > 0 ? -displayAmount : 0,
        balance: expense.raw.balance,
        transactionSummary: expense.raw.transactionSummary,
        sourceLine: expense.sourceLine,
        importSource: expense.raw.importSource,
      ),
    );
  }

  double? _parseRefundAmountFromStatus(String status, double expenseAmount) {
    if (status.contains('已全额退款')) {
      return expenseAmount;
    }

    final match = RegExp(r'已退款[(（]?¥?([\d,.]+)[)）]?').firstMatch(status);
    if (match == null) {
      return null;
    }
    return _parseAmount(match.group(1)!);
  }

  String _formatWeChatAmount(double amount) {
    final fixed = amount.toStringAsFixed(2);
    if (fixed.endsWith('00')) {
      return amount.toStringAsFixed(0);
    }
    if (fixed.endsWith('0')) {
      return amount.toStringAsFixed(1);
    }
    return fixed;
  }

  BankBillParsedRecord _buildRecord(BankBillRawRow raw, {required int rowIndex}) {
    final columns = raw.sourceLine?.split(',') ?? const <String>[];
    final wechatType = columns.elementAtOrNull(_columnType)?.trim() ?? '';
    final parentCategory = _mapCategory(wechatType, raw.amount >= 0);
    final refined = _subcategoryResolver.refine(
      parentCategory: parentCategory,
      type: raw.amount >= 0 ? LedgerRecordType.income : LedgerRecordType.expense,
      platformCategory: wechatType,
      counterparty: columns.elementAtOrNull(_columnCounterparty),
      description: columns.elementAtOrNull(_columnProduct),
      summary: raw.transactionSummary,
    );
    final recordSource = raw.importSource?.trim() ?? '';

    return BankBillParsedRecord(
      record: LedgerRecord(
        id: 'wechat-import-$rowIndex',
        title: _recordTitle(raw),
        amount: raw.amount.abs(),
        type: raw.amount >= 0 ? LedgerRecordType.income : LedgerRecordType.expense,
        category: refined.category,
        createdAt: raw.date,
        notes: wechatType.isEmpty ? '' : '交易类型：$wechatType',
        source: recordSource.isNotEmpty
            ? recordSource
            : BillImportSource.unknown,
      ),
      categoryReason: _buildCategoryReason(
        wechatType: wechatType,
        parentCategory: parentCategory,
        refined: refined,
      ),
      raw: raw,
    );
  }

  String _buildCategoryReason({
    required String wechatType,
    required String parentCategory,
    required BankBillCategoryResolution refined,
  }) {
    final mappedLabel = refined.category == parentCategory
        ? parentCategory
        : refined.category;
    final base = '微信交易类型「$wechatType」映射为「$mappedLabel」';
    if (refined.detail.isEmpty) {
      return base;
    }
    return '$base，${refined.detail}';
  }

  String _recordTitle(BankBillRawRow raw) {
    final summary = normalizeBankBillTransactionSummary(raw.transactionSummary);
    if (summary.isNotEmpty) {
      return summary;
    }
    return '微信交易';
  }

  String _buildSummary({
    required String counterparty,
    required String product,
  }) {
    final description = product.trim();
    if (description.isNotEmpty && description != '/') {
      return normalizeBankBillTransactionSummary(description);
    }

    final merchant = counterparty.trim();
    if (merchant.isNotEmpty && merchant != '/') {
      return normalizeBankBillTransactionSummary(merchant);
    }
    return '';
  }

  String? _normalizePaymentMethod(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == '/') {
      return null;
    }
    return value;
  }

  String _mapCategory(String wechatType, bool isIncome) {
    if (isIncome) {
      return wechatType == '转账' ? '其他' : '其他';
    }
    return _categoryMap[wechatType] ?? '其他';
  }

  double? _parseAmount(String raw) {
    final normalized = raw.replaceAll(',', '').trim();
    return double.tryParse(normalized);
  }
}

class _WeChatRowContext {
  const _WeChatRowContext({
    required this.columns,
    required this.sourceLine,
    required this.rowIndex,
    required this.raw,
  });

  static const _refundSuffix = '-退款';

  final List<String> columns;
  final String sourceLine;
  final int rowIndex;
  final BankBillRawRow raw;

  String get type => columns[1].trim();
  String get counterparty => columns[2].trim();
  String get direction => columns[4].trim();
  String get status => columns[7].trim();
  double get absoluteAmount => raw.amount.abs();

  bool get isRefundIncome =>
      type.endsWith(_refundSuffix) && direction == '收入';

  bool get isRefundedExpense =>
      direction == '支出' &&
      (status.contains('已全额退款') || status.contains('已退款'));

  String? get refundMerchantName {
    if (!isRefundIncome || !type.endsWith(_refundSuffix)) {
      return null;
    }
    return type.substring(0, type.length - _refundSuffix.length);
  }
}
