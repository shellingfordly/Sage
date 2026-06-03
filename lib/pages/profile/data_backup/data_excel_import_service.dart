import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/ledger_store.dart';
import '../../../models/import_parse_result.dart';
import '../../../utils/excel_record_parser.dart';
import '../../../utils/platform_file_bytes.dart';
import '../../../utils/record_import_parser.dart';
import 'data_preview_page.dart';
import 'package:ledger_app/components/time_range/export_range.dart';

class DataExcelImportService {
  const DataExcelImportService();

  Future<DataExcelImportResult> importFromFilePicker(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'txt', 'pdf', 'doc', 'docx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return const DataExcelImportCancelled();
      }

      final file = result.files.single;
      final extension = (file.extension ?? '').toLowerCase();
      if (extension == 'pdf' || extension == 'doc' || extension == 'docx') {
        return const DataExcelImportFailure('请使用「导入 PDF 账单」导入 PDF 文件');
      }

      final bytes = await readPlatformFileBytes(file);
      final parsed = extension == 'csv' || extension == 'txt'
          ? parseCsvRecords(bytes)
          : parseExcelRecords(bytes);

      if (parsed.fatalError != null) {
        return DataExcelImportFailure(parsed.fatalError!);
      }
      if (parsed.records.isEmpty && parsed.failedRows.isNotEmpty) {
        if (!context.mounted) {
          return const DataExcelImportCancelled();
        }
        await _showImportPreviewPage(
          context,
          fileName: file.name,
          parsed: parsed,
        );
        return const DataExcelImportCancelled();
      }
      if (parsed.records.isEmpty) {
        return const DataExcelImportFailure('未识别到可导入记录，请检查文件格式');
      }

      if (!context.mounted) {
        return const DataExcelImportCancelled();
      }

      final confirmed = await _showImportPreviewPage(
        context,
        fileName: file.name,
        parsed: parsed,
      );
      if (confirmed != true) {
        return const DataExcelImportCancelled(message: '已取消导入');
      }

      final added = await ledgerStore.importRecords(
        parsed.records,
        skipDuplicates: true,
      );
      if (added == 0) {
        return const DataExcelImportFailure('没有导入新记录（可能都已存在）');
      }

      final skipped = parsed.failedRows.length;
      if (skipped > 0) {
        return DataExcelImportSuccess(
          '导入成功，新增 $added 条；另有 $skipped 条格式不匹配已跳过',
        );
      }
      return DataExcelImportSuccess('导入成功，新增 $added 条记录');
    } catch (error) {
      return DataExcelImportFailure('导入失败：$error');
    }
  }

  Future<bool?> _showImportPreviewPage(
    BuildContext context, {
    required String fileName,
    required ImportParseResult parsed,
  }) {
    final totalRows = parsed.records.length + parsed.failedRows.length;
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => DataPreviewPage(
          title: '导入预览',
          subtitle:
              '文件：$fileName  ·  总行数：$totalRows  ·  可导入：${parsed.records.length}  ·  失败：${parsed.failedRows.length}',
          columns: exportPreviewColumns,
          rows: parsed.records
              .map((record) => DataPreviewRow(cells: recordToPreviewCells(record)))
              .toList(),
          failureRows: parsed.failedRows
              .map(
                (item) => DataPreviewFailureRow(
                  sourceLabel: '第 ${item.rowNumber} 行',
                  reason: item.reason,
                ),
              )
              .toList(),
          confirmButtonText: '继续导入',
          cancelButtonText: '取消',
        ),
      ),
    );
  }
}

sealed class DataExcelImportResult {
  const DataExcelImportResult();
}

class DataExcelImportSuccess extends DataExcelImportResult {
  const DataExcelImportSuccess(this.message);
  final String message;
}

class DataExcelImportFailure extends DataExcelImportResult {
  const DataExcelImportFailure(this.message);
  final String message;
}

class DataExcelImportCancelled extends DataExcelImportResult {
  const DataExcelImportCancelled({this.message});
  final String? message;
}
