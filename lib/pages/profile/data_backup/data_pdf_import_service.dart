import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/ledger_store.dart';
import '../../../services/bank_bill/bank_bill_import_service.dart';
import '../../../utils/platform_file_bytes.dart';
import '../bank_bill/bank_bill_import_review_page.dart';

class DataPdfImportService {
  const DataPdfImportService({BankBillImportService? bankBillImportService})
    : _bankBillImportService = bankBillImportService ?? const BankBillImportService();

  final BankBillImportService _bankBillImportService;

  Future<DataPdfImportResult> importFromFilePicker(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return const DataPdfImportCancelled();
      }

      final file = result.files.single;
      final bytes = await readPlatformFileBytes(file);
      final parsed = await _bankBillImportService.parsePdf(
        bytes,
        sourceName: file.name,
      );

      if (parsed.isCompleteFailure && parsed.skippedRows.isEmpty) {
        return DataPdfImportFailure(parsed.fatalError ?? 'PDF 账单解析失败');
      }

      if (!parsed.hasRecords && parsed.skippedRows.isEmpty) {
        return DataPdfImportFailure(
          parsed.fatalError ?? '未识别到可导入的账单记录',
        );
      }

      if (!context.mounted) {
        return const DataPdfImportCancelled();
      }

      final confirmedRecords = await openBankBillImportReviewPage(
        context,
        fileName: file.name,
        templateName: parsed.templateName,
        records: parsed.records,
        skippedRows: parsed.skippedRows,
      );
      if (confirmedRecords.isEmpty) {
        return const DataPdfImportCancelled(message: '已取消导入');
      }

      final added = await ledgerStore.importRecords(
        confirmedRecords,
        skipDuplicates: true,
      );
      if (added == 0) {
        return const DataPdfImportFailure('没有导入新记录（可能都已存在）');
      }

      final remainingSkipped = parsed.skippedRows.length;
      final skippedHint = remainingSkipped > 0
          ? '；另有 $remainingSkipped 行未导入（审核时已跳过）'
          : '';
      return DataPdfImportSuccess('导入成功，新增 $added 条记录$skippedHint');
    } catch (error) {
      return DataPdfImportFailure('导入失败：$error');
    }
  }
}

sealed class DataPdfImportResult {
  const DataPdfImportResult();
}

class DataPdfImportSuccess extends DataPdfImportResult {
  const DataPdfImportSuccess(this.message);
  final String message;
}

class DataPdfImportFailure extends DataPdfImportResult {
  const DataPdfImportFailure(this.message);
  final String message;
}

class DataPdfImportCancelled extends DataPdfImportResult {
  const DataPdfImportCancelled({this.message});
  final String? message;
}
