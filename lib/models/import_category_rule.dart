class ImportCategoryRule {
  const ImportCategoryRule({
    required this.id,
    required this.keyword,
    required this.category,
    required this.sortOrder,
  });

  final String id;
  final String keyword;
  final String category;
  final int sortOrder;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'keyword': keyword,
      'category': category,
      'sortOrder': sortOrder,
    };
  }

  factory ImportCategoryRule.fromJson(Map<String, Object?> json) {
    return ImportCategoryRule(
      id: json['id'] as String,
      keyword: json['keyword'] as String,
      category: json['category'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  ImportCategoryRule copyWith({
    String? id,
    String? keyword,
    String? category,
    int? sortOrder,
  }) {
    return ImportCategoryRule(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
