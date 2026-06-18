import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/models/ledger_category.dart';
import 'package:ledger_app/models/ledger_record.dart';

void main() {
  group('resolveCategoryLabel', () {
    test('uses default parent when ledger only has orphan category', () {
      final orphanCategories = [
        LedgerCategory(
          id: 'expense-高速费',
          name: '高速费',
          type: LedgerRecordType.expense,
          iconKey: 'toll',
        ),
      ];

      expect(
        resolveCategoryLabel(
          name: '高速费',
          type: LedgerRecordType.expense,
          ledgerCategories: orphanCategories,
        ),
        '交通·高速费',
      );
    });

    test('returns parent only when no subcategory is defined', () {
      expect(
        resolveCategoryLabel(
          name: '交通',
          type: LedgerRecordType.expense,
          ledgerCategories: const [],
        ),
        '交通',
      );
    });

    test('returns parent·child when ledger has full subcategory', () {
      final defaults = defaultCategories();
      final toll = defaults.firstWhere(
        (category) =>
            category.name == '高速费' &&
            category.type == LedgerRecordType.expense,
      );

      expect(
        resolveCategoryLabel(
          name: '高速费',
          type: LedgerRecordType.expense,
          ledgerCategories: defaults,
        ),
        '交通·高速费',
      );
      expect(toll.parentId, isNotNull);
    });
  });

  group('findCategoryByName', () {
    test('prefers subcategory over orphan with same name', () {
      final defaults = defaultCategories();
      final sub = defaults.firstWhere(
        (category) =>
            category.name == '高速费' &&
            category.type == LedgerRecordType.expense,
      );
      final orphan = LedgerCategory(
        id: 'expense-高速费',
        name: '高速费',
        type: LedgerRecordType.expense,
        iconKey: 'toll',
      );

      expect(
        findCategoryByName(
          [orphan, sub],
          name: '高速费',
          type: LedgerRecordType.expense,
        ),
        sub,
      );
    });
  });
}
