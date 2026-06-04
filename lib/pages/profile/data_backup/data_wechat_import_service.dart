import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/ledger_store.dart';
import '../../../services/bank_bill/bank_bill_import_service.dart';
import '../../../utils/platform_file_bytes.dart';
import '../bank_bill/bank_bill_import_review_page.dart';

class DataWechatImportService {
  const DataWechatImportService({BankBillImportService? bankBillImportService})
    : _bankBillImportService = bankBillImportService ?? const BankBillImportService();

  final BankBillImportService _bankBillImportService;

  Future<DataWechatImportResult> importFromFilePicker(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return const DataWechatImportCancelled();
      }

      final file = result.files.single;
      final bytes = await readPlatformFileBytes(file);
      final parsed = _bankBillImportService.parseWechatXlsx(bytes);

      if (parsed.isCompleteFailure && parsed.skippedRows.isEmpty) {
        return DataWechatImportFailure(parsed.fatalError ?? '微信账单解析失败');
      }

      if (!parsed.hasRecords && parsed.skippedRows.isEmpty) {
        return DataWechatImportFailure(
          parsed.fatalError ?? '未识别到可导入的账单记录',
        );
      }

      if (!context.mounted) {
        return const DataWechatImportCancelled();
      }

      final confirmedRecords = await openBankBillImportReviewPage(
        context,
        fileName: file.name,
        templateName: parsed.templateName,
        records: parsed.records,
        skippedRows: parsed.skippedRows,
      );
      if (confirmedRecords.isEmpty) {
        return const DataWechatImportCancelled(message: '已取消导入');
      }

      final added = await ledgerStore.importRecords(
        confirmedRecords,
        skipDuplicates: true,
      );
      if (added == 0) {
        return const DataWechatImportFailure('没有导入新记录（可能都已存在）');
      }

      final remainingSkipped = parsed.skippedRows.length;
      final skippedHint = remainingSkipped > 0
          ? '；另有 $remainingSkipped 行未导入（退款/已退款等）'
          : '';
      return DataWechatImportSuccess('导入成功，新增 $added 条记录$skippedHint');
    } catch (error) {
      return DataWechatImportFailure('导入失败：$error');
    }
  }
}

sealed class DataWechatImportResult {
  const DataWechatImportResult();
}

class DataWechatImportSuccess extends DataWechatImportResult {
  const DataWechatImportSuccess(this.message);
  final String message;
}

class DataWechatImportFailure extends DataWechatImportResult {
  const DataWechatImportFailure(this.message);
  final String message;
}

class DataWechatImportCancelled extends DataWechatImportResult {
  const DataWechatImportCancelled({this.message});
  final String? message;
}
