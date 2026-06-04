import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/ledger_store.dart';
import '../../../services/bank_bill/bank_bill_import_service.dart';
import '../../../utils/platform_file_bytes.dart';
import '../bank_bill/bank_bill_import_review_page.dart';

class DataAlipayImportService {
  const DataAlipayImportService({BankBillImportService? bankBillImportService})
    : _bankBillImportService = bankBillImportService ?? const BankBillImportService();

  final BankBillImportService _bankBillImportService;

  Future<DataAlipayImportResult> importFromFilePicker(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return const DataAlipayImportCancelled();
      }

      final file = result.files.single;
      final bytes = await readPlatformFileBytes(file);
      final parsed = _bankBillImportService.parseCsv(bytes);

      if (parsed.isCompleteFailure && parsed.skippedRows.isEmpty) {
        return DataAlipayImportFailure(parsed.fatalError ?? '支付宝账单解析失败');
      }

      if (!parsed.hasRecords && parsed.skippedRows.isEmpty) {
        return DataAlipayImportFailure(
          parsed.fatalError ?? '未识别到可导入的账单记录',
        );
      }

      if (!context.mounted) {
        return const DataAlipayImportCancelled();
      }

      final confirmedRecords = await openBankBillImportReviewPage(
        context,
        fileName: file.name,
        templateName: parsed.templateName,
        records: parsed.records,
        skippedRows: parsed.skippedRows,
      );
      if (confirmedRecords.isEmpty) {
        return const DataAlipayImportCancelled(message: '已取消导入');
      }

      final added = await ledgerStore.importRecords(
        confirmedRecords,
        skipDuplicates: true,
      );
      if (added == 0) {
        return const DataAlipayImportFailure('没有导入新记录（可能都已存在）');
      }

      final remainingSkipped = parsed.skippedRows.length;
      final skippedHint = remainingSkipped > 0
          ? '；另有 $remainingSkipped 行未导入（还款/退款/关闭交易等）'
          : '';
      return DataAlipayImportSuccess('导入成功，新增 $added 条记录$skippedHint');
    } catch (error) {
      return DataAlipayImportFailure('导入失败：$error');
    }
  }
}

sealed class DataAlipayImportResult {
  const DataAlipayImportResult();
}

class DataAlipayImportSuccess extends DataAlipayImportResult {
  const DataAlipayImportSuccess(this.message);
  final String message;
}

class DataAlipayImportFailure extends DataAlipayImportResult {
  const DataAlipayImportFailure(this.message);
  final String message;
}

class DataAlipayImportCancelled extends DataAlipayImportResult {
  const DataAlipayImportCancelled({this.message});
  final String? message;
}
