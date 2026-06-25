import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ledger_app/components/time_range/export_range.dart';

import '../../../../data/ledger_store.dart';
import '../../../../models/ledger_record.dart';
import '../../../../utils/file_name_utils.dart';
import '../../../../utils/platform_file_io.dart';
import '../../../../utils/record_import_parser.dart';

class ExportService {
  const ExportService();

  Future<ExportResult> exportRecordsToExcel({
    required List<LedgerRecord> records,
    required ExportRange range,
    DateTimeRange? customRange,
  }) async {
    if (records.isEmpty) {
      return const ExportResult.failure('当前范围没有可导出的记录');
    }

    try {
      final bytes = buildExcelBytes(
        records,
        categoryLabelBuilder: ledgerStore.categoryLabelForRecord,
      );
      final suggestedName = buildExportFileName(
        range: range,
        customRange: customRange,
      );

      final path = await FilePicker.saveFile(
        dialogTitle: '保存导出的 Excel',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );
      if (path != null) {
        return ExportResult.success('导出成功：${fileNameFromPath(path)}');
      }

      if (kIsWeb) {
        return const ExportResult.cancelled();
      }

      final directory = await FilePicker.getDirectoryPath(dialogTitle: '选择导出目录');
      if (directory == null) {
        return const ExportResult.cancelled();
      }
      final fallbackPath = '$directory/$suggestedName';
      await writeBytesToPath(fallbackPath, bytes);
      return ExportResult.success('导出成功：$suggestedName');
    } catch (error) {
      return ExportResult.failure('导出失败：$error');
    }
  }

  Uint8List buildExcelBytes(
    List<LedgerRecord> records, {
    String Function(LedgerRecord record)? categoryLabelBuilder,
  }) {
    final labelFor = categoryLabelBuilder ?? _defaultCategoryLabel;
    final excel = xl.Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'records') {
      excel.rename(defaultSheet, 'records');
    }

    final cashflowRecords = records.where((record) => !record.isWealth).toList();
    final wealthRecords = records.where((record) => record.isWealth).toList();

    _appendCashflowSheet(excel['records'], cashflowRecords, labelFor);
    if (wealthRecords.isNotEmpty) {
      _appendWealthSheet(excel['wealth'], wealthRecords, labelFor);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('无法生成文件');
    }
    return Uint8List.fromList(encoded);
  }

  String _defaultCategoryLabel(LedgerRecord record) => record.category;

  void _appendCashflowSheet(
    xl.Sheet sheet,
    List<LedgerRecord> records,
    String Function(LedgerRecord record) categoryLabelFor,
  ) {
    sheet.appendRow(exportPreviewColumns.map(xl.TextCellValue.new).toList());

    for (final record in records) {
      sheet.appendRow([
        xl.TextCellValue(formatImportDateTime(record.createdAt)),
        xl.TextCellValue(recordTypeLabel(record.type)),
        xl.TextCellValue(categoryLabelFor(record)),
        xl.TextCellValue(record.title),
        xl.DoubleCellValue(record.amount),
        xl.TextCellValue(record.notes),
        xl.TextCellValue(record.source),
      ]);
    }
  }

  void _appendWealthSheet(
    xl.Sheet sheet,
    List<LedgerRecord> records,
    String Function(LedgerRecord record) categoryLabelFor,
  ) {
    sheet.appendRow(wealthExportColumns.map(xl.TextCellValue.new).toList());

    for (final record in records) {
      final meta = record.wealthMeta;
      sheet.appendRow([
        xl.TextCellValue(formatImportDateTime(record.createdAt)),
        xl.TextCellValue(recordTypeLabel(record.type)),
        xl.TextCellValue(categoryLabelFor(record)),
        xl.TextCellValue(record.title),
        xl.DoubleCellValue(record.amount),
        xl.TextCellValue(record.notes),
        xl.TextCellValue(record.source),
        meta.annualRate == null
            ? xl.TextCellValue('')
            : xl.DoubleCellValue(meta.annualRate!),
        xl.TextCellValue(
          meta.maturityDate == null ? '' : formatImportDateOnly(meta.maturityDate!),
        ),
        xl.TextCellValue(formatImportYesNo(meta.remindOnMaturity)),
      ]);
    }
  }
}

sealed class ExportResult {
  const ExportResult();

  const factory ExportResult.success(String message) = ExportSuccess;
  const factory ExportResult.failure(String message) = ExportFailure;
  const factory ExportResult.cancelled() = ExportCancelled;
}

class ExportSuccess extends ExportResult {
  const ExportSuccess(this.message);
  final String message;
}

class ExportFailure extends ExportResult {
  const ExportFailure(this.message);
  final String message;
}

class ExportCancelled extends ExportResult {
  const ExportCancelled();
}
