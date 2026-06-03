import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xl;
import 'package:xml/xml.dart';

import '../models/import_parse_result.dart';
import '../models/ledger_record.dart';
import 'record_import_parser.dart';

ImportParseResult parseExcelRecords(Uint8List bytes) {
  try {
    final excel = xl.Excel.decodeBytes(bytes);
    final records = <LedgerRecord>[];
    final failedRows = <ImportFailure>[];
    for (final table in excel.tables.values) {
      if (table.rows.isEmpty) {
        continue;
      }
      for (var rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
        final row = table.rows[rowIndex];
        final parsed = _parseRecordCells(
          rowNumber: rowIndex + 1,
          dateCell: row.elementAtOrNull(0),
          typeCell: row.elementAtOrNull(1),
          categoryCell: row.elementAtOrNull(2),
          titleCell: row.elementAtOrNull(3),
          amountCell: row.elementAtOrNull(4),
          notesCell: row.elementAtOrNull(5),
        );
        if (parsed.record != null) {
          records.add(parsed.record!);
        } else if (parsed.failure != null) {
          failedRows.add(parsed.failure!);
        }
      }
    }
    return ImportParseResult(records: records, failedRows: failedRows);
  } catch (error) {
    final fallback = _parseXlsxByXml(bytes);
    if (fallback != null) {
      return fallback;
    }
    return ImportParseResult(
      records: const [],
      failedRows: const [],
      fatalError: 'Excel 解析失败，请确认文件未损坏并使用 xlsx 格式：$error',
    );
  }
}

ImportParseResult parseCsvRecords(Uint8List bytes) {
  try {
    final content = utf8.decode(bytes, allowMalformed: true).replaceFirst('\ufeff', '');
    final lines = content.split('\n');
    final records = <LedgerRecord>[];
    final failedRows = <ImportFailure>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        continue;
      }
      final columns = line.split(',');
      final parsed = parseImportRecordColumns(
        rowNumber: i + 1,
        dateText: columns.elementAtOrNull(0) ?? '',
        typeText: columns.elementAtOrNull(1) ?? '',
        categoryText: columns.elementAtOrNull(2) ?? '',
        titleText: columns.elementAtOrNull(3) ?? '',
        amountText: columns.elementAtOrNull(4) ?? '',
        notesText: columns.elementAtOrNull(5) ?? '',
      );
      if (parsed.record != null) {
        records.add(parsed.record!);
      } else if (parsed.failure != null) {
        failedRows.add(parsed.failure!);
      }
    }
    return ImportParseResult(records: records, failedRows: failedRows);
  } catch (error) {
    return ImportParseResult(
      records: const [],
      failedRows: const [],
      fatalError: 'CSV 解析失败，请检查分隔符与编码：$error',
    );
  }
}

ImportParseResult? _parseXlsxByXml(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final worksheetFiles = archive.files
        .where((file) => !file.isFile ? false : file.name.startsWith('xl/worksheets/sheet'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    if (worksheetFiles.isEmpty) {
      return null;
    }

    final sharedStrings = _readSharedStrings(archive);
    final records = <LedgerRecord>[];
    final failedRows = <ImportFailure>[];
    for (final worksheetFile in worksheetFiles) {
      final sheetXml = utf8.decode(worksheetFile.content as List<int>);
      final document = XmlDocument.parse(sheetXml);
      final rows = document.findAllElements('row').toList();

      for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        final rowNumber = int.tryParse(row.getAttribute('r') ?? '') ?? (rowIndex + 1);
        if (rowNumber <= 1) {
          continue;
        }

        final columns = <int, String>{};
        var currentCol = 0;
        for (final cell in row.findElements('c')) {
          final ref = cell.getAttribute('r') ?? '';
          final col = _columnIndexFromRef(ref) ?? currentCol;
          columns[col] = _cellTextFromXml(cell, sharedStrings);
          currentCol = col + 1;
        }

        final parsed = parseImportRecordColumns(
          rowNumber: rowNumber,
          dateText: columns[0] ?? '',
          typeText: columns[1] ?? '',
          categoryText: columns[2] ?? '',
          titleText: columns[3] ?? '',
          amountText: columns[4] ?? '',
          notesText: columns[5] ?? '',
        );
        if (parsed.record != null) {
          records.add(parsed.record!);
        } else if (parsed.failure != null) {
          failedRows.add(parsed.failure!);
        }
      }
    }

    return ImportParseResult(records: records, failedRows: failedRows);
  } catch (_) {
    return null;
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

RecordRowParseResult _parseRecordCells({
  required int rowNumber,
  required xl.Data? dateCell,
  required xl.Data? typeCell,
  required xl.Data? categoryCell,
  required xl.Data? titleCell,
  required xl.Data? amountCell,
  xl.Data? notesCell,
}) {
  return parseImportRecordColumns(
    rowNumber: rowNumber,
    dateText: _cellString(dateCell),
    typeText: _cellString(typeCell),
    categoryText: _cellString(categoryCell),
    titleText: _cellString(titleCell),
    amountText: _amountTextFromCell(amountCell),
    notesText: _cellString(notesCell),
  );
}

String _cellString(xl.Data? cell) {
  final value = cell?.value;
  if (value == null) {
    return '';
  }
  if (value is xl.TextCellValue) {
    return value.value.text ?? '';
  }
  if (value is xl.IntCellValue) {
    return value.value.toString();
  }
  if (value is xl.DoubleCellValue) {
    return value.value.toString();
  }
  if (value is xl.DateTimeCellValue) {
    return value.asDateTimeLocal().toIso8601String();
  }
  if (value is xl.DateCellValue) {
    return value.asDateTimeLocal().toIso8601String();
  }
  return value.toString();
}

String _amountTextFromCell(xl.Data? cell) {
  final value = cell?.value;
  if (value is xl.IntCellValue) {
    return value.value.toString();
  }
  if (value is xl.DoubleCellValue) {
    return value.value.toString();
  }
  return _cellString(cell);
}
