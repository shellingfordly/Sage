class LedgerBook {
  const LedgerBook({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LedgerBook.fromJson(Map<String, Object?> json) {
    return LedgerBook(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  LedgerBook copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return LedgerBook(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
