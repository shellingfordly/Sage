import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ledger_app/components/time_range/export_range.dart';

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
      final bytes = _buildExcelBytes(records);
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

  Uint8List _buildExcelBytes(List<LedgerRecord> records) {
    final excel = xl.Excel.createExcel();
    final sheet = excel['records'];
    sheet.appendRow([
      xl.TextCellValue('日期'),
      xl.TextCellValue('类型'),
      xl.TextCellValue('分类'),
      xl.TextCellValue('名称'),
      xl.TextCellValue('金额'),
      xl.TextCellValue('备注'),
      xl.TextCellValue('方式'),
    ]);

    for (final record in records) {
      sheet.appendRow([
        xl.TextCellValue(formatImportDateTime(record.createdAt)),
        xl.TextCellValue(recordTypeLabel(record.type)),
        xl.TextCellValue(record.category),
        xl.TextCellValue(record.title),
        xl.DoubleCellValue(record.amount),
        xl.TextCellValue(record.notes),
        xl.TextCellValue(record.source),
      ]);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('无法生成文件');
    }
    return Uint8List.fromList(encoded);
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
