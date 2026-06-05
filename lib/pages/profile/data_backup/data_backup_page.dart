import 'package:flutter/material.dart';

import '../../../components/pickers/record_date_picker.dart';
import 'package:ledger_app/components/time_range/export_range.dart';
import 'package:ledger_app/components/time_range/time_range_panel.dart';
import '../../../data/ledger_store.dart';
import '../../../models/ledger_record.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/record_import_parser.dart';
import 'export/export_preview_page.dart';
import 'export/export_service.dart';
import 'import/import_alipay.dart';
import 'import/import_excel.dart';
import 'import/import_pdf.dart';
import 'import/import_wechat.dart';

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  static const _exportService = ExportService();
  static const _excelImportService = ImportExcelService();
  static const _pdfImportService = ImportPdfService();
  static const _alipayImportService = ImportAlipayService();
  static const _wechatImportService = ImportWechatService();

  ExportRange _range = ExportRange.month;
  DateTimeRange? _customRange;
  bool _busy = false;

  List<LedgerRecord> get _filteredRecords => filterRecordsByExportRange(
    allRecords: ledgerStore.records,
    range: _range,
    customRange: _customRange,
  );

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;
    return Scaffold(
      appBar: AppBar(title: const Text('数据备份')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ExportSection(
                range: _range,
                customRange: _customRange,
                recordCount: records.length,
                rangeText: currentExportRangeText(
                  range: _range,
                  customRange: _customRange,
                ),
                busy: _busy,
                onRangeChanged: (next) {
                  setState(() {
                    _range = next;
                    if (next == ExportRange.custom && _customRange == null) {
                      final now = DateTime.now();
                      _customRange = DateTimeRange(
                        start: DateTime(now.year, now.month, 1),
                        end: DateTime(now.year, now.month, now.day),
                      );
                    }
                  });
                },
                onPickCustomRange: _pickCustomRange,
                onClearCustomRange: () => setState(() => _customRange = null),
                onPreview: _previewExportData,
                onExport: _exportExcel,
              ),
              const SizedBox(height: 14),
              _ImportSection(
                busy: _busy,
                onImportExcel: _importRecords,
                onImportPdf: _importBankPdfBill,
                onImportAlipay: _importAlipayBill,
                onImportWechat: _importWechatBill,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialRange = _customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );
    final picked = await pickCustomDateRange(
      context,
      initialStart: initialRange.start,
      initialEnd: initialRange.end,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: '选择导出时间范围',
    );
    if (picked == null) {
      return;
    }
    setState(() => _customRange = picked);
  }

  Future<void> _previewExportData() async {
    final records = _filteredRecords;
    if (records.isEmpty) {
      _showMessage('当前范围没有可预览的数据');
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ExportPreviewPage(
          title: '导出数据预览',
          subtitle: '${exportRangeLabel(_range)}  ·  共 ${records.length} 条',
          columns: exportPreviewColumns,
          rows: records
              .map((record) => ExportPreviewRow(cells: recordToPreviewCells(record)))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _exportExcel() async {
    setState(() => _busy = true);
    try {
      final result = await _exportService.exportRecordsToExcel(
        records: _filteredRecords,
        range: _range,
        customRange: _customRange,
      );
      switch (result) {
        case ExportSuccess(:final message):
          _showMessage(message);
        case ExportFailure(:final message):
          _showMessage(message);
        case ExportCancelled():
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _importRecords() async {
    setState(() => _busy = true);
    try {
      final result = await _excelImportService.importFromFilePicker(context);
      _handleExcelImportResult(result);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _importBankPdfBill() async {
    setState(() => _busy = true);
    try {
      final result = await _pdfImportService.importFromFilePicker(context);
      _handlePdfImportResult(result);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _importAlipayBill() async {
    setState(() => _busy = true);
    try {
      final result = await _alipayImportService.importFromFilePicker(context);
      _handleAlipayImportResult(result);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _importWechatBill() async {
    setState(() => _busy = true);
    try {
      final result = await _wechatImportService.importFromFilePicker(context);
      _handleWechatImportResult(result);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _handleExcelImportResult(ImportExcelResult result) {
    switch (result) {
      case ImportExcelSuccess(:final message):
        _showMessage(message);
      case ImportExcelFailure(:final message):
        _showMessage(message);
      case ImportExcelCancelled(:final message):
        if (message != null) {
          _showMessage(message);
        }
    }
  }

  void _handlePdfImportResult(ImportPdfResult result) {
    switch (result) {
      case ImportPdfSuccess(:final message):
        _showMessage(message);
      case ImportPdfFailure(:final message):
        _showMessage(message);
      case ImportPdfCancelled(:final message):
        if (message != null) {
          _showMessage(message);
        }
    }
  }

  void _handleAlipayImportResult(ImportAlipayResult result) {
    switch (result) {
      case ImportAlipaySuccess(:final message):
        _showMessage(message);
      case ImportAlipayFailure(:final message):
        _showMessage(message);
      case ImportAlipayCancelled(:final message):
        if (message != null) {
          _showMessage(message);
        }
    }
  }

  void _handleWechatImportResult(ImportWechatResult result) {
    switch (result) {
      case ImportWechatSuccess(:final message):
        _showMessage(message);
      case ImportWechatFailure(:final message):
        _showMessage(message);
      case ImportWechatCancelled(:final message):
        if (message != null) {
          _showMessage(message);
        }
    }
  }

  void _showMessage(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ExportSection extends StatelessWidget {
  const _ExportSection({
    required this.range,
    required this.customRange,
    required this.recordCount,
    required this.rangeText,
    required this.busy,
    required this.onRangeChanged,
    required this.onPickCustomRange,
    required this.onClearCustomRange,
    required this.onPreview,
    required this.onExport,
  });

  final ExportRange range;
  final DateTimeRange? customRange;
  final int recordCount;
  final String rangeText;
  final bool busy;
  final ValueChanged<ExportRange> onRangeChanged;
  final VoidCallback onPickCustomRange;
  final VoidCallback onClearCustomRange;
  final VoidCallback onPreview;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('导出', style: AppTextStyles.sectionTitle(context)),
          const SizedBox(height: 10),
          TimeRangePanel(
            selectedRange: range,
            periodRangeText: rangeText,
            customRange: customRange,
            enabled: !busy,
            decorated: false,
            onRangeChanged: onRangeChanged,
            onPickCustomRange: onPickCustomRange,
            onClearCustomRange: onClearCustomRange,
          ),
          const SizedBox(height: 12),
          Text('预计导出 $recordCount 条记录', style: AppTextStyles.bodyMuted(context)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onPreview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('预览导出数据'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : onExport,
                  icon: const Icon(Icons.file_download_outlined),
                  label: Text(busy ? '处理中...' : '导出 Excel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImportSection extends StatelessWidget {
  const _ImportSection({
    required this.busy,
    required this.onImportExcel,
    required this.onImportPdf,
    required this.onImportAlipay,
    required this.onImportWechat,
  });

  final bool busy;
  final VoidCallback onImportExcel;
  final VoidCallback onImportPdf;
  final VoidCallback onImportAlipay;
  final VoidCallback onImportWechat;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              onPressed: busy ? null : onImportExcel,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('导入 Excel / CSV'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onImportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('导入 PDF 账单'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onImportAlipay,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('导入支付宝账单'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onImportWechat,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('导入微信账单'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Excel / CSV 按固定列导入。PDF 支持标准五列表格流水。支付宝请导出 CSV，微信请导出 xlsx，自动跳过退款与已退款交易，解析后可审核。',
            style: AppTextStyles.bodyMuted(context),
          ),
        ],
      ),
    );
  }
}
