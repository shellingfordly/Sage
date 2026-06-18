import 'package:flutter/material.dart';

import 'ledger_record.dart';

class LedgerCategory {
  const LedgerCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    this.parentId,
  });

  final String id;
  final String name;
  final LedgerRecordType type;
  final String iconKey;
  final String? parentId;

  bool get isSubcategory => parentId != null;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'iconKey': iconKey,
      if (parentId != null) 'parentId': parentId,
    };
  }

  factory LedgerCategory.fromJson(Map<String, Object?> json) {
    return LedgerCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _recordTypeFromName(json['type'] as String),
      iconKey: json['iconKey'] as String? ?? 'category',
      parentId: json['parentId'] as String?,
    );
  }

  LedgerCategory copyWith({
    String? id,
    String? name,
    LedgerRecordType? type,
    String? iconKey,
    String? parentId,
  }) {
    return LedgerCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      parentId: parentId ?? this.parentId,
    );
  }
}

List<LedgerCategory> topLevelCategories(
  Iterable<LedgerCategory> categories,
  LedgerRecordType type,
) {
  return categories
      .where((category) => category.type == type && category.parentId == null)
      .toList();
}

List<LedgerCategory> subcategoriesOf(
  Iterable<LedgerCategory> categories,
  String parentId,
) {
  return categories
      .where((category) => category.parentId == parentId)
      .toList();
}

bool categoryHasSubcategories(
  Iterable<LedgerCategory> categories,
  String parentId,
) {
  return subcategoriesOf(categories, parentId).isNotEmpty;
}

LedgerCategory? findCategoryByName(
  Iterable<LedgerCategory> categories, {
  required String name,
  required LedgerRecordType type,
}) {
  LedgerCategory? match;
  for (final category in categories) {
    if (category.type != type || category.name != name) {
      continue;
    }
    if (category.parentId != null) {
      return category;
    }
    match ??= category;
  }
  return match;
}

LedgerCategory resolveDisplayCategory(
  Iterable<LedgerCategory> categories, {
  required String name,
  required LedgerRecordType type,
}) {
  return findCategoryByName(categories, name: name, type: type) ??
      resolveOrphanCategory(type, name);
}

String formatCategoryLabel(
  Iterable<LedgerCategory> categories, {
  required String name,
  required LedgerRecordType type,
  String separator = '·',
}) {
  final category = findCategoryByName(categories, name: name, type: type);
  if (category == null || category.parentId == null) {
    return name;
  }
  for (final parent in categories) {
    if (parent.id == category.parentId) {
      return '${parent.name}$separator${category.name}';
    }
  }
  return name;
}

String formatCategoryLabelFromAll(
  Iterable<LedgerCategory> categories,
  String name,
) {
  for (final type in LedgerRecordType.values) {
    if (findCategoryByName(categories, name: name, type: type) != null) {
      return resolveCategoryLabel(
        name: name,
        type: type,
        ledgerCategories: categories,
      );
    }
  }
  return name;
}

String resolveCategoryLabel({
  required String name,
  required LedgerRecordType type,
  required Iterable<LedgerCategory> ledgerCategories,
  String separator = '·',
}) {
  final label = formatCategoryLabel(
    ledgerCategories,
    name: name,
    type: type,
    separator: separator,
  );
  if (label.contains(separator)) {
    return label;
  }

  final defaultLabel = formatCategoryLabel(
    defaultCategories().where((category) => category.type == type),
    name: name,
    type: type,
    separator: separator,
  );
  if (defaultLabel.contains(separator)) {
    return defaultLabel;
  }
  return label;
}

LedgerCategory resolveOrphanCategory(LedgerRecordType type, String name) {
  for (final category in defaultCategories()) {
    if (category.type == type && category.name == name) {
      return category;
    }
  }
  return LedgerCategory(
    id: '${type.name}-$name',
    name: name,
    type: type,
    iconKey: iconKeyForCategoryName(name, type),
  );
}

List<LedgerCategory> flattenCategoriesWithSubs(
  Iterable<LedgerCategory> parents,
  Iterable<LedgerCategory> all,
) {
  final result = <LedgerCategory>[];
  for (final parent in parents) {
    result.add(parent);
    result.addAll(subcategoriesOf(all, parent.id));
  }
  return result;
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
  CategoryIconOption(key: 'lunch', label: '正餐', icon: Icons.lunch_dining_outlined),
  CategoryIconOption(key: 'cafe', label: '咖啡', icon: Icons.local_cafe_outlined),
  CategoryIconOption(key: 'fastfood', label: '快餐', icon: Icons.fastfood_outlined),
  CategoryIconOption(key: 'cookie', label: '零食', icon: Icons.cookie_outlined),
  CategoryIconOption(key: 'fruit', label: '水果', icon: Icons.local_florist_outlined),
  CategoryIconOption(key: 'icecream', label: '冰品', icon: Icons.icecream_outlined),
  CategoryIconOption(key: 'rice', label: '粮油', icon: Icons.rice_bowl_outlined),
  CategoryIconOption(key: 'pantry', label: '储备', icon: Icons.inventory_2_outlined),
  CategoryIconOption(key: 'grocery', label: '超市', icon: Icons.local_grocery_store_outlined),
  CategoryIconOption(key: 'cake', label: '甜品', icon: Icons.cake_outlined),
  CategoryIconOption(key: 'wine', label: '酒水', icon: Icons.wine_bar_outlined),
  CategoryIconOption(key: 'liquor', label: '酒', icon: Icons.liquor_outlined),
  CategoryIconOption(key: 'tea', label: '茶', icon: Icons.emoji_food_beverage_outlined),
  CategoryIconOption(key: 'bus', label: '交通', icon: Icons.directions_bus_outlined),
  CategoryIconOption(key: 'car', label: '汽车', icon: Icons.directions_car_outlined),
  CategoryIconOption(key: 'subway', label: '地铁', icon: Icons.subway_outlined),
  CategoryIconOption(key: 'train', label: '火车', icon: Icons.train_outlined),
  CategoryIconOption(key: 'flight', label: '飞机', icon: Icons.flight_outlined),
  CategoryIconOption(key: 'taxi', label: '出租', icon: Icons.local_taxi_outlined),
  CategoryIconOption(key: 'bike', label: '骑行', icon: Icons.directions_bike_outlined),
  CategoryIconOption(key: 'gas', label: '加油', icon: Icons.local_gas_station_outlined),
  CategoryIconOption(key: 'ev', label: '充电', icon: Icons.ev_station_outlined),
  CategoryIconOption(key: 'parking', label: '停车', icon: Icons.local_parking_outlined),
  CategoryIconOption(key: 'toll', label: '高速', icon: Icons.toll_outlined),
  CategoryIconOption(key: 'car_repair', label: '修车', icon: Icons.car_repair_outlined),
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
  CategoryIconOption(key: 'redpacket', label: '红包', icon: Icons.redeem_outlined),
  CategoryIconOption(key: 'dining', label: '请客', icon: Icons.restaurant_menu_outlined),
  CategoryIconOption(key: 'ticket', label: '门票', icon: Icons.confirmation_number_outlined),
  CategoryIconOption(key: 'hospital', label: '医疗', icon: Icons.local_hospital_outlined),
  CategoryIconOption(key: 'medical', label: '诊疗', icon: Icons.medical_services_outlined),
  CategoryIconOption(key: 'pharmacy', label: '药品', icon: Icons.local_pharmacy_outlined),
  CategoryIconOption(key: 'heart', label: '保健', icon: Icons.monitor_heart_outlined),
  CategoryIconOption(key: 'fitness', label: '健身', icon: Icons.fitness_center_outlined),
  CategoryIconOption(key: 'spa', label: '美容', icon: Icons.spa_outlined),
  CategoryIconOption(key: 'cut', label: '美发', icon: Icons.content_cut_outlined),
  CategoryIconOption(key: 'face', label: '护肤', icon: Icons.face_retouching_natural_outlined),
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
      '兼职' => 'briefcase',
      '转账' => 'exchange',
      '投资收益' => 'trend',
      _ => 'category',
    };
  }
  if (type == LedgerRecordType.wealth) {
    return switch (name) {
      '定期存款' => 'bank',
      '活期·货币' => 'savings',
      '基金' => 'trend',
      '股票' => 'trend',
      '收益' => 'payments',
      _ => 'category',
    };
  }
  return switch (name) {
    '餐饮' => 'restaurant',
    '早中晚餐' => 'lunch',
    '咖啡奶茶' => 'cafe',
    '零食水果' => 'fruit',
    '粮油调味' => 'rice',
    '烟酒茶叶' => 'tea',
    '交通' => 'bus',
    '加油充电' => 'ev',
    '高速费' => 'toll',
    '停车' => 'parking',
    '公交地铁' => 'subway',
    '打车租车' => 'taxi',
    '火车飞机' => 'flight',
    '保养修车' => 'car_repair',
    '购物' => 'shopping',
    '日用百货' => 'store',
    '服饰鞋包' => 'clothing',
    '数码家电' => 'computer',
    '美妆护肤' => 'face',
    '居住' => 'home',
    '房租' => 'apartment',
    '水电燃气' => 'bolt',
    '物业维修' => 'repair',
    '家居装饰' => 'furniture',
    '娱乐' => 'movie',
    '电影演出' => 'theater',
    '游戏电竞' => 'game',
    '运动健身' => 'fitness',
    '聚会社交' => 'celebration',
    '医疗' => 'hospital',
    '看病买药' => 'pharmacy',
    '体检保健' => 'heart',
    '牙齿眼科' => 'medical',
    '学习' => 'school',
    '培训课程' => 'school',
    '书籍资料' => 'book',
    '考试报名' => 'receipt',
    '旅行' => 'beach',
    '机票酒店' => 'hotel',
    '景区门票' => 'ticket',
    '旅游购物' => 'shopping',
    '通讯' => 'phone',
    '话费流量' => 'phone',
    '宽带网络' => 'wifi',
    '美容' => 'spa',
    '护肤美发' => 'cut',
    '医美护理' => 'face',
    '宠物' => 'pets',
    '宠物食品' => 'pets',
    '宠物医疗' => 'medical',
    '宠物用品' => 'store',
    '社交' => 'celebration',
    '人情社交' => 'celebration',
    '礼金红包' => 'redpacket',
    '请客送礼' => 'dining',
    '转账' => 'exchange',
    '红包' => 'gift',
    _ => 'category',
  };
}

LedgerCategory _category({
  required String id,
  required String name,
  required LedgerRecordType type,
  required String iconKey,
  String? parentId,
}) {
  return LedgerCategory(
    id: id,
    name: name,
    type: type,
    iconKey: iconKey,
    parentId: parentId,
  );
}

void _addCategoryGroup(
  List<LedgerCategory> target, {
  required String id,
  required String name,
  required LedgerRecordType type,
  required String iconKey,
  List<(String id, String name, String iconKey)> subs = const [],
}) {
  target.add(_category(id: id, name: name, type: type, iconKey: iconKey));
  for (final sub in subs) {
    target.add(
      _category(
        id: sub.$1,
        name: sub.$2,
        type: type,
        iconKey: sub.$3,
        parentId: id,
      ),
    );
  }
}

List<LedgerCategory> defaultCategories() {
  final categories = <LedgerCategory>[];

  _addCategoryGroup(
    categories,
    id: 'expense-restaurant',
    name: '餐饮',
    type: LedgerRecordType.expense,
    iconKey: 'restaurant',
    subs: const [
      ('expense-restaurant-meals', '早中晚餐', 'lunch'),
      ('expense-restaurant-cafe', '咖啡奶茶', 'cafe'),
      ('expense-restaurant-snacks', '零食水果', 'fruit'),
      ('expense-restaurant-grocery', '粮油调味', 'rice'),
      ('expense-restaurant-drinks', '烟酒茶叶', 'tea'),
    ],
  );
  _addCategoryGroup(
    categories,
    id: 'expense-bus',
    name: '交通',
    type: LedgerRecordType.expense,
    iconKey: 'bus',
    subs: const [
      ('expense-bus-gas', '加油充电', 'ev'),
      ('expense-bus-toll', '高速费', 'toll'),
      ('expense-bus-parking', '停车', 'parking'),
      ('expense-bus-subway', '公交地铁', 'subway'),
      ('expense-bus-taxi', '打车租车', 'taxi'),
      ('expense-bus-train', '火车飞机', 'flight'),
      ('expense-bus-repair', '保养修车', 'car_repair'),
    ],
  );
  _addCategoryGroup(
    categories,
    id: 'expense-shopping',
    name: '购物',
    type: LedgerRecordType.expense,
    iconKey: 'shopping',
    subs: const [
      ('expense-shopping-daily', '日用百货', 'store'),
      ('expense-shopping-clothing', '服饰鞋包', 'clothing'),
      ('expense-shopping-digital', '数码家电', 'computer'),
      ('expense-shopping-beauty', '美妆护肤', 'face'),
    ],
  );
  _addCategoryGroup(
    categories,
    id: 'expense-home',
    name: '居住',
    type: LedgerRecordType.expense,
    iconKey: 'home',
    subs: const [
      ('expense-home-rent', '房租', 'apartment'),
      ('expense-home-utility', '水电燃气', 'bolt'),
      ('expense-home-property', '物业维修', 'repair'),
      ('expense-home-furniture', '家居装饰', 'furniture'),
    ],
  );
  _addCategoryGroup(
    categories,
    id: 'expense-movie',
    name: '娱乐',
    type: LedgerRecordType.expense,
    iconKey: 'movie',
    subs: const [
      ('expense-movie-film', '电影演出', 'theater'),
      ('expense-movie-game', '游戏电竞', 'game'),
      ('expense-movie-fitness', '运动健身', 'fitness'),
      ('expense-movie-party', '聚会社交', 'celebration'),
    ],
  );
  _addCategoryGroup(
    categories,
    id: 'expense-hospital',
    name: '医疗',
    type: LedgerRecordType.expense,
    iconKey: 'hospital',
    subs: const [
      ('expense-hospital-clinic', '看病买药', 'pharmacy'),
      ('expense-hospital-checkup', '体检保健', 'heart'),
      ('expense-hospital-pharmacy', '牙齿眼科', 'medical'),
    ],
  );
  _addCategoryGroup(
    categories,
    id: 'expense-school',
    name: '学习',
    type: LedgerRecordType.expense,
    iconKey: 'school',
    subs: const [
      ('expense-school-course', '培训课程', 'school'),
      ('expense-school-books', '书籍资料', 'book'),
      ('expense-school-exam', '考试报名', 'receipt'),
    ],
  );
  _addCategoryGroup(
    categories,
    id: 'expense-beach',
    name: '旅行',
    type: LedgerRecordType.expense,
    iconKey: 'beach',
    subs: const [
      ('expense-beach-transport', '机票酒店', 'hotel'),
      ('expense-beach-ticket', '景区门票', 'ticket'),
      ('expense-beach-shopping', '旅游购物', 'shopping'),
    ],
  );
  _addCategoryGroup(
    categories,
    id: 'expense-phone',
    name: '通讯',
    type: LedgerRecordType.expense,
    iconKey: 'phone',
    subs: const [
      ('expense-phone-mobile', '话费流量', 'phone'),
      ('expense-phone-broadband', '宽带网络', 'wifi'),
    ],
  );
  _addCategoryGroup(
    categories,
    id: 'expense-spa',
    name: '美容',
    type: LedgerRecordType.expense,
    iconKey: 'spa',
    subs: const [
      ('expense-spa-hair', '护肤美发', 'cut'),
      ('expense-spa-medical', '医美护理', 'face'),
    ],
  );
  _addCategoryGroup(
    categories,
    id: 'expense-pets',
    name: '宠物',
    type: LedgerRecordType.expense,
    iconKey: 'pets',
    subs: const [
      ('expense-pets-food', '宠物食品', 'pets'),
      ('expense-pets-medical', '宠物医疗', 'medical'),
      ('expense-pets-supplies', '宠物用品', 'store'),
    ],
  );
  _addCategoryGroup(
    categories,
    id: 'expense-social',
    name: '社交',
    type: LedgerRecordType.expense,
    iconKey: 'celebration',
    subs: const [
      ('expense-social-gift', '礼金红包', 'redpacket'),
      ('expense-social-treat', '请客送礼', 'dining'),
    ],
  );
  categories.addAll(const [
    LedgerCategory(
      id: 'expense-gift',
      name: '红包',
      type: LedgerRecordType.expense,
      iconKey: 'gift',
    ),
    LedgerCategory(
      id: 'expense-exchange',
      name: '转账',
      type: LedgerRecordType.expense,
      iconKey: 'exchange',
    ),
    LedgerCategory(
      id: 'expense-other',
      name: '其他',
      type: LedgerRecordType.expense,
      iconKey: 'category',
    ),
  ]);

  _addCategoryGroup(
    categories,
    id: 'income-work',
    name: '工资',
    type: LedgerRecordType.income,
    iconKey: 'work',
    subs: const [
      ('income-work-base', '基本工资', 'work'),
      ('income-work-bonus', '绩效提成', 'award'),
      ('income-work-year-end', '年终奖金', 'celebration'),
    ],
  );
  categories.add(
    _category(
      id: 'income-award',
      name: '奖金',
      type: LedgerRecordType.income,
      iconKey: 'award',
    ),
  );
  _addCategoryGroup(
    categories,
    id: 'income-briefcase',
    name: '兼职',
    type: LedgerRecordType.income,
    iconKey: 'briefcase',
    subs: const [
      ('income-briefcase-side', '副业收入', 'briefcase'),
      ('income-briefcase-writing', '稿酬稿费', 'book'),
    ],
  );
  categories.addAll(const [
    LedgerCategory(
      id: 'income-investment',
      name: '投资收益',
      type: LedgerRecordType.income,
      iconKey: 'trend',
    ),
    LedgerCategory(
      id: 'income-exchange',
      name: '转账',
      type: LedgerRecordType.income,
      iconKey: 'exchange',
    ),
    LedgerCategory(
      id: 'income-other',
      name: '其他',
      type: LedgerRecordType.income,
      iconKey: 'category',
    ),
  ]);

  categories.addAll(const [
    LedgerCategory(
      id: 'wealth-fixed-deposit',
      name: '定期存款',
      type: LedgerRecordType.wealth,
      iconKey: 'bank',
    ),
    LedgerCategory(
      id: 'wealth-demand',
      name: '活期·货币',
      type: LedgerRecordType.wealth,
      iconKey: 'savings',
    ),
    LedgerCategory(
      id: 'wealth-fund',
      name: '基金',
      type: LedgerRecordType.wealth,
      iconKey: 'trend',
    ),
    LedgerCategory(
      id: 'wealth-stock',
      name: '股票',
      type: LedgerRecordType.wealth,
      iconKey: 'trend',
    ),
    LedgerCategory(
      id: 'wealth-yield',
      name: '收益',
      type: LedgerRecordType.wealth,
      iconKey: 'payments',
    ),
    LedgerCategory(
      id: 'wealth-other',
      name: '其他',
      type: LedgerRecordType.wealth,
      iconKey: 'category',
    ),
  ]);

  return categories;
}

LedgerRecordType _recordTypeFromName(String name) {
  return LedgerRecordType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => LedgerRecordType.expense,
  );
}
