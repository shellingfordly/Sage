import '../../models/ledger_record.dart';
import 'bank_bill_models.dart';

class BankBillCategoryResult {
  const BankBillCategoryResult({
    required this.type,
    required this.category,
    required this.reason,
  });

  final LedgerRecordType type;
  final String category;
  final String reason;
}

/// 仅根据交易摘要的通用关键词规则分类。
class BankBillCategorizer {
  const BankBillCategorizer();

  BankBillCategoryResult categorize(BankBillRawRow raw) {
    final type = raw.amount >= 0 ? LedgerRecordType.income : LedgerRecordType.expense;
    final summary = normalizeBankBillTransactionSummary(raw.transactionSummary);

    if (type == LedgerRecordType.income) {
      if (summary.contains('工资')) {
        return const BankBillCategoryResult(
          type: LedgerRecordType.income,
          category: '工资',
          reason: '交易摘要含「工资」',
        );
      }
      if (summary.contains('转账')) {
        return const BankBillCategoryResult(
          type: LedgerRecordType.income,
          category: '转账',
          reason: '交易摘要含「转账」',
        );
      }
      if (summary.contains('退款')) {
        return const BankBillCategoryResult(
          type: LedgerRecordType.income,
          category: '其他',
          reason: '交易摘要含「退款」',
        );
      }
      if (summary.contains('奖金')) {
        return const BankBillCategoryResult(
          type: LedgerRecordType.income,
          category: '奖金',
          reason: '交易摘要含「奖金」',
        );
      }
      if (_containsAny(summary, const ['理财', '基金', '利息', '收益', '分红'])) {
        return const BankBillCategoryResult(
          type: LedgerRecordType.income,
          category: '理财',
          reason: '交易摘要含理财相关词',
        );
      }
      return const BankBillCategoryResult(
        type: LedgerRecordType.income,
        category: '其他',
        reason: '未匹配到收入规则',
      );
    }

    // 支出侧含「工资」少见，归入其他避免误分类。
    if (summary.contains('工资')) {
      return const BankBillCategoryResult(
        type: LedgerRecordType.expense,
        category: '其他',
        reason: '交易摘要含「工资」（支出）',
      );
    }

    if (_containsAny(summary, const ['信用卡', '还款'])) {
      return const BankBillCategoryResult(
        type: LedgerRecordType.expense,
        category: '其他',
        reason: '交易摘要含还款相关词',
      );
    }

    if (_containsAny(summary, const ['转账', '汇款'])) {
      return const BankBillCategoryResult(
        type: LedgerRecordType.expense,
        category: '转账',
        reason: '交易摘要含转账相关词',
      );
    }

    if (_containsAny(summary, const ['基金', '申购', '赎回', '理财'])) {
      return const BankBillCategoryResult(
        type: LedgerRecordType.expense,
        category: '理财',
        reason: '交易摘要含基金/理财相关词',
      );
    }

    if (_containsAny(summary, const ['地铁', '公交', '出租', '加油', '停车', '铁路', '交通'])) {
      return const BankBillCategoryResult(
        type: LedgerRecordType.expense,
        category: '交通',
        reason: '交易摘要含交通相关词',
      );
    }

    if (_containsAny(summary, const ['医院', '药店', '药房', '诊所', '卫生', '医疗'])) {
      return const BankBillCategoryResult(
        type: LedgerRecordType.expense,
        category: '医疗',
        reason: '交易摘要含医疗相关词',
      );
    }

    if (_containsAny(summary, const ['学校', '培训', '教育', '课程', '书店', '图书馆'])) {
      return const BankBillCategoryResult(
        type: LedgerRecordType.expense,
        category: '学习',
        reason: '交易摘要含学习相关词',
      );
    }

    if (_containsAny(summary, const ['房租', '物业', '水电', '燃气', '宽带', '话费', '居住'])) {
      return const BankBillCategoryResult(
        type: LedgerRecordType.expense,
        category: '居住',
        reason: '交易摘要含居住相关词',
      );
    }

    if (_containsAny(summary, const ['视频', '游戏', '影院', '电影', '娱乐'])) {
      return const BankBillCategoryResult(
        type: LedgerRecordType.expense,
        category: '娱乐',
        reason: '交易摘要含娱乐相关词',
      );
    }

    if (_containsAny(summary, const ['餐厅', '外卖', '餐饮', '咖啡', '奶茶', '饭店', '食堂'])) {
      return const BankBillCategoryResult(
        type: LedgerRecordType.expense,
        category: '餐饮',
        reason: '交易摘要含餐饮相关词',
      );
    }

    if (_containsAny(summary, const ['支付', '消费', '购物', '超市', '便利店', '商城', '快捷'])) {
      return const BankBillCategoryResult(
        type: LedgerRecordType.expense,
        category: '购物',
        reason: '交易摘要含支付/消费相关词',
      );
    }

    return const BankBillCategoryResult(
      type: LedgerRecordType.expense,
      category: '其他',
      reason: '未匹配到支出规则',
    );
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}

String bankBillRecordTitle(BankBillRawRow raw) {
  final summary = normalizeBankBillTransactionSummary(raw.transactionSummary);
  if (summary.isNotEmpty) {
    return summary;
  }
  return '账单记录';
}
