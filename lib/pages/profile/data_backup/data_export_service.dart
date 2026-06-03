import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import '../../../models/ledger_record.dart';
import '../../../utils/file_name_utils.dart';
import '../../../utils/platform_file_io.dart';
import '../../../utils/record_import_parser.dart';
import 'package:ledger_app/components/time_range/export_range.dart';

class DataExportService {
  const DataExportService();

  Future<DataExportResult> exportRecordsToExcel({
    required List<LedgerRecord> records,
    required ExportRange range,
    DateTimeRange? customRange,
  }) async {
    if (records.isEmpty) {
      return const DataExportResult.failure('当前范围没有可导出的记录');
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
        return DataExportResult.success('导出成功：${fileNameFromPath(path)}');
      }

      if (kIsWeb) {
        return const DataExportResult.cancelled();
      }

      final directory = await FilePicker.getDirectoryPath(dialogTitle: '选择导出目录');
      if (directory == null) {
        return const DataExportResult.cancelled();
      }
      final fallbackPath = '$directory/$suggestedName';
      await writeBytesToPath(fallbackPath, bytes);
      return DataExportResult.success('导出成功：$suggestedName');
    } catch (error) {
      return DataExportResult.failure('导出失败：$error');
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
    ]);

    for (final record in records) {
      sheet.appendRow([
        xl.TextCellValue(formatImportDateTime(record.createdAt)),
        xl.TextCellValue(recordTypeLabel(record.type)),
        xl.TextCellValue(record.category),
        xl.TextCellValue(record.title),
        xl.DoubleCellValue(record.amount),
        xl.TextCellValue(record.notes),
      ]);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('无法生成文件');
    }
    return Uint8List.fromList(encoded);
  }
}

sealed class DataExportResult {
  const DataExportResult();

  const factory DataExportResult.success(String message) = DataExportSuccess;
  const factory DataExportResult.failure(String message) = DataExportFailure;
  const factory DataExportResult.cancelled() = DataExportCancelled;
}

class DataExportSuccess extends DataExportResult {
  const DataExportSuccess(this.message);
  final String message;
}

class DataExportFailure extends DataExportResult {
  const DataExportFailure(this.message);
  final String message;
}

class DataExportCancelled extends DataExportResult {
  const DataExportCancelled();
}
