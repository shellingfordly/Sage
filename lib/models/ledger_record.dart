enum LedgerRecordType { expense, income }

class LedgerRecord {
  const LedgerRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double amount;
  final LedgerRecordType type;
  final String category;
  final DateTime createdAt;

  bool get isIncome => type == LedgerRecordType.income;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LedgerRecord.fromJson(Map<String, Object?> json) {
    return LedgerRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: _recordTypeFromName(json['type'] as String),
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

LedgerRecordType _recordTypeFromName(String name) {
  return LedgerRecordType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => LedgerRecordType.expense,
  );
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
