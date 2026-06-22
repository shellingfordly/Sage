import 'package:ledger_app/models/import_category_rule.dart';
import 'package:ledger_app/services/bank_bill/import_category_rule_matcher.dart';
import 'package:test/test.dart';

void main() {
  const matcher = ImportCategoryRuleMatcher();

  ImportCategoryRule rule({
    required String id,
    required String keyword,
    required String category,
    required int sortOrder,
  }) {
    return ImportCategoryRule(
      id: id,
      keyword: keyword,
      category: category,
      sortOrder: sortOrder,
    );
  }

  group('ImportCategoryRuleMatcher', () {
    test('returns null when no rules or empty context', () {
      expect(
        matcher.match(context: '某某超市', rules: const []),
        isNull,
      );
      expect(
        matcher.match(
          context: '  ',
          rules: [rule(id: '1', keyword: '超市', category: '餐饮', sortOrder: 0)],
        ),
        isNull,
      );
    });

    test('matches keyword as substring case-insensitively', () {
      final matched = matcher.match(
        context: '微信支付-某某超市消费',
        rules: [
          rule(id: '1', keyword: '某某超市', category: '零食水果', sortOrder: 0),
        ],
      );

      expect(matched?.category, '零食水果');
    });

    test('prefers longer keyword over shorter', () {
      final matched = matcher.match(
        context: '先充后付高速费',
        rules: [
          rule(id: '1', keyword: '高速', category: '交通', sortOrder: 0),
          rule(id: '2', keyword: '先充后付', category: '加油充电', sortOrder: 1),
        ],
      );

      expect(matched?.keyword, '先充后付');
      expect(matched?.category, '加油充电');
    });

    test('uses sortOrder when keyword lengths are equal', () {
      final matched = matcher.match(
        context: '超市购物',
        rules: [
          rule(id: '1', keyword: '超市', category: '日用', sortOrder: 2),
          rule(id: '2', keyword: '超市', category: '零食水果', sortOrder: 0),
        ],
      );

      expect(matched?.id, '2');
      expect(matched?.category, '零食水果');
    });
  });
}
