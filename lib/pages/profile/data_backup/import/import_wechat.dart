import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../data/ledger_store.dart';
import '../../../../services/bank_bill/bank_bill_import_service.dart';
import '../../../../utils/platform_file_bytes.dart';
import '../../bank_bill/bank_bill_import_review_page.dart';

class ImportWechatService {
  const ImportWechatService({BankBillImportService? bankBillImportService})
    : _bankBillImportService = bankBillImportService ?? const BankBillImportService();

  final BankBillImportService _bankBillImportService;

  Future<ImportWechatResult> importFromFilePicker(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return const ImportWechatCancelled();
      }

      final file = result.files.single;
      final bytes = await readPlatformFileBytes(file);
      final parsed = _bankBillImportService.parseWechatXlsx(bytes);

      if (parsed.isCompleteFailure && parsed.skippedRows.isEmpty) {
        return ImportWechatFailure(parsed.fatalError ?? '微信账单解析失败');
      }

      if (!parsed.hasRecords && parsed.skippedRows.isEmpty) {
        return ImportWechatFailure(
          parsed.fatalError ?? '未识别到可导入的账单记录',
        );
      }

      if (!context.mounted) {
        return const ImportWechatCancelled();
      }

      final confirmedRecords = await openBankBillImportReviewPage(
        context,
        fileName: file.name,
        templateName: parsed.templateName,
        records: parsed.records,
        skippedRows: parsed.skippedRows,
      );
      if (confirmedRecords.isEmpty) {
        return const ImportWechatCancelled(message: '已取消导入');
      }

      final added = await ledgerStore.importRecords(
        confirmedRecords,
        skipDuplicates: true,
      );
      if (added == 0) {
        return const ImportWechatFailure('没有导入新记录（可能都已存在）');
      }

      final remainingSkipped = parsed.skippedRows.length;
      final skippedHint = remainingSkipped > 0
          ? '；另有 $remainingSkipped 行未导入（退款/已退款等）'
          : '';
      return ImportWechatSuccess('导入成功，新增 $added 条记录$skippedHint');
    } catch (error) {
      return ImportWechatFailure('导入失败：$error');
    }
  }
}

sealed class ImportWechatResult {
  const ImportWechatResult();
}

class ImportWechatSuccess extends ImportWechatResult {
  const ImportWechatSuccess(this.message);
  final String message;
}

class ImportWechatFailure extends ImportWechatResult {
  const ImportWechatFailure(this.message);
  final String message;
}

class ImportWechatCancelled extends ImportWechatResult {
  const ImportWechatCancelled({this.message});
  final String? message;
}
