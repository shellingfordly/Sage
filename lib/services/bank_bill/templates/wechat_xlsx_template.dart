import 'dart:typed_data';

import '../../../models/ledger_record.dart';
import '../../../utils/record_import_parser.dart';
import '../bank_bill_models.dart';
import '../bill_import_source.dart';
import '../wechat_xlsx_reader.dart';

class WeChatXlsxBillTemplate {
  const WeChatXlsxBillTemplate();

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

    final records = <BankBillParsedRecord>[];
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

      records.add(_buildRecord(raw, rowIndex: i));
    }

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
    final type = columns[_columnType].trim();
    final direction = columns[_columnDirection].trim();
    final status = columns[_columnStatus].trim();

    if (type.endsWith('-退款')) {
      return '退款记录（不计入收支）';
    }
    if (status.contains('已退款') || status.contains('已全额退款')) {
      return status.contains('已全额退款') ? '已全额退款' : '已退款';
    }
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

  BankBillParsedRecord _buildRecord(BankBillRawRow raw, {required int rowIndex}) {
    final columns = raw.sourceLine?.split(',') ?? const <String>[];
    final wechatType = columns.elementAtOrNull(_columnType)?.trim() ?? '';
    final mappedCategory = _mapCategory(wechatType, raw.amount >= 0);
    final recordSource = raw.importSource?.trim() ?? '';

    return BankBillParsedRecord(
      record: LedgerRecord(
        id: 'wechat-import-$rowIndex',
        title: _recordTitle(raw),
        amount: raw.amount.abs(),
        type: raw.amount >= 0 ? LedgerRecordType.income : LedgerRecordType.expense,
        category: mappedCategory,
        createdAt: raw.date,
        notes: wechatType.isEmpty ? '' : '交易类型：$wechatType',
        source: recordSource.isNotEmpty
            ? recordSource
            : BillImportSource.unknown,
      ),
      categoryReason: '微信交易类型「$wechatType」映射为「$mappedCategory」',
      raw: raw,
    );
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
