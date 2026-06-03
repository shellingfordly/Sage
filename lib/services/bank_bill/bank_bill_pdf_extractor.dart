import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import 'bank_bill_text_normalizer.dart';

/// 使用 pdfrx 从 PDF 提取文本，并做账单场景下的归一化。
Future<String> extractTextFromPdf(Uint8List bytes, {String? sourceName}) async {
  final document = await PdfDocument.openData(
    bytes,
    sourceName: sourceName ?? 'statement.pdf',
  );
  try {
    final buffer = StringBuffer();
    for (final page in document.pages) {
      final pageText = await page.loadText();
      final text = pageText.fullText.trim();
      if (text.isEmpty) {
        continue;
      }
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.writeln(text);
    }
    return normalizeBankBillText(buffer.toString());
  } finally {
    await document.dispose();
  }
}
