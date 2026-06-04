import 'dart:typed_data';

import '../../../models/ledger_record.dart';
import '../alipay_csv_parser.dart';
import '../bank_bill_models.dart';
import '../bill_import_source.dart';

class AlipayCsvBillTemplate {
  const AlipayCsvBillTemplate();

  static const templateId = 'alipay-csv-v1';

  static const _headerMarker = '交易时间,交易分类,交易对方';

  static const _columnTime = 0;
  static const _columnCategory = 1;
  static const _columnCounterparty = 2;
  static const _columnDescription = 4;
  static const _columnDirection = 5;
  static const _columnAmount = 6;
  static const _columnPaymentMethod = 7;
  static const _columnStatus = 8;

  static const _skipStatuses = {
    '交易关闭',
    '还款失败',
  };

  static const _categoryMap = {
    '餐饮美食': '餐饮',
    '交通出行': '交通',
    '医疗健康': '医疗',
    '日用百货': '购物',
    '家居家装': '购物',
    '数码电器': '购物',
    '美容美发': '其他',
    '爱车养车': '交通',
    '充值缴费': '居住',
    '商业服务': '其他',
    '转账红包': '其他',
    '文化休闲': '娱乐',
    '运动户外': '娱乐',
    '住房物业': '居住',
    '公共服务': '其他',
    '教育': '学习',
    '保险': '其他',
    '人情往来': '其他',
    '亲子': '其他',
    '宠物': '其他',
  };

  String get id => templateId;

  String get displayName => '支付宝交易明细';

  bool canParse(String content) {
    return content.contains('支付宝') && content.contains(_headerMarker);
  }

  bool canParseBytes(Uint8List bytes) {
    return canParse(decodeAlipayCsvText(bytes));
  }

  BankBillParseResult parseBytes(Uint8List bytes) {
    return parse(decodeAlipayCsvText(bytes));
  }

  BankBillParseResult parse(String content) {
    if (!canParse(content)) {
      return BankBillParseResult(
        templateId: id,
        templateName: displayName,
        fatalError: '不是支付宝交易明细 CSV 格式',
      );
    }

    final lines = content
        .split('\n')
        .map((line) => line.replaceAll('\r', '').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final headerIndex = lines.indexWhere((line) => line.startsWith(_headerMarker));
    if (headerIndex < 0) {
      return BankBillParseResult(
        templateId: id,
        templateName: displayName,
        fatalError: '未找到支付宝账单表头',
      );
    }

    final records = <BankBillParsedRecord>[];
    final skippedRows = <BankBillSkippedRow>[];

    for (var i = headerIndex + 1; i < lines.length; i++) {
      final columns = parseAlipayCsvLine(lines[i]);
      if (columns.length < 9) {
        skippedRows.add(
          BankBillSkippedRow(
            sourceLine: lines[i],
            reason: '列数不足',
          ),
        );
        continue;
      }

      final skipReason = _skipReason(columns);
      if (skipReason != null) {
        skippedRows.add(
          BankBillSkippedRow(
            sourceLine: lines[i],
            reason: skipReason,
          ),
        );
        continue;
      }

      final raw = _parseRow(columns, sourceLine: lines[i]);
      if (raw == null) {
        skippedRows.add(
          BankBillSkippedRow(
            sourceLine: lines[i],
            reason: '字段解析失败',
          ),
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
            ? '未能从 CSV 中解析出可导入记录，请确认文件为$displayName格式'
            : 'CSV 中未找到交易记录',
      );
    }

    return BankBillParseResult(
      templateId: id,
      templateName: displayName,
      records: records,
      skippedRows: skippedRows,
    );
  }

  String? _skipReason(List<String> columns) {
    final direction = columns[_columnDirection];
    final status = columns[_columnStatus];

    if (direction == '不计收支') {
      return '不计收支（还款/退款/充值提现等）';
    }
    if (_skipStatuses.contains(status)) {
      return status == '交易关闭' ? '交易已关闭' : status;
    }
    if (direction != '支出' && direction != '收入') {
      return '未知收支类型：$direction';
    }
    return null;
  }

  BankBillRawRow? _parseRow(List<String> columns, {required String sourceLine}) {
    final date = _parseDateTime(columns[_columnTime]);
    final amount = _parseAmount(columns[_columnAmount]);
    if (date == null || amount == null || amount <= 0) {
      return null;
    }

    final direction = columns[_columnDirection];
    final signedAmount = direction == '收入' ? amount : -amount;
    final summary = _buildSummary(
      category: columns[_columnCategory],
      counterparty: columns[_columnCounterparty],
      description: columns[_columnDescription],
    );
    if (summary.isEmpty) {
      return null;
    }

    final paymentMethod = columns.elementAtOrNull(_columnPaymentMethod)?.trim();

    return BankBillRawRow(
      date: date,
      currency: 'CNY',
      amount: signedAmount,
      balance: 0,
      transactionSummary: summary,
      sourceLine: sourceLine,
      importSource: paymentMethod != null && paymentMethod.isNotEmpty
          ? paymentMethod
          : null,
    );
  }

  BankBillParsedRecord _buildRecord(BankBillRawRow raw, {required int rowIndex}) {
    final columns = parseAlipayCsvLine(raw.sourceLine ?? '');
    final alipayCategory = columns.elementAtOrNull(_columnCategory) ?? '';
    final mappedCategory = _mapCategory(alipayCategory, raw.amount >= 0);
    final notes = _buildNotes(alipayCategory: alipayCategory);
    final recordSource = raw.importSource?.trim() ?? '';

    return BankBillParsedRecord(
      record: LedgerRecord(
        id: 'alipay-import-$rowIndex',
        title: _recordTitle(raw),
        amount: raw.amount.abs(),
        type: raw.amount >= 0 ? LedgerRecordType.income : LedgerRecordType.expense,
        category: mappedCategory,
        createdAt: raw.date,
        notes: notes,
        source: recordSource.isNotEmpty
            ? recordSource
            : BillImportSource.unknown,
      ),
      categoryReason: '支付宝分类「$alipayCategory」映射为「$mappedCategory」',
      raw: raw,
    );
  }

  String _recordTitle(BankBillRawRow raw) {
    final summary = normalizeBankBillTransactionSummary(raw.transactionSummary);
    if (summary.isNotEmpty) {
      return summary;
    }
    return '支付宝交易';
  }

  String _buildSummary({
    required String category,
    required String counterparty,
    required String description,
  }) {
    final product = description.trim();
    if (product.isNotEmpty && product != '/') {
      return normalizeBankBillTransactionSummary(product);
    }

    final merchant = counterparty.trim();
    if (merchant.isNotEmpty && merchant != '/') {
      return normalizeBankBillTransactionSummary(merchant);
    }

    final fallback = category.trim();
    if (fallback.isNotEmpty) {
      return normalizeBankBillTransactionSummary(fallback);
    }
    return '';
  }

  String _buildNotes({required String alipayCategory}) {
    if (alipayCategory.isEmpty) {
      return '';
    }
    return '交易分类：$alipayCategory';
  }

  String _mapCategory(String alipayCategory, bool isIncome) {
    if (isIncome) {
      return switch (alipayCategory) {
        '工资' => '工资',
        '奖金' => '奖金',
        '理财' => '理财',
        '兼职' => '兼职',
        _ => '其他',
      };
    }
    return _categoryMap[alipayCategory] ?? '其他';
  }

  DateTime? _parseDateTime(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final match = RegExp(
      r'^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{1,2}):(\d{1,2})$',
    ).firstMatch(normalized);
    if (match == null) {
      return DateTime.tryParse(normalized);
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    final second = int.parse(match.group(6)!);
    return DateTime(year, month, day, hour, minute, second);
  }

  double? _parseAmount(String raw) {
    final normalized = raw.replaceAll(',', '').trim();
    return double.tryParse(normalized);
  }
}
