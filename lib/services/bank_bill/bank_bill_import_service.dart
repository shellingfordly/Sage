import 'dart:typed_data';

import 'bank_bill_models.dart';
import 'bank_bill_pdf_extractor.dart';
import 'bank_bill_template.dart';

class BankBillImportService {
  const BankBillImportService();

  Future<BankBillParseResult> parsePdf(
    Uint8List bytes, {
    String? sourceName,
  }) async {
    try {
      final extractedText = await extractTextFromPdf(bytes, sourceName: sourceName);
      if (extractedText.trim().isEmpty) {
        return BankBillParseResult(
          templateId: '',
          templateName: '',
          fatalError: 'PDF 中未提取到文本，可能是扫描件或加密文件',
        );
      }

      final template = BankBillTemplateRegistry.defaultTemplate;
      final result = template.parse(extractedText);
      if (result.hasRecords) {
        return result;
      }

      if (result.fatalError != null) {
        return result;
      }

      return BankBillParseResult(
        templateId: template.id,
        templateName: template.displayName,
        fatalError: '未能从 PDF 中解析出有效账单行，请确认文件为${template.displayName}格式',
      );
    } catch (error) {
      return BankBillParseResult(
        templateId: '',
        templateName: '',
        fatalError: 'PDF 解析失败：$error',
      );
    }
  }
}
