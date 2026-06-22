import '../../models/import_category_rule.dart';

/// 全局导入分类自定义规则匹配：优先最长关键词，同长度按用户排序。
class ImportCategoryRuleMatcher {
  const ImportCategoryRuleMatcher();

  ImportCategoryRule? match({
    required String context,
    required List<ImportCategoryRule> rules,
  }) {
    if (rules.isEmpty || context.trim().isEmpty) {
      return null;
    }

    final normalized = context.toLowerCase();
    ImportCategoryRule? best;

    for (final rule in rules) {
      final keyword = rule.keyword.trim();
      if (keyword.isEmpty) {
        continue;
      }
      if (!normalized.contains(keyword.toLowerCase())) {
        continue;
      }

      if (best == null) {
        best = rule;
        continue;
      }

      final lengthCompare = keyword.length.compareTo(best.keyword.trim().length);
      if (lengthCompare > 0) {
        best = rule;
        continue;
      }
      if (lengthCompare == 0 && rule.sortOrder < best.sortOrder) {
        best = rule;
      }
    }

    return best;
  }
}
