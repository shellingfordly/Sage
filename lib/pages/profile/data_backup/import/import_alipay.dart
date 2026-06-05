import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../data/ledger_store.dart';
import '../../../../services/bank_bill/bank_bill_import_service.dart';
import '../../../../utils/platform_file_bytes.dart';
import '../../bank_bill/bank_bill_import_review_page.dart';

class ImportAlipayService {
  const ImportAlipayService({BankBillImportService? bankBillImportService})
    : _bankBillImportService = bankBillImportService ?? const BankBillImportService();

  final BankBillImportService _bankBillImportService;

  Future<ImportAlipayResult> importFromFilePicker(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return const ImportAlipayCancelled();
      }

      final file = result.files.single;
      final bytes = await readPlatformFileBytes(file);
      final parsed = _bankBillImportService.parseCsv(bytes);

      if (parsed.isCompleteFailure && parsed.skippedRows.isEmpty) {
        return ImportAlipayFailure(parsed.fatalError ?? '支付宝账单解析失败');
      }

      if (!parsed.hasRecords && parsed.skippedRows.isEmpty) {
        return ImportAlipayFailure(
          parsed.fatalError ?? '未识别到可导入的账单记录',
        );
      }

      if (!context.mounted) {
        return const ImportAlipayCancelled();
      }

      final confirmedRecords = await openBankBillImportReviewPage(
        context,
        fileName: file.name,
        templateName: parsed.templateName,
        records: parsed.records,
        skippedRows: parsed.skippedRows,
      );
      if (confirmedRecords.isEmpty) {
        return const ImportAlipayCancelled(message: '已取消导入');
      }

      final added = await ledgerStore.importRecords(
        confirmedRecords,
        skipDuplicates: true,
      );
      if (added == 0) {
        return const ImportAlipayFailure('没有导入新记录（可能都已存在）');
      }

      final remainingSkipped = parsed.skippedRows.length;
      final skippedHint = remainingSkipped > 0
          ? '；另有 $remainingSkipped 行未导入（还款/退款/关闭交易等）'
          : '';
      return ImportAlipaySuccess('导入成功，新增 $added 条记录$skippedHint');
    } catch (error) {
      return ImportAlipayFailure('导入失败：$error');
    }
  }
}

sealed class ImportAlipayResult {
  const ImportAlipayResult();
}

class ImportAlipaySuccess extends ImportAlipayResult {
  const ImportAlipaySuccess(this.message);
  final String message;
}

class ImportAlipayFailure extends ImportAlipayResult {
  const ImportAlipayFailure(this.message);
  final String message;
}

class ImportAlipayCancelled extends ImportAlipayResult {
  const ImportAlipayCancelled({this.message});
  final String? message;
}
