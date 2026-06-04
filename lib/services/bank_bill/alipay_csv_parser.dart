import 'dart:convert';
import 'dart:typed_data';

import 'package:fast_gbk/fast_gbk.dart';

/// 解析支付宝导出的 CSV 单行（支持引号包裹字段）。
List<String> parseAlipayCsvLine(String line) {
  final result = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        buffer.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      result.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }

  result.add(buffer.toString());
  return result.map((value) => value.trim()).toList();
}

String decodeAlipayCsvText(Uint8List bytes) {
  final payload = _stripUtf8Bom(bytes);
  final utf8Text = utf8.decode(payload, allowMalformed: true);
  if (_looksLikeAlipayExport(utf8Text)) {
    return utf8Text;
  }

  try {
    final gbkText = gbk.decode(payload);
    if (_looksLikeAlipayExport(gbkText)) {
      return gbkText;
    }
  } catch (_) {
    // Fall back to UTF-8 below.
  }

  return utf8Text;
}

Uint8List _stripUtf8Bom(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return Uint8List.sublistView(bytes, 3);
  }
  return bytes;
}

bool _looksLikeAlipayExport(String content) {
  return content.contains('支付宝') && content.contains('交易时间,交易分类,交易对方');
}
