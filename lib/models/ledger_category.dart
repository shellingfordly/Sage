import 'package:flutter/material.dart';

import 'ledger_record.dart';

class LedgerCategory {
  const LedgerCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
  });

  final String id;
  final String name;
  final LedgerRecordType type;
  final String iconKey;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'iconKey': iconKey,
    };
  }

  factory LedgerCategory.fromJson(Map<String, Object?> json) {
    return LedgerCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _recordTypeFromName(json['type'] as String),
      iconKey: json['iconKey'] as String? ?? 'category',
    );
  }

  LedgerCategory copyWith({
    String? id,
    String? name,
    LedgerRecordType? type,
    String? iconKey,
  }) {
    return LedgerCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
    );
  }
}

class CategoryIconOption {
  const CategoryIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

const categoryIconOptions = <CategoryIconOption>[
  CategoryIconOption(key: 'restaurant', label: '餐饮', icon: Icons.restaurant_outlined),
  CategoryIconOption(key: 'bus', label: '交通', icon: Icons.directions_bus_outlined),
  CategoryIconOption(key: 'shopping', label: '购物', icon: Icons.shopping_bag_outlined),
  CategoryIconOption(key: 'home', label: '居住', icon: Icons.home_outlined),
  CategoryIconOption(key: 'movie', label: '娱乐', icon: Icons.movie_outlined),
  CategoryIconOption(key: 'hospital', label: '医疗', icon: Icons.local_hospital_outlined),
  CategoryIconOption(key: 'school', label: '学习', icon: Icons.school_outlined),
  CategoryIconOption(key: 'work', label: '工资', icon: Icons.work_outline),
  CategoryIconOption(key: 'award', label: '奖金', icon: Icons.workspace_premium_outlined),
  CategoryIconOption(key: 'trend', label: '理财', icon: Icons.trending_up),
  CategoryIconOption(key: 'briefcase', label: '兼职', icon: Icons.business_center_outlined),
  CategoryIconOption(key: 'category', label: '其他', icon: Icons.category_outlined),
];

const _categoryIconFallback = CategoryIconOption(
  key: 'category',
  label: '其他',
  icon: Icons.category_outlined,
);

IconData categoryIconForKey(String key) {
  for (final option in categoryIconOptions) {
    if (option.key == key) {
      return option.icon;
    }
  }
  return _categoryIconFallback.icon;
}

String iconKeyForCategoryName(String name, LedgerRecordType type) {
  if (type == LedgerRecordType.income) {
    return switch (name) {
      '工资' => 'work',
      '奖金' => 'award',
      '理财' => 'trend',
      '兼职' => 'briefcase',
      _ => 'category',
    };
  }
  return switch (name) {
    '餐饮' => 'restaurant',
    '交通' => 'bus',
    '购物' => 'shopping',
    '居住' => 'home',
    '娱乐' => 'movie',
    '医疗' => 'hospital',
    '学习' => 'school',
    _ => 'category',
  };
}

List<LedgerCategory> defaultCategories() {
  return [
    const LedgerCategory(
      id: 'expense-restaurant',
      name: '餐饮',
      type: LedgerRecordType.expense,
      iconKey: 'restaurant',
    ),
    const LedgerCategory(
      id: 'expense-bus',
      name: '交通',
      type: LedgerRecordType.expense,
      iconKey: 'bus',
    ),
    const LedgerCategory(
      id: 'expense-shopping',
      name: '购物',
      type: LedgerRecordType.expense,
      iconKey: 'shopping',
    ),
    const LedgerCategory(
      id: 'expense-home',
      name: '居住',
      type: LedgerRecordType.expense,
      iconKey: 'home',
    ),
    const LedgerCategory(
      id: 'expense-movie',
      name: '娱乐',
      type: LedgerRecordType.expense,
      iconKey: 'movie',
    ),
    const LedgerCategory(
      id: 'expense-hospital',
      name: '医疗',
      type: LedgerRecordType.expense,
      iconKey: 'hospital',
    ),
    const LedgerCategory(
      id: 'expense-school',
      name: '学习',
      type: LedgerRecordType.expense,
      iconKey: 'school',
    ),
    const LedgerCategory(
      id: 'expense-other',
      name: '其他',
      type: LedgerRecordType.expense,
      iconKey: 'category',
    ),
    const LedgerCategory(
      id: 'income-work',
      name: '工资',
      type: LedgerRecordType.income,
      iconKey: 'work',
    ),
    const LedgerCategory(
      id: 'income-award',
      name: '奖金',
      type: LedgerRecordType.income,
      iconKey: 'award',
    ),
    const LedgerCategory(
      id: 'income-trend',
      name: '理财',
      type: LedgerRecordType.income,
      iconKey: 'trend',
    ),
    const LedgerCategory(
      id: 'income-briefcase',
      name: '兼职',
      type: LedgerRecordType.income,
      iconKey: 'briefcase',
    ),
    const LedgerCategory(
      id: 'income-other',
      name: '其他',
      type: LedgerRecordType.income,
      iconKey: 'category',
    ),
  ];
}

LedgerRecordType _recordTypeFromName(String name) {
  return LedgerRecordType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => LedgerRecordType.expense,
  );
}
