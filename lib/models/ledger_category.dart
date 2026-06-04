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
  CategoryIconOption(key: 'cafe', label: '咖啡', icon: Icons.local_cafe_outlined),
  CategoryIconOption(key: 'fastfood', label: '快餐', icon: Icons.fastfood_outlined),
  CategoryIconOption(key: 'grocery', label: '超市', icon: Icons.local_grocery_store_outlined),
  CategoryIconOption(key: 'cake', label: '甜品', icon: Icons.cake_outlined),
  CategoryIconOption(key: 'wine', label: '酒水', icon: Icons.wine_bar_outlined),
  CategoryIconOption(key: 'bus', label: '交通', icon: Icons.directions_bus_outlined),
  CategoryIconOption(key: 'car', label: '汽车', icon: Icons.directions_car_outlined),
  CategoryIconOption(key: 'subway', label: '地铁', icon: Icons.subway_outlined),
  CategoryIconOption(key: 'train', label: '火车', icon: Icons.train_outlined),
  CategoryIconOption(key: 'flight', label: '飞机', icon: Icons.flight_outlined),
  CategoryIconOption(key: 'taxi', label: '出租', icon: Icons.local_taxi_outlined),
  CategoryIconOption(key: 'bike', label: '骑行', icon: Icons.directions_bike_outlined),
  CategoryIconOption(key: 'gas', label: '加油', icon: Icons.local_gas_station_outlined),
  CategoryIconOption(key: 'parking', label: '停车', icon: Icons.local_parking_outlined),
  CategoryIconOption(key: 'shopping', label: '购物', icon: Icons.shopping_bag_outlined),
  CategoryIconOption(key: 'store', label: '商店', icon: Icons.storefront_outlined),
  CategoryIconOption(key: 'clothing', label: '服饰', icon: Icons.checkroom_outlined),
  CategoryIconOption(key: 'diamond', label: '珠宝', icon: Icons.diamond_outlined),
  CategoryIconOption(key: 'gift', label: '礼物', icon: Icons.card_giftcard_outlined),
  CategoryIconOption(key: 'home', label: '居住', icon: Icons.home_outlined),
  CategoryIconOption(key: 'apartment', label: '房租', icon: Icons.apartment_outlined),
  CategoryIconOption(key: 'furniture', label: '家具', icon: Icons.chair_outlined),
  CategoryIconOption(key: 'kitchen', label: '家电', icon: Icons.kitchen_outlined),
  CategoryIconOption(key: 'bolt', label: '水电', icon: Icons.bolt_outlined),
  CategoryIconOption(key: 'water', label: '用水', icon: Icons.water_drop_outlined),
  CategoryIconOption(key: 'wifi', label: '网络', icon: Icons.wifi_outlined),
  CategoryIconOption(key: 'phone', label: '通讯', icon: Icons.phone_iphone_outlined),
  CategoryIconOption(key: 'cleaning', label: '清洁', icon: Icons.cleaning_services_outlined),
  CategoryIconOption(key: 'laundry', label: '洗衣', icon: Icons.local_laundry_service_outlined),
  CategoryIconOption(key: 'repair', label: '维修', icon: Icons.handyman_outlined),
  CategoryIconOption(key: 'movie', label: '娱乐', icon: Icons.movie_outlined),
  CategoryIconOption(key: 'music', label: '音乐', icon: Icons.music_note_outlined),
  CategoryIconOption(key: 'game', label: '游戏', icon: Icons.sports_esports_outlined),
  CategoryIconOption(key: 'theater', label: '演出', icon: Icons.theater_comedy_outlined),
  CategoryIconOption(key: 'camera', label: '摄影', icon: Icons.photo_camera_outlined),
  CategoryIconOption(key: 'park', label: '户外', icon: Icons.park_outlined),
  CategoryIconOption(key: 'beach', label: '旅行', icon: Icons.beach_access_outlined),
  CategoryIconOption(key: 'hotel', label: '住宿', icon: Icons.hotel_outlined),
  CategoryIconOption(key: 'celebration', label: '聚会', icon: Icons.celebration_outlined),
  CategoryIconOption(key: 'hospital', label: '医疗', icon: Icons.local_hospital_outlined),
  CategoryIconOption(key: 'pharmacy', label: '药品', icon: Icons.local_pharmacy_outlined),
  CategoryIconOption(key: 'fitness', label: '健身', icon: Icons.fitness_center_outlined),
  CategoryIconOption(key: 'spa', label: '美容', icon: Icons.spa_outlined),
  CategoryIconOption(key: 'pets', label: '宠物', icon: Icons.pets_outlined),
  CategoryIconOption(key: 'child', label: '育儿', icon: Icons.child_care_outlined),
  CategoryIconOption(key: 'school', label: '学习', icon: Icons.school_outlined),
  CategoryIconOption(key: 'book', label: '书籍', icon: Icons.menu_book_outlined),
  CategoryIconOption(key: 'computer', label: '数码', icon: Icons.computer_outlined),
  CategoryIconOption(key: 'subscription', label: '订阅', icon: Icons.subscriptions_outlined),
  CategoryIconOption(key: 'work', label: '工资', icon: Icons.work_outline),
  CategoryIconOption(key: 'award', label: '奖金', icon: Icons.workspace_premium_outlined),
  CategoryIconOption(key: 'trend', label: '理财', icon: Icons.trending_up),
  CategoryIconOption(key: 'briefcase', label: '兼职', icon: Icons.business_center_outlined),
  CategoryIconOption(key: 'sell', label: '出售', icon: Icons.sell_outlined),
  CategoryIconOption(key: 'payments', label: '收款', icon: Icons.payments_outlined),
  CategoryIconOption(key: 'wallet', label: '钱包', icon: Icons.account_balance_wallet_outlined),
  CategoryIconOption(key: 'bank', label: '银行', icon: Icons.account_balance_outlined),
  CategoryIconOption(key: 'credit_card', label: '信用卡', icon: Icons.credit_card_outlined),
  CategoryIconOption(key: 'savings', label: '储蓄', icon: Icons.savings_outlined),
  CategoryIconOption(key: 'receipt', label: '报销', icon: Icons.receipt_long_outlined),
  CategoryIconOption(key: 'exchange', label: '转账', icon: Icons.currency_exchange_outlined),
  CategoryIconOption(key: 'volunteer', label: '捐赠', icon: Icons.volunteer_activism_outlined),
  CategoryIconOption(key: 'shield', label: '保险', icon: Icons.shield_outlined),
  CategoryIconOption(key: 'tax', label: '税费', icon: Icons.percent_outlined),
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
