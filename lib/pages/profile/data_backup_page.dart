import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../data/ledger_store.dart';
import '../../models/ledger_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/platform_file_io.dart';

enum _ExportRange { month, year, all, custom }

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  _ExportRange _range = _ExportRange.month;
  DateTimeRange? _customRange;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords();
    return Scaffold(
      appBar: AppBar(title: const Text('数据备份')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.surface(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('导出', style: AppTextStyles.sectionTitle(context)),
                    const SizedBox(height: 10),
                    SegmentedButton<_ExportRange>(
                      segments: const [
                        ButtonSegment(value: _ExportRange.month, label: Text('本月')),
                        ButtonSegment(value: _ExportRange.year, label: Text('本年')),
                        ButtonSegment(value: _ExportRange.all, label: Text('全部')),
                        ButtonSegment(value: _ExportRange.custom, label: Text('自定义')),
                      ],
                      selected: {_range},
                      onSelectionChanged: _busy
                          ? null
                          : (values) {
                              final next = values.first;
                              setState(() {
                                _range = next;
                                if (next == _ExportRange.custom && _customRange == null) {
                                  final now = DateTime.now();
                                  _customRange = DateTimeRange(
                                    start: DateTime(now.year, now.month, 1),
                                    end: DateTime(now.year, now.month, now.day),
                                  );
                                }
                              });
                            },
                    ),
                    if (_range == _ExportRange.custom) ...[
                      const SizedBox(height: 12),
                      Text('自定义时间范围', style: AppTextStyles.bodyStrong(context)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _pickCustomRange,
                              icon: const Icon(Icons.date_range_outlined),
                              label: Text(_customRange == null ? '选择时间范围' : _customRangeLabel()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: (_busy || _customRange == null)
                                ? null
                                : () => setState(() => _customRange = null),
                            child: const Text('清除'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text('预计导出 ${records.length} 条记录', style: AppTextStyles.bodyMuted(context)),
                    const SizedBox(height: 4),
                    Text('当前范围：${_currentRangeText()}', style: AppTextStyles.bodyMuted(context)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _previewExportData,
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('预览导出数据'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _exportExcel,
                            icon: const Icon(Icons.file_download_outlined),
                            label: Text(_busy ? '处理中...' : '导出 Excel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: AppDecorations.surface(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('导入', style: AppTextStyles.sectionTitle(context)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _importRecords,
                        icon: const Icon(Icons.file_upload_outlined),
                        label: const Text('导入账单文件'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '支持 Excel（.xlsx/.xls）和 CSV（.csv）导入。Word/PDF 的结构差异较大，当前版本暂不支持自动识别导入。',
                      style: AppTextStyles.bodyMuted(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<LedgerRecord> _filteredRecords() {
    final all = ledgerStore.records;
    final now = DateTime.now();
    return switch (_range) {
      _ExportRange.all => all,
      _ExportRange.month => all.where(
          (record) =>
              record.createdAt.year == now.year && record.createdAt.month == now.month,
        ).toList(),
      _ExportRange.year => all.where((record) => record.createdAt.year == now.year).toList(),
      _ExportRange.custom => _filterByCustomRange(all),
    };
  }

  List<LedgerRecord> _filterByCustomRange(List<LedgerRecord> all) {
    final range = _customRange;
    if (range == null) {
      return const [];
    }
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    return all
        .where(
          (record) => !record.createdAt.isBefore(start) && !record.createdAt.isAfter(end),
        )
        .toList();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          _customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month, now.day),
          ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: '选择导出时间范围',
      locale: const Locale('zh', 'CN'),
      cancelText: '取消',
      confirmText: '确定',
      saveText: '保存',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _customRange = picked;
    });
  }

  String _customRangeLabel() {
    final range = _customRange;
    if (range == null) {
      return '选择时间范围';
    }
    return '${range.start.year}/${range.start.month.toString().padLeft(2, '0')}/${range.start.day.toString().padLeft(2, '0')}'
        ' - '
        '${range.end.year}/${range.end.month.toString().padLeft(2, '0')}/${range.end.day.toString().padLeft(2, '0')}';
  }

  Future<void> _previewExportData() async {
    final records = _filteredRecords();
    if (records.isEmpty) {
      _showMessage('当前范围没有可预览的数据');
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => _DataPreviewPage(
          title: '导出数据预览',
          subtitle: '${_exportRangeLabel()}  ·  共 ${records.length} 条',
          columns: const ['日期', '类型', '分类', '名称', '金额'],
          rows: records
              .map(
                (record) => _PreviewRow(
                  cells: [
                    _formatDateTime(record.createdAt),
                    record.type == LedgerRecordType.income ? '收入' : '支出',
                    record.category,
                    record.title,
                    record.amount.toStringAsFixed(2),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _exportExcel() async {
    final records = _filteredRecords();
    if (records.isEmpty) {
      _showMessage('当前范围没有可导出的记录');
      return;
    }
    setState(() => _busy = true);
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['records'];
      sheet.appendRow([
        xl.TextCellValue('日期'),
        xl.TextCellValue('类型'),
        xl.TextCellValue('分类'),
        xl.TextCellValue('名称'),
        xl.TextCellValue('金额'),
      ]);

      for (final record in records) {
        final dateText =
            '${record.createdAt.year.toString().padLeft(4, '0')}-${record.createdAt.month.toString().padLeft(2, '0')}-${record.createdAt.day.toString().padLeft(2, '0')} '
            '${record.createdAt.hour.toString().padLeft(2, '0')}:${record.createdAt.minute.toString().padLeft(2, '0')}';
        sheet.appendRow([
          xl.TextCellValue(dateText),
          xl.TextCellValue(record.type == LedgerRecordType.income ? '收入' : '支出'),
          xl.TextCellValue(record.category),
          xl.TextCellValue(record.title),
          xl.DoubleCellValue(record.amount),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        _showMessage('导出失败，无法生成文件');
        return;
      }

      final suggestedName = _buildExportFileName();
      final path = await FilePicker.saveFile(
        dialogTitle: '保存导出的 Excel',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(bytes),
      );
      if (path != null) {
        _showMessage('导出成功：${_fileNameFromPath(path)}');
        return;
      }

      if (kIsWeb) {
        _showMessage('已取消导出');
        return;
      }

      // 部分桌面环境下 saveFile 可能返回 null，降级为手动选目录保存。
      final directory = await FilePicker.getDirectoryPath(dialogTitle: '选择导出目录');
      if (directory == null) {
        _showMessage('已取消导出');
        return;
      }
      final fallbackPath = '$directory/$suggestedName';
      await writeBytesToPath(fallbackPath, bytes);
      _showMessage('导出成功：$suggestedName');
    } catch (error) {
      _showMessage('导出失败：$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _buildExportFileName() {
    return switch (_range) {
      _ExportRange.month => 'ledger_${DateTime.now().year}_${DateTime.now().month.toString().padLeft(2, '0')}.xlsx',
      _ExportRange.year => 'ledger_${DateTime.now().year}.xlsx',
      _ExportRange.all => 'ledger_all.xlsx',
      _ExportRange.custom => _buildCustomRangeFileName(),
    };
  }

  String _buildCustomRangeFileName() {
    final range = _customRange;
    if (range == null) {
      return 'ledger_custom.xlsx';
    }
    final start = range.start;
    final end = range.end;
    return 'ledger_${start.year}${start.month.toString().padLeft(2, '0')}${start.day.toString().padLeft(2, '0')}_'
        '${end.year}${end.month.toString().padLeft(2, '0')}${end.day.toString().padLeft(2, '0')}.xlsx';
  }

  String _exportRangeLabel() {
    return switch (_range) {
      _ExportRange.month => '本月',
      _ExportRange.year => '本年',
      _ExportRange.all => '全部',
      _ExportRange.custom => '自定义',
    };
  }

  String _currentRangeText() {
    final now = DateTime.now();
    switch (_range) {
      case _ExportRange.month:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return '${_formatDate(start)} - ${_formatDate(end)}';
      case _ExportRange.year:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31);
        return '${_formatDate(start)} - ${_formatDate(end)}';
      case _ExportRange.custom:
        return _customRange == null ? '未设置' : _customRangeLabel();
      case _ExportRange.all:
        return _allRecordsRangeText();
    }
  }

  String _allRecordsRangeText() {
    final records = ledgerStore.records;
    if (records.isEmpty) {
      return '暂无数据';
    }
    DateTime earliest = records.first.createdAt;
    DateTime latest = records.first.createdAt;
    for (final record in records) {
      if (record.createdAt.isBefore(earliest)) {
        earliest = record.createdAt;
      }
      if (record.createdAt.isAfter(latest)) {
        latest = record.createdAt;
      }
    }
    return '${_formatDate(earliest)} - ${_formatDate(latest)}';
  }

  String _formatDate(DateTime value) {
    return '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> _importRecords() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'txt', 'pdf', 'doc', 'docx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.single;
      final extension = (file.extension ?? '').toLowerCase();
      if (extension == 'pdf' || extension == 'doc' || extension == 'docx') {
        _showMessage('当前版本暂不支持 PDF/Word 自动导入，请先转为 Excel 或 CSV');
        return;
      }

      final bytes = await _readFileBytes(file);
      final parsed = extension == 'csv' || extension == 'txt'
          ? _parseCsvRecords(bytes)
          : _parseExcelRecords(bytes);
      if (parsed.fatalError != null) {
        _showMessage(parsed.fatalError!);
        return;
      }
      if (parsed.records.isEmpty && parsed.failedRows.isNotEmpty) {
        await _showImportPreviewPage(fileName: file.name, parsed: parsed);
        return;
      }
      if (parsed.records.isEmpty) {
        _showMessage('未识别到可导入记录，请检查文件格式');
        return;
      }
      final confirmed = await _showImportPreviewPage(
        fileName: file.name,
        parsed: parsed,
      );
      if (confirmed != true) {
        _showMessage('已取消导入');
        return;
      }
      final added = await ledgerStore.importRecords(parsed.records, skipDuplicates: true);
      if (added == 0) {
        _showMessage('没有导入新记录（可能都已存在）');
      } else {
        final skipped = parsed.failedRows.length;
        if (skipped > 0) {
          _showMessage('导入成功，新增 $added 条；另有 $skipped 条格式不匹配已跳过');
        } else {
          _showMessage('导入成功，新增 $added 条记录');
        }
      }
    } catch (error) {
      _showMessage('导入失败：$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<Uint8List> _readFileBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    }
    final path = file.path;
    if (path == null) {
      throw StateError('无法读取文件');
    }
    return Uint8List.fromList(await readBytesFromPath(path));
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index < 0 ? normalized : normalized.substring(index + 1);
  }

  _ParsedRecords _parseExcelRecords(Uint8List bytes) {
    try {
      final excel = xl.Excel.decodeBytes(bytes);
      final records = <LedgerRecord>[];
      final failedRows = <_ImportFailure>[];
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
          );
          if (parsed.record != null) {
            records.add(parsed.record!);
          } else if (parsed.failure != null) {
            failedRows.add(parsed.failure!);
          }
        }
      }
      return _ParsedRecords(records: records, failedRows: failedRows);
    } catch (error) {
      final fallback = _parseXlsxByXml(bytes);
      if (fallback != null) {
        return fallback;
      }
      return _ParsedRecords(
        records: const [],
        failedRows: const [],
        fatalError: 'Excel 解析失败，请确认文件未损坏并使用 xlsx 格式：$error',
      );
    }
  }

  _ParsedRecords? _parseXlsxByXml(Uint8List bytes) {
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
      final failedRows = <_ImportFailure>[];
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

          final parsed = _parseRecordColumns(
            rowNumber: rowNumber,
            dateText: columns[0] ?? '',
            typeText: columns[1] ?? '',
            categoryText: columns[2] ?? '',
            titleText: columns[3] ?? '',
            amountText: columns[4] ?? '',
          );
          if (parsed.record != null) {
            records.add(parsed.record!);
          } else if (parsed.failure != null) {
            failedRows.add(parsed.failure!);
          }
        }
      }

      return _ParsedRecords(records: records, failedRows: failedRows);
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

  _ParsedRecords _parseCsvRecords(Uint8List bytes) {
    try {
      final content = utf8.decode(bytes, allowMalformed: true).replaceFirst('\ufeff', '');
      final lines = content.split('\n');
      final records = <LedgerRecord>[];
      final failedRows = <_ImportFailure>[];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) {
          continue;
        }
        final columns = line.split(',');
        final parsed = _parseRecordColumns(
          rowNumber: i + 1,
          dateText: columns.elementAtOrNull(0) ?? '',
          typeText: columns.elementAtOrNull(1) ?? '',
          categoryText: columns.elementAtOrNull(2) ?? '',
          titleText: columns.elementAtOrNull(3) ?? '',
          amountText: columns.elementAtOrNull(4) ?? '',
        );
        if (parsed.record != null) {
          records.add(parsed.record!);
        } else if (parsed.failure != null) {
          failedRows.add(parsed.failure!);
        }
      }
      return _ParsedRecords(records: records, failedRows: failedRows);
    } catch (error) {
      return _ParsedRecords(
        records: const [],
        failedRows: const [],
        fatalError: 'CSV 解析失败，请检查分隔符与编码：$error',
      );
    }
  }

  _RowParseResult _parseRecordCells({
    required int rowNumber,
    required xl.Data? dateCell,
    required xl.Data? typeCell,
    required xl.Data? categoryCell,
    required xl.Data? titleCell,
    required xl.Data? amountCell,
  }) {
    final title = _cellString(titleCell).trim();
    final category = _cellString(categoryCell).trim();
    final typeText = _cellString(typeCell).trim();
    final dateText = _cellString(dateCell).trim();
    final amountText = _cellString(amountCell).trim();
    if ([title, category, typeText, dateText, amountText].every((item) => item.isEmpty)) {
      return const _RowParseResult.empty();
    }
    if (title.isEmpty) {
      return _RowParseResult.failure(rowNumber, '名称为空');
    }
    if (category.isEmpty) {
      return _RowParseResult.failure(rowNumber, '分类为空');
    }
    final type = _parseType(_cellString(typeCell).trim());
    if (type == null) {
      return _RowParseResult.failure(rowNumber, '类型无效（需为“收入/支出”）');
    }
    final amount = _amountFromCell(amountCell);
    if (amount == null || amount <= 0) {
      return _RowParseResult.failure(rowNumber, '金额无效（需大于 0）');
    }
    final createdAt = _dateFromCell(dateCell);
    if (createdAt == null) {
      return _RowParseResult.failure(rowNumber, '日期无效');
    }
    return _RowParseResult.record(
      LedgerRecord(
        id: 'import-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        amount: amount,
        type: type,
        category: category,
        createdAt: createdAt,
      ),
    );
  }

  _RowParseResult _parseRecordColumns({
    required int rowNumber,
    required String dateText,
    required String typeText,
    required String categoryText,
    required String titleText,
    required String amountText,
  }) {
    final title = titleText.trim();
    final category = categoryText.trim();
    final typeRaw = typeText.trim();
    final dateRaw = dateText.trim();
    final amountRaw = amountText.trim();
    if ([title, category, typeRaw, dateRaw, amountRaw].every((item) => item.isEmpty)) {
      return const _RowParseResult.empty();
    }
    if (title.isEmpty) {
      return _RowParseResult.failure(rowNumber, '名称为空');
    }
    if (category.isEmpty) {
      return _RowParseResult.failure(rowNumber, '分类为空');
    }
    final type = _parseType(typeRaw);
    if (type == null) {
      return _RowParseResult.failure(rowNumber, '类型无效（需为“收入/支出”）');
    }
    final amount = _parseAmountText(amountText);
    if (amount == null || amount <= 0) {
      return _RowParseResult.failure(rowNumber, '金额无效（需大于 0）');
    }
    final createdAt = _parseDateText(dateText);
    if (createdAt == null) {
      return _RowParseResult.failure(rowNumber, '日期无效');
    }

    return _RowParseResult.record(
      LedgerRecord(
        id: 'import-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        amount: amount,
        type: type,
        category: category,
        createdAt: createdAt,
      ),
    );
  }

  LedgerRecordType? _parseType(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.contains('income') || normalized.contains('收入') || normalized.contains('收')) {
      return LedgerRecordType.income;
    }
    if (normalized.contains('expense') || normalized.contains('支出') || normalized.contains('支')) {
      return LedgerRecordType.expense;
    }
    return null;
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

  double? _amountFromCell(xl.Data? cell) {
    final value = cell?.value;
    if (value is xl.IntCellValue) {
      return value.value.toDouble();
    }
    if (value is xl.DoubleCellValue) {
      return value.value;
    }
    return _parseAmountText(_cellString(cell));
  }

  double? _parseAmountText(String raw) {
    var text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    text = text.replaceAll('￥', '').replaceAll('¥', '').replaceAll(',', '');
    text = text.replaceAll(' ', '');
    if (text.startsWith('(') && text.endsWith(')')) {
      text = '-${text.substring(1, text.length - 1)}';
    }
    return double.tryParse(text);
  }

  DateTime? _dateFromCell(xl.Data? cell) {
    final value = cell?.value;
    if (value is xl.DateTimeCellValue) {
      return value.asDateTimeLocal();
    }
    if (value is xl.DateCellValue) {
      return value.asDateTimeLocal();
    }
    return _parseDateText(_cellString(cell));
  }

  DateTime? _parseDateText(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    final normalized = text.replaceAll('/', '-');
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed;
    }
    final mdyMatch = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})(?:\s+(\d{1,2})(?::(\d{1,2})(?::(\d{1,2}))?)?)?$',
    ).firstMatch(text);
    if (mdyMatch != null) {
      final first = int.tryParse(mdyMatch.group(1)!);
      final secondPart = int.tryParse(mdyMatch.group(2)!);
      final yearRaw = int.tryParse(mdyMatch.group(3)!);
      final hour = int.tryParse(mdyMatch.group(4) ?? '0') ?? 0;
      final minute = int.tryParse(mdyMatch.group(5) ?? '0') ?? 0;
      final second = int.tryParse(mdyMatch.group(6) ?? '0') ?? 0;
      if (first != null && secondPart != null && yearRaw != null) {
        final year = yearRaw < 100 ? (2000 + yearRaw) : yearRaw;
        final month = first <= 12 ? first : secondPart;
        final day = first <= 12 ? secondPart : first;
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day, hour, minute, second);
        }
      }
    }
    final cnMatch = RegExp(
      r'^(\d{2,4})年(\d{1,2})月(\d{1,2})日(?:\s+(\d{1,2})(?::(\d{1,2})(?::(\d{1,2}))?)?)?$',
    ).firstMatch(text);
    if (cnMatch != null) {
      final yearRaw = int.tryParse(cnMatch.group(1)!);
      final month = int.tryParse(cnMatch.group(2)!);
      final day = int.tryParse(cnMatch.group(3)!);
      final hour = int.tryParse(cnMatch.group(4) ?? '0') ?? 0;
      final minute = int.tryParse(cnMatch.group(5) ?? '0') ?? 0;
      final second = int.tryParse(cnMatch.group(6) ?? '0') ?? 0;
      if (yearRaw != null && month != null && day != null) {
        final year = yearRaw < 100 ? (2000 + yearRaw) : yearRaw;
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day, hour, minute, second);
        }
      }
    }
    final excelSerial = double.tryParse(normalized);
    if (excelSerial == null || excelSerial <= 0) {
      return null;
    }
    final base = DateTime(1899, 12, 30);
    final wholeDays = excelSerial.floor();
    final fraction = excelSerial - wholeDays;
    final seconds = (fraction * 24 * 3600).round();
    return base.add(Duration(days: wholeDays, seconds: seconds));
  }

  void _showMessage(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool?> _showImportPreviewPage({
    required String fileName,
    required _ParsedRecords parsed,
  }) async {
    final totalRows = parsed.records.length + parsed.failedRows.length;
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => _DataPreviewPage(
          title: '导入预览',
          subtitle:
              '文件：$fileName  ·  总行数：$totalRows  ·  可导入：${parsed.records.length}  ·  失败：${parsed.failedRows.length}',
          columns: const ['日期', '类型', '分类', '名称', '金额'],
          rows: parsed.records
              .map(
                (record) => _PreviewRow(
                  cells: [
                    _formatDateTime(record.createdAt),
                    record.type == LedgerRecordType.income ? '收入' : '支出',
                    record.category,
                    record.title,
                    record.amount.toStringAsFixed(2),
                  ],
                ),
              )
              .toList(),
          failureRows: parsed.failedRows
              .map(
                (item) => _PreviewFailureRow(
                  sourceLabel: '第 ${item.rowNumber} 行',
                  reason: item.reason,
                ),
              )
              .toList(),
          confirmButtonText: '继续导入',
          cancelButtonText: '取消',
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _ParsedRecords {
  const _ParsedRecords({
    required this.records,
    required this.failedRows,
    this.fatalError,
  });

  final List<LedgerRecord> records;
  final List<_ImportFailure> failedRows;
  final String? fatalError;
}

class _ImportFailure {
  const _ImportFailure({required this.rowNumber, required this.reason});

  final int rowNumber;
  final String reason;
}

class _RowParseResult {
  const _RowParseResult({this.record, this.failure});

  const _RowParseResult.empty() : record = null, failure = null;

  factory _RowParseResult.record(LedgerRecord record) {
    return _RowParseResult(record: record);
  }

  factory _RowParseResult.failure(int rowNumber, String reason) {
    return _RowParseResult(
      failure: _ImportFailure(rowNumber: rowNumber, reason: reason),
    );
  }

  final LedgerRecord? record;
  final _ImportFailure? failure;
}

class _PreviewRow {
  const _PreviewRow({required this.cells});
  final List<String> cells;
}

class _PreviewFailureRow {
  const _PreviewFailureRow({required this.sourceLabel, required this.reason});

  final String sourceLabel;
  final String reason;
}

class _DataPreviewPage extends StatefulWidget {
  const _DataPreviewPage({
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.rows,
    this.failureRows = const [],
    this.confirmButtonText,
    this.cancelButtonText,
  });

  final String title;
  final String subtitle;
  final List<String> columns;
  final List<_PreviewRow> rows;
  final List<_PreviewFailureRow> failureRows;
  final String? confirmButtonText;
  final String? cancelButtonText;

  @override
  State<_DataPreviewPage> createState() => _DataPreviewPageState();
}

class _DataPreviewPageState extends State<_DataPreviewPage> {
  static const _chunkSize = 120;
  final _recordsController = ScrollController();
  final _failuresController = ScrollController();
  int _visibleRecordCount = _chunkSize;
  int _visibleFailureCount = _chunkSize;

  @override
  void initState() {
    super.initState();
    _recordsController.addListener(_onRecordsScroll);
    _failuresController.addListener(_onFailuresScroll);
  }

  @override
  void dispose() {
    _recordsController
      ..removeListener(_onRecordsScroll)
      ..dispose();
    _failuresController
      ..removeListener(_onFailuresScroll)
      ..dispose();
    super.dispose();
  }

  void _onRecordsScroll() {
    if (!_recordsController.hasClients) {
      return;
    }
    if (_recordsController.position.extentAfter < 360 &&
        _visibleRecordCount < widget.rows.length) {
      setState(() {
        _visibleRecordCount = (_visibleRecordCount + _chunkSize).clamp(0, widget.rows.length);
      });
    }
  }

  void _onFailuresScroll() {
    if (!_failuresController.hasClients) {
      return;
    }
    if (_failuresController.position.extentAfter < 360 &&
        _visibleFailureCount < widget.failureRows.length) {
      setState(() {
        _visibleFailureCount =
            (_visibleFailureCount + _chunkSize).clamp(0, widget.failureRows.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFailures = widget.failureRows.isNotEmpty;
    final canConfirm = widget.confirmButtonText != null;
    return DefaultTabController(
      length: hasFailures ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: TabBar(
            tabs: [
              Tab(text: '数据（${widget.rows.length}）'),
              if (hasFailures) Tab(text: '失败（${widget.failureRows.length}）'),
            ],
          ),
        ),
        body: Padding(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.subtitle, style: AppTextStyles.bodyMuted(context)),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  children: [
                    _PreviewTableView(
                      columns: widget.columns,
                      rows: widget.rows.take(_visibleRecordCount).toList(),
                      totalCount: widget.rows.length,
                      visibleCount: _visibleRecordCount,
                      controller: _recordsController,
                    ),
                    if (hasFailures)
                      _FailureListView(
                        rows: widget.failureRows.take(_visibleFailureCount).toList(),
                        totalCount: widget.failureRows.length,
                        visibleCount: _visibleFailureCount,
                        controller: _failuresController,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(widget.cancelButtonText ?? '关闭'),
                    ),
                  ),
                  if (canConfirm) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(widget.confirmButtonText!),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewTableView extends StatelessWidget {
  const _PreviewTableView({
    required this.columns,
    required this.rows,
    required this.totalCount,
    required this.visibleCount,
    required this.controller,
  });

  final List<String> columns;
  final List<_PreviewRow> rows;
  final int totalCount;
  final int visibleCount;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (rows.isEmpty) {
      return Center(child: Text('暂无可展示数据', style: AppTextStyles.bodyMuted(context)));
    }
    return Container(
      decoration: AppDecorations.surface(context),
      child: Column(
        children: [
          Container(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                for (final title in columns)
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyStrong(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: controller,
              itemCount: rows.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: context.colors.divider,
              ),
              itemBuilder: (context, index) {
                final row = rows[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      for (final cell in row.cells)
                        Expanded(
                          child: Text(
                            cell,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMuted(context),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (visibleCount < totalCount)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '已加载 $visibleCount / $totalCount 条，继续下滑自动加载',
                style: AppTextStyles.bodyMuted(context),
              ),
            ),
        ],
      ),
    );
  }
}

class _FailureListView extends StatelessWidget {
  const _FailureListView({
    required this.rows,
    required this.totalCount,
    required this.visibleCount,
    required this.controller,
  });

  final List<_PreviewFailureRow> rows;
  final int totalCount;
  final int visibleCount;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(child: Text('无失败数据', style: AppTextStyles.bodyMuted(context)));
    }
    return Container(
      decoration: AppDecorations.surface(context),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: controller,
              itemCount: rows.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: context.colors.divider,
              ),
              itemBuilder: (context, index) {
                final row = rows[index];
                return ListTile(
                  dense: true,
                  title: Text(row.sourceLabel, style: AppTextStyles.bodyStrong(context)),
                  subtitle: Text(row.reason, style: AppTextStyles.bodyMuted(context)),
                );
              },
            ),
          ),
          if (visibleCount < totalCount)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '已加载 $visibleCount / $totalCount 条，继续下滑自动加载',
                style: AppTextStyles.bodyMuted(context),
              ),
            ),
        ],
      ),
    );
  }
}
