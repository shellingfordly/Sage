import 'wealth_meta.dart';

enum LedgerRecordType { expense, income, wealth }

class LedgerRecord {
  const LedgerRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.createdAt,
    this.notes = '',
    this.source = '',
    this.wealthMeta = const WealthMeta(),
  });

  final String id;
  final String title;
  final double amount;
  final LedgerRecordType type;
  final String category;
  final DateTime createdAt;
  final String notes;

  /// 记录方式，如银行卡、微信、方式A 等。
  final String source;
  final WealthMeta wealthMeta;

  bool get isIncome => type == LedgerRecordType.income;

  bool get isExpense => type == LedgerRecordType.expense;

  bool get isWealth => type == LedgerRecordType.wealth;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      if (notes.isNotEmpty) 'notes': notes,
      if (source.isNotEmpty) 'source': source,
      if (isWealth && wealthMeta != const WealthMeta())
        'wealthMeta': wealthMeta.toJson(),
    };
  }

  factory LedgerRecord.fromJson(Map<String, Object?> json) {
    final type = _recordTypeFromName(json['type'] as String);
    final wealthMetaRaw = json['wealthMeta'];
    return LedgerRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: type,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String? ?? '',
      source: json['source'] as String? ?? '',
      wealthMeta: type == LedgerRecordType.wealth && wealthMetaRaw is Map
          ? WealthMeta.fromJson(Map<String, Object?>.from(wealthMetaRaw))
          : const WealthMeta(),
    );
  }

  LedgerRecord copyWith({
    String? id,
    String? title,
    double? amount,
    LedgerRecordType? type,
    String? category,
    DateTime? createdAt,
    String? notes,
    String? source,
    WealthMeta? wealthMeta,
  }) {
    final nextType = type ?? this.type;
    return LedgerRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: nextType,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      wealthMeta: nextType == LedgerRecordType.wealth
          ? (wealthMeta ?? this.wealthMeta)
          : const WealthMeta(),
    );
  }
}

LedgerRecordType _recordTypeFromName(String name) {
  return LedgerRecordType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => LedgerRecordType.expense,
  );
}

String ledgerRecordTypeLabel(LedgerRecordType type) {
  return switch (type) {
    LedgerRecordType.expense => '支出',
    LedgerRecordType.income => '收入',
    LedgerRecordType.wealth => '理财',
  };
}

class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.amount,
    required this.percent,
  });

  final String category;
  final double amount;
  final double percent;
}

class DailyExpenseTotal {
  const DailyExpenseTotal({required this.day, required this.amount});

  final int day;
  final double amount;
}
