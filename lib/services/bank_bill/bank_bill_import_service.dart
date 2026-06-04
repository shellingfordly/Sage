import 'dart:typed_data';

import 'bank_bill_models.dart';
import 'bank_bill_pdf_extractor.dart';
import 'bank_bill_template.dart';
import 'templates/alipay_csv_template.dart';
import 'templates/wechat_xlsx_template.dart';

class BankBillImportService {
  const BankBillImportService({
    AlipayCsvBillTemplate? alipayCsvTemplate,
    WeChatXlsxBillTemplate? wechatXlsxTemplate,
  })  : _alipayCsvTemplate = alipayCsvTemplate ?? const AlipayCsvBillTemplate(),
        _wechatXlsxTemplate = wechatXlsxTemplate ?? const WeChatXlsxBillTemplate();

  final AlipayCsvBillTemplate _alipayCsvTemplate;
  final WeChatXlsxBillTemplate _wechatXlsxTemplate;

  BankBillParseResult parseCsv(Uint8List bytes) {
    try {
      if (!_alipayCsvTemplate.canParseBytes(bytes)) {
        return const BankBillParseResult(
          templateId: '',
          templateName: '',
          fatalError: '不是支持的账单 CSV 格式，请使用支付宝导出的交易明细',
        );
      }

      final result = _alipayCsvTemplate.parseBytes(bytes);
      if (result.hasRecords) {
        return result;
      }
      if (result.fatalError != null) {
        return result;
      }

      return BankBillParseResult(
        templateId: _alipayCsvTemplate.id,
        templateName: _alipayCsvTemplate.displayName,
        fatalError: '未能从 CSV 中解析出有效账单行，请确认文件为${_alipayCsvTemplate.displayName}格式',
      );
    } catch (error) {
      return BankBillParseResult(
        templateId: '',
        templateName: '',
        fatalError: 'CSV 解析失败：$error',
      );
    }
  }

  BankBillParseResult parseWechatXlsx(Uint8List bytes) {
    try {
      if (!_wechatXlsxTemplate.canParseBytes(bytes)) {
        return const BankBillParseResult(
          templateId: '',
          templateName: '',
          fatalError: '不是支持的账单 xlsx 格式，请使用微信导出的账单流水',
        );
      }

      final result = _wechatXlsxTemplate.parseBytes(bytes);
      if (result.hasRecords) {
        return result;
      }
      if (result.fatalError != null) {
        return result;
      }

      return BankBillParseResult(
        templateId: _wechatXlsxTemplate.id,
        templateName: _wechatXlsxTemplate.displayName,
        fatalError: '未能从 xlsx 中解析出有效账单行，请确认文件为${_wechatXlsxTemplate.displayName}格式',
      );
    } catch (error) {
      return BankBillParseResult(
        templateId: '',
        templateName: '',
        fatalError: 'xlsx 解析失败：$error',
      );
    }
  }

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
