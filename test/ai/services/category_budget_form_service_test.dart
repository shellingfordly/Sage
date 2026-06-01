import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/ai/services/category_budget_form_service.dart';

void main() {
  group('CategoryBudgetFormService', () {
    const service = CategoryBudgetFormService();

    test('parses positive budget values and skips invalid entries', () {
      final result = service.parseBudgets(const <String, String>{
        '餐饮': '800',
        '交通': ' 300.5 ',
        '购物': '0',
        '娱乐': '-50',
        '医疗': 'abc',
        '': '100',
      });

      expect(result, const <String, double>{'餐饮': 800, '交通': 300.5});
    });

    test('sums parsed category budgets', () {
      final total = service.sumBudgets(const <String, double>{
        '餐饮': 800,
        '交通': 200,
      });

      expect(total, 1000);
    });

    test('creates draft budgets from monthly expense totals', () {
      final draft = service.createDraftFromSpending(const <String, double>{
        '餐饮': 1234.56,
        '交通': 0,
        '娱乐': -10,
        '购物': 300,
      });

      expect(draft, const <String, double>{'餐饮': 1234.56, '购物': 300});
    });

    test('creates draft budgets from previous month category budgets', () {
      final draft = service.createDraftFromPreviousBudgets(
        const <String, double>{'餐饮': 900, '交通': 0, '娱乐': -5, '购物': 300},
      );

      expect(draft, const <String, double>{'餐饮': 900, '购物': 300});
    });
  });
}
