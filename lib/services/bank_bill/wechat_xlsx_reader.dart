import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// 从微信导出的 xlsx 中读取表格行（每行按列索引 0 起）。
List<List<String>> readWeChatXlsxRows(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final worksheetFile = archive.files
        .where((file) => file.isFile && file.name == 'xl/worksheets/sheet1.xml')
        .cast<ArchiveFile?>()
        .firstWhere((file) => file != null, orElse: () => null);
    if (worksheetFile == null) {
      return const [];
    }

    final sharedStrings = _readSharedStrings(archive);
    final sheetXml = utf8.decode(worksheetFile.content as List<int>);
    final document = XmlDocument.parse(sheetXml);
    final rows = document.findAllElements('row').toList();
    final result = <List<String>>[];

    for (final row in rows) {
      final columns = <int, String>{};
      var currentCol = 0;
      for (final cell in row.findElements('c')) {
        final ref = cell.getAttribute('r') ?? '';
        final col = _columnIndexFromRef(ref) ?? currentCol;
        columns[col] = _cellTextFromXml(cell, sharedStrings);
        currentCol = col + 1;
      }
      if (columns.isEmpty) {
        continue;
      }
      final maxCol = columns.keys.reduce((a, b) => a > b ? a : b);
      final line = List<String>.generate(maxCol + 1, (index) => columns[index] ?? '');
      result.add(line);
    }
    return result;
  } catch (_) {
    return const [];
  }
}

List<String> _readSharedStrings(Archive archive) {
  ArchiveFile? file;
  for (final item in archive.files) {
    if (item.name == 'xl/sharedStrings.xml') {
      file = item;
      break;
    }
  }
  if (file == null) {
    return const <String>[];
  }
  final xml = utf8.decode(file.content as List<int>);
  final document = XmlDocument.parse(xml);
  final values = <String>[];
  for (final item in document.findAllElements('si')) {
    final texts = item.findAllElements('t').map((node) => node.innerText).toList();
    values.add(texts.join());
  }
  return values;
}

int? _columnIndexFromRef(String ref) {
  if (ref.isEmpty) {
    return null;
  }
  final letters = ref.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
  if (letters.isEmpty) {
    return null;
  }
  var result = 0;
  for (var i = 0; i < letters.length; i++) {
    result = result * 26 + (letters.codeUnitAt(i) - 64);
  }
  return result - 1;
}

String _cellTextFromXml(XmlElement cell, List<String> sharedStrings) {
  final type = cell.getAttribute('t');
  if (type == 's') {
    final index = int.tryParse(cell.getElement('v')?.innerText ?? '');
    if (index != null && index >= 0 && index < sharedStrings.length) {
      return sharedStrings[index];
    }
    return '';
  }
  if (type == 'inlineStr') {
    final texts = cell.findAllElements('t').map((node) => node.innerText).toList();
    return texts.join();
  }
  return cell.getElement('v')?.innerText ?? '';
}
