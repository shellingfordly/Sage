enum LedgerRecordType { expense, income }

class LedgerRecord {
  const LedgerRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.createdAt,
    this.notes = '',
  });

  final String id;
  final String title;
  final double amount;
  final LedgerRecordType type;
  final String category;
  final DateTime createdAt;
  final String notes;

  bool get isIncome => type == LedgerRecordType.income;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      if (notes.isNotEmpty) 'notes': notes,
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
      notes: json['notes'] as String? ?? '',
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
  }) {
    return LedgerRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
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
