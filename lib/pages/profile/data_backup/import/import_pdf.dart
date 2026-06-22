import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../data/ledger_store.dart';
import '../../../../services/bank_bill/bank_bill_import_service.dart';
import '../../../../utils/platform_file_bytes.dart';
import '../../bank_bill/bank_bill_import_review_page.dart';

class ImportPdfService {
  const ImportPdfService({BankBillImportService? bankBillImportService})
    : _bankBillImportService = bankBillImportService ?? const BankBillImportService();

  final BankBillImportService _bankBillImportService;

  Future<ImportPdfResult> importFromFilePicker(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return const ImportPdfCancelled();
      }

      final file = result.files.single;
      final bytes = await readPlatformFileBytes(file);
      final parsed = await _bankBillImportService.parsePdf(
        bytes,
        sourceName: file.name,
        customRules: ledgerStore.importCategoryRules,
      );

      if (parsed.isCompleteFailure && parsed.skippedRows.isEmpty) {
        return ImportPdfFailure(parsed.fatalError ?? 'PDF 账单解析失败');
      }

      if (!parsed.hasRecords && parsed.skippedRows.isEmpty) {
        return ImportPdfFailure(
          parsed.fatalError ?? '未识别到可导入的账单记录',
        );
      }

      if (!context.mounted) {
        return const ImportPdfCancelled();
      }

      final confirmedRecords = await openBankBillImportReviewPage(
        context,
        fileName: file.name,
        templateName: parsed.templateName,
        records: parsed.records,
        skippedRows: parsed.skippedRows,
      );
      if (confirmedRecords.isEmpty) {
        return const ImportPdfCancelled(message: '已取消导入');
      }

      final added = await ledgerStore.importRecords(
        confirmedRecords,
        skipDuplicates: true,
      );
      if (added == 0) {
        return const ImportPdfFailure('没有导入新记录（可能都已存在）');
      }

      final remainingSkipped = parsed.skippedRows.length;
      final skippedHint = remainingSkipped > 0
          ? '；另有 $remainingSkipped 行未导入（审核时已跳过）'
          : '';
      return ImportPdfSuccess('导入成功，新增 $added 条记录$skippedHint');
    } catch (error) {
      return ImportPdfFailure('导入失败：$error');
    }
  }
}

sealed class ImportPdfResult {
  const ImportPdfResult();
}

class ImportPdfSuccess extends ImportPdfResult {
  const ImportPdfSuccess(this.message);
  final String message;
}

class ImportPdfFailure extends ImportPdfResult {
  const ImportPdfFailure(this.message);
  final String message;
}

class ImportPdfCancelled extends ImportPdfResult {
  const ImportPdfCancelled({this.message});
  final String? message;
}
