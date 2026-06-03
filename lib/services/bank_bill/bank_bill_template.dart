import 'bank_bill_models.dart';
import 'templates/standard_table_template.dart';

/// PDF 账单解析模板接口，后续新增版式时实现此接口并注册即可。
abstract class BankBillTemplate {
  String get id;
  String get displayName;

  /// 判断提取出的 PDF 文本是否匹配该模板。
  bool canParse(String extractedText);

  /// 解析文本为账单记录；无法解析的行计入 [BankBillParseResult.skippedCount]。
  BankBillParseResult parse(String extractedText);
}

class BankBillTemplateRegistry {
  BankBillTemplateRegistry._();

  static final List<BankBillTemplate> templates = [
    StandardTableBankBillTemplate(),
  ];

  static BankBillTemplate get defaultTemplate => templates.first;

  static BankBillTemplate? detect(String extractedText) {
    for (final template in templates) {
      if (template.canParse(extractedText)) {
        return template;
      }
    }
    return null;
  }
}
