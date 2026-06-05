import '../../models/ledger_record.dart';

const _nonConsumptionCategoryKeywords = <String>{
  '转账',
  '转帐',
  '定存',
  '存款',
  '还款',
  '借呗',
  '房贷',
  '车贷',
  '理财',
  '基金',
  '股票',
  '提现',
  '内部转账',
  '资金划转',
};

const _nonConsumptionTitleKeywords = <String>{
  '转账',
  '转帐',
  '定存',
  '还款',
  '内部转',
  '提现',
};

bool isNonConsumptionRecord(LedgerRecord record) {
  if (record.isIncome) {
    return false;
  }
  final category = record.category.trim();
  final title = record.title.trim();
  for (final keyword in _nonConsumptionCategoryKeywords) {
    if (category.contains(keyword)) {
      return true;
    }
  }
  for (final keyword in _nonConsumptionTitleKeywords) {
    if (title.contains(keyword)) {
      return true;
    }
  }
  return false;
}

bool isConsumptionExpense(LedgerRecord record) {
  return !record.isIncome && !isNonConsumptionRecord(record);
}

List<LedgerRecord> consumptionExpenses(Iterable<LedgerRecord> records) {
  return records.where(isConsumptionExpense).toList();
}
