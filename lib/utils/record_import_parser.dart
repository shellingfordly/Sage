import '../models/import_parse_result.dart';
import '../models/ledger_category.dart';
import '../models/ledger_record.dart';
import '../models/wealth_meta.dart';

LedgerRecordType? parseImportRecordType(String text) {
  final normalized = text.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized.contains('income') ||
      normalized.contains('收入') ||
      normalized.contains('收')) {
    return LedgerRecordType.income;
  }
  if (normalized.contains('expense') ||
      normalized.contains('支出') ||
      normalized.contains('支')) {
    return LedgerRecordType.expense;
  }
  if (normalized.contains('wealth') ||
      normalized.contains('理财')) {
    return LedgerRecordType.wealth;
  }
  return null;
}

double? parseImportAmount(String raw) {
  var text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  text = text.replaceAll('￥', '').replaceAll('¥', '').replaceAll(',', '');
  text = text.replaceAll(' ', '');
  if (text.startsWith('(') && text.endsWith(')')) {
    text = '-${text.substring(1, text.length - 1)}';
  }
  return double.tryParse(text);
}

DateTime? parseImportDate(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  final normalized = text.replaceAll('/', '-');
  final parsed = DateTime.tryParse(normalized);
  if (parsed != null) {
    return parsed;
  }
  final mdyMatch = RegExp(
    r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})(?:\s+(\d{1,2})(?::(\d{1,2})(?::(\d{1,2}))?)?)?$',
  ).firstMatch(text);
  if (mdyMatch != null) {
    final first = int.tryParse(mdyMatch.group(1)!);
    final secondPart = int.tryParse(mdyMatch.group(2)!);
    final yearRaw = int.tryParse(mdyMatch.group(3)!);
    final hour = int.tryParse(mdyMatch.group(4) ?? '0') ?? 0;
    final minute = int.tryParse(mdyMatch.group(5) ?? '0') ?? 0;
    final second = int.tryParse(mdyMatch.group(6) ?? '0') ?? 0;
    if (first != null && secondPart != null && yearRaw != null) {
      final year = yearRaw < 100 ? (2000 + yearRaw) : yearRaw;
      final month = first <= 12 ? first : secondPart;
      final day = first <= 12 ? secondPart : first;
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day, hour, minute, second);
      }
    }
  }
  final cnMatch = RegExp(
    r'^(\d{2,4})年(\d{1,2})月(\d{1,2})日(?:\s+(\d{1,2})(?::(\d{1,2})(?::(\d{1,2}))?)?)?$',
  ).firstMatch(text);
  if (cnMatch != null) {
    final yearRaw = int.tryParse(cnMatch.group(1)!);
    final month = int.tryParse(cnMatch.group(2)!);
    final day = int.tryParse(cnMatch.group(3)!);
    final hour = int.tryParse(cnMatch.group(4) ?? '0') ?? 0;
    final minute = int.tryParse(cnMatch.group(5) ?? '0') ?? 0;
    final second = int.tryParse(cnMatch.group(6) ?? '0') ?? 0;
    if (yearRaw != null && month != null && day != null) {
      final year = yearRaw < 100 ? (2000 + yearRaw) : yearRaw;
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day, hour, minute, second);
      }
    }
  }
  final excelSerial = double.tryParse(normalized);
  if (excelSerial == null || excelSerial <= 0) {
    return null;
  }
  final base = DateTime(1899, 12, 30);
  final wholeDays = excelSerial.floor();
  final fraction = excelSerial - wholeDays;
  final seconds = (fraction * 24 * 3600).round();
  return base.add(Duration(days: wholeDays, seconds: seconds));
}

RecordRowParseResult parseImportRecordColumns({
  required int rowNumber,
  required String dateText,
  required String typeText,
  required String categoryText,
  required String titleText,
  required String amountText,
  String notesText = '',
  String sourceText = '',
}) {
  final title = titleText.trim();
  final category = categoryText.trim();
  final typeRaw = typeText.trim();
  final dateRaw = dateText.trim();
  final amountRaw = amountText.trim();
  final notes = notesText.trim();
  final source = sourceText.trim();
  if ([title, category, typeRaw, dateRaw, amountRaw, notes, source]
      .every((item) => item.isEmpty)) {
    return const RecordRowParseResult.empty();
  }
  if (title.isEmpty) {
    return RecordRowParseResult.failure(rowNumber, '名称为空');
  }
  if (category.isEmpty) {
    return RecordRowParseResult.failure(rowNumber, '分类为空');
  }
  final type = parseImportRecordType(typeRaw);
  if (type == null) {
    return RecordRowParseResult.failure(rowNumber, '类型无效（需为“收入/支出”）');
  }
  final amount = parseImportAmount(amountRaw);
  if (amount == null || amount <= 0) {
    return RecordRowParseResult.failure(rowNumber, '金额无效（需大于 0）');
  }
  final createdAt = parseImportDate(dateRaw);
  if (createdAt == null) {
    return RecordRowParseResult.failure(rowNumber, '日期无效');
  }

  return RecordRowParseResult.record(
    LedgerRecord(
      id: 'import-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      amount: amount,
      type: type,
      category: category,
      createdAt: createdAt,
      notes: notes,
      source: source,
    ),
  );
}

const wealthExportColumns = [
  '日期',
  '类型',
  '分类',
  '名称',
  '金额',
  '备注',
  '方式',
  '年利率(%)',
  '到期日',
  '到期提醒',
];

bool isWealthSheetName(String name) {
  final normalized = name.trim().toLowerCase();
  return normalized == 'wealth' || normalized == '理财';
}

bool isWealthImportHeader(Iterable<String> headers) {
  return headers.any(
    (header) => header.contains('年利率') || header.contains('到期日'),
  );
}

double? parseOptionalImportRate(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  return parseImportAmount(text);
}

bool? parseImportYesNo(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  if (const {'是', 'yes', 'true', '1', 'y'}.contains(normalized)) {
    return true;
  }
  if (const {'否', 'no', 'false', '0', 'n'}.contains(normalized)) {
    return false;
  }
  return null;
}

String formatImportDateOnly(DateTime dateTime) {
  return '${dateTime.year.toString().padLeft(4, '0')}-'
      '${dateTime.month.toString().padLeft(2, '0')}-'
      '${dateTime.day.toString().padLeft(2, '0')}';
}

String formatImportYesNo(bool value) {
  return value ? '是' : '否';
}

class ImportCategoryParts {
  const ImportCategoryParts({
    required this.leafName,
    this.parentName,
  });

  final String? parentName;
  final String leafName;

  bool get hasParent => parentName != null && parentName!.isNotEmpty;
}

ImportCategoryParts parseImportCategoryText(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return const ImportCategoryParts(leafName: '其他');
  }

  final separatorIndex = text.indexOf('·');
  if (separatorIndex <= 0 || separatorIndex >= text.length - 1) {
    return ImportCategoryParts(leafName: text);
  }

  return ImportCategoryParts(
    parentName: text.substring(0, separatorIndex).trim(),
    leafName: text.substring(separatorIndex + 1).trim(),
  );
}

String exportCategoryLabelForRecord(
  LedgerRecord record,
  Iterable<LedgerCategory> categories,
) {
  return resolveCategoryLabel(
    name: record.category,
    type: record.type,
    ledgerCategories: categories,
  );
}

RecordRowParseResult parseWealthImportRecordColumns({
  required int rowNumber,
  required String dateText,
  required String typeText,
  required String categoryText,
  required String titleText,
  required String amountText,
  String notesText = '',
  String sourceText = '',
  String annualRateText = '',
  String maturityDateText = '',
  String remindText = '',
}) {
  final base = parseImportRecordColumns(
    rowNumber: rowNumber,
    dateText: dateText,
    typeText: typeText.isEmpty ? '理财' : typeText,
    categoryText: categoryText,
    titleText: titleText,
    amountText: amountText,
    notesText: notesText,
  );
  if (base.record == null) {
    return base;
  }

  final maturity = parseImportDate(maturityDateText.trim());
  final remind = parseImportYesNo(remindText) ?? false;

  return RecordRowParseResult.record(
    base.record!.copyWith(
      type: LedgerRecordType.wealth,
      source: sourceText.trim(),
      wealthMeta: WealthMeta(
        annualRate: parseOptionalImportRate(annualRateText),
        maturityDate: maturity == null
            ? null
            : DateTime(maturity.year, maturity.month, maturity.day),
        remindOnMaturity: remind,
      ),
    ),
  );
}

String recordTypeLabel(LedgerRecordType type) {
  return ledgerRecordTypeLabel(type);
}

List<String> recordToPreviewCells(
  LedgerRecord record, {
  String? categoryLabel,
}) {
  return [
    formatImportDateTime(record.createdAt),
    recordTypeLabel(record.type),
    categoryLabel ?? record.category,
    record.title,
    record.amount.toStringAsFixed(2),
    record.notes,
    record.source,
  ];
}

List<String> wealthRecordToPreviewCells(
  LedgerRecord record, {
  String? categoryLabel,
}) {
  final meta = record.wealthMeta;
  return [
    formatImportDateTime(record.createdAt),
    recordTypeLabel(record.type),
    categoryLabel ?? record.category,
    record.title,
    record.amount.toStringAsFixed(2),
    record.notes,
    record.source,
    meta.annualRate?.toStringAsFixed(2) ?? '',
    meta.maturityDate == null ? '' : formatImportDateOnly(meta.maturityDate!),
    formatImportYesNo(meta.remindOnMaturity),
  ];
}

String formatImportDateTime(DateTime dateTime) {
  return '${dateTime.year.toString().padLeft(4, '0')}-'
      '${dateTime.month.toString().padLeft(2, '0')}-'
      '${dateTime.day.toString().padLeft(2, '0')} '
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';
}

String formatDateSlash(DateTime value) {
  return '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
}

String formatDateRangeLabel(DateTime start, DateTime end) {
  return '${start.year}/${start.month.toString().padLeft(2, '0')}/${start.day.toString().padLeft(2, '0')}'
      ' - '
      '${end.year}/${end.month.toString().padLeft(2, '0')}/${end.day.toString().padLeft(2, '0')}';
}

String formatDateRangeLabelCompact(DateTime start, DateTime end) {
  final startLabel =
      '${start.year}/${start.month.toString().padLeft(2, '0')}/${start.day.toString().padLeft(2, '0')}';
  if (start.year == end.year &&
      start.month == end.month &&
      start.day == end.day) {
    return startLabel;
  }
  if (start.year == end.year) {
    final endLabel =
        '${end.month.toString().padLeft(2, '0')}/${end.day.toString().padLeft(2, '0')}';
    return '$startLabel - $endLabel';
  }
  return formatDateRangeLabel(start, end);
}
