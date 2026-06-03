/// PDF 提取文本的常见归一化：合并被拆开的汉字、统一空白等。
String normalizeBankBillText(String text) {
  var result = text
      .replaceAll('\u0000', '')
      .replaceAll('\r', '\n')
      .replaceAll('\u3000', ' ');

  result = _collapseCjkSpaces(result);
  result = result.replaceAll(RegExp(r'[ \t]+'), ' ');
  result = result.replaceAll(RegExp(r'\n[ \t]*'), '\n');
  return result.trim();
}

/// 用于关键字匹配的更激进压缩（去掉所有空白）。
String compactBankBillText(String text) {
  return normalizeBankBillText(text).replaceAll(RegExp(r'\s+'), '');
}

String _collapseCjkSpaces(String input) {
  var result = input;
  while (true) {
    final next = result.replaceAllMapped(
      RegExp(r'([\u4e00-\u9fff])\s+([\u4e00-\u9fff])'),
      (match) => '${match.group(1)}${match.group(2)}',
    );
    if (next == result) {
      return result;
    }
    result = next;
  }
}

bool bankBillTextContains(String haystack, String keyword) {
  return compactBankBillText(haystack).contains(keyword);
}
