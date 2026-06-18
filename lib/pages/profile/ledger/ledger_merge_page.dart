import 'package:flutter/material.dart';

import '../../../data/ledger_store.dart';
import '../../../models/ledger_book.dart';
import '../../../models/ledger_record.dart';
import '../../../services/ledger/ledger_merge_analyzer.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/ledger_formatters.dart';
import '../../../components/pickers/date_picker.dart';

enum _MergeRange { month, pickMonth, all, custom }

enum _MergeStep { select, analyze, review, confirm }

enum _ReviewTab { toMerge, filtered, suspected }

class LedgerMergePage extends StatefulWidget {
  const LedgerMergePage({super.key});

  @override
  State<LedgerMergePage> createState() => _LedgerMergePageState();
}

class _LedgerMergePageState extends State<LedgerMergePage> {
  static const _analyzer = LedgerMergeAnalyzer();

  _MergeStep _step = _MergeStep.select;
  _MergeRange _range = _MergeRange.all;
  _ReviewTab _reviewTab = _ReviewTab.toMerge;

  String? _sourceLedgerId;
  String? _targetLedgerId;
  DateTime? _pickedMonth;
  DateTimeRange? _customRange;
  List<AnalyzedMergeRecord>? _analysisItems;
  String _searchQuery = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initLedgerSelection();
  }

  void _initLedgerSelection() {
    final ledgers = ledgerStore.ledgers;
    if (ledgers.length >= 2) {
      _sourceLedgerId = ledgers.first.id;
      _targetLedgerId = ledgers[1].id;
    } else if (ledgers.length == 1) {
      _sourceLedgerId = ledgers.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ledgerStore,
      builder: (context, child) {
        final ledgers = ledgerStore.ledgers;
        if (ledgers.length < 2) {
          return Scaffold(
            appBar: AppBar(title: const Text('合并账本')),
            body: SafeArea(
              child: Padding(
                padding: AppSpacing.page,
                child: Center(
                  child: Text(
                    '至少需要两个账本才能合并，请先新建账本。',
                    style: AppTextStyles.bodyMuted(context),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        _ensureValidLedgerSelection(ledgers);

        return PopScope(
          canPop: _step == _MergeStep.select,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _goBackStep();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(_stepTitle),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _step == _MergeStep.select
                    ? () => Navigator.of(context).pop()
                    : _goBackStep,
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  _StepIndicator(step: _step),
                  Expanded(
                    child: switch (_step) {
                      _MergeStep.select => _buildSelectStep(ledgers),
                      _MergeStep.analyze => _buildAnalyzeStep(ledgers),
                      _MergeStep.review => _buildReviewStep(ledgers),
                      _MergeStep.confirm => _buildConfirmStep(ledgers),
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String get _stepTitle => switch (_step) {
        _MergeStep.select => '合并账本 · 选择范围',
        _MergeStep.analyze => '合并账本 · 分析结果',
        _MergeStep.review => '合并账本 · 确认清单',
        _MergeStep.confirm => '合并账本 · 执行合并',
      };

  void _ensureValidLedgerSelection(List<LedgerBook> ledgers) {
    final ids = ledgers.map((ledger) => ledger.id).toSet();
    if (_sourceLedgerId == null || !ids.contains(_sourceLedgerId)) {
      _sourceLedgerId = ledgers.first.id;
    }
    if (_targetLedgerId == null ||
        !ids.contains(_targetLedgerId) ||
        _targetLedgerId == _sourceLedgerId) {
      _targetLedgerId = ledgers
          .firstWhere(
            (ledger) => ledger.id != _sourceLedgerId,
            orElse: () => ledgers.first,
          )
          .id;
    }
  }

  LedgerBook? _ledgerById(String? id, List<LedgerBook> ledgers) {
    if (id == null) {
      return null;
    }
    for (final ledger in ledgers) {
      if (ledger.id == id) {
        return ledger;
      }
    }
    return null;
  }

  List<LedgerRecord> _sourceRecordsInRange() {
    final sourceId = _sourceLedgerId;
    if (sourceId == null) {
      return const [];
    }
    final all = ledgerStore.recordsForLedger(sourceId);
    final now = DateTime.now();
    return switch (_range) {
      _MergeRange.all => all,
      _MergeRange.month => all
          .where(
            (record) =>
                record.createdAt.year == now.year &&
                record.createdAt.month == now.month,
          )
          .toList(),
      _MergeRange.pickMonth => _filterByMonth(all, _pickedMonth),
      _MergeRange.custom => _filterByCustomRange(all),
    };
  }

  List<LedgerRecord> _filterByMonth(
    List<LedgerRecord> records,
    DateTime? month,
  ) {
    if (month == null) {
      return const [];
    }
    return records
        .where(
          (record) =>
              record.createdAt.year == month.year &&
              record.createdAt.month == month.month,
        )
        .toList();
  }

  List<LedgerRecord> _filterByCustomRange(List<LedgerRecord> records) {
    final range = _customRange;
    if (range == null) {
      return const [];
    }
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );
    return records
        .where(
          (record) =>
              !record.createdAt.isBefore(start) &&
              !record.createdAt.isAfter(end),
        )
        .toList();
  }

  String _rangeLabel() {
    final now = DateTime.now();
    return switch (_range) {
      _MergeRange.all => '全部记录',
      _MergeRange.month => '${now.year}年${now.month}月',
      _MergeRange.pickMonth => _pickedMonth == null
          ? '未选择月份'
          : '${_pickedMonth!.year}年${_pickedMonth!.month}月',
      _MergeRange.custom => _customRange == null
          ? '未选择时间范围'
          : '${_customRange!.start.year}/${_customRange!.start.month.toString().padLeft(2, '0')}/${_customRange!.start.day.toString().padLeft(2, '0')}'
              ' - '
              '${_customRange!.end.year}/${_customRange!.end.month.toString().padLeft(2, '0')}/${_customRange!.end.day.toString().padLeft(2, '0')}',
    };
  }

  bool get _canProceedFromSelect {
    if (_sourceLedgerId == null ||
        _targetLedgerId == null ||
        _sourceLedgerId == _targetLedgerId) {
      return false;
    }
    if (_range == _MergeRange.pickMonth && _pickedMonth == null) {
      return false;
    }
    if (_range == _MergeRange.custom && _customRange == null) {
      return false;
    }
    return _sourceRecordsInRange().isNotEmpty;
  }

  void _runAnalysis() {
    final sourceId = _sourceLedgerId;
    final targetId = _targetLedgerId;
    if (sourceId == null || targetId == null) {
      return;
    }
    final sourceRecords = _sourceRecordsInRange();
    final targetRecords = ledgerStore.recordsForLedger(targetId);
    setState(() {
      _analysisItems = _analyzer.analyze(
        sourceRecords: sourceRecords,
        targetRecords: targetRecords,
      );
      _reviewTab = _ReviewTab.toMerge;
      _searchQuery = '';
      _step = _MergeStep.analyze;
    });
  }

  void _goBackStep() {
    setState(() {
      _step = switch (_step) {
        _MergeStep.select => _MergeStep.select,
        _MergeStep.analyze => _MergeStep.select,
        _MergeStep.review => _MergeStep.analyze,
        _MergeStep.confirm => _MergeStep.review,
      };
    });
  }

  void _goNextStep() {
    setState(() {
      _step = switch (_step) {
        _MergeStep.select => _MergeStep.analyze,
        _MergeStep.analyze => _MergeStep.review,
        _MergeStep.review => _MergeStep.confirm,
        _MergeStep.confirm => _MergeStep.confirm,
      };
    });
  }

  int _countByDisposition(MergeRecordDisposition disposition) {
    final items = _analysisItems;
    if (items == null) {
      return 0;
    }
    return items.where((item) => item.effectiveDisposition == disposition).length;
  }

  int get _willMergeCount => _countByDisposition(MergeRecordDisposition.toMerge);

  List<AnalyzedMergeRecord> _filteredReviewItems() {
    final items = _analysisItems ?? const <AnalyzedMergeRecord>[];
    final tabDisposition = switch (_reviewTab) {
      _ReviewTab.toMerge => MergeRecordDisposition.toMerge,
      _ReviewTab.filtered => MergeRecordDisposition.filtered,
      _ReviewTab.suspected => MergeRecordDisposition.suspected,
    };
    final query = _searchQuery.trim().toLowerCase();
    return items.where((item) {
      if (item.effectiveDisposition != tabDisposition) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final record = item.source;
      return record.title.toLowerCase().contains(query) ||
          record.category.toLowerCase().contains(query) ||
          record.amount.toString().contains(query);
    }).toList();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await pickDate(
      context,
      initialDate: _pickedMonth ?? now,
      lastDate: DateTime.now(),
      helpText: '选择月份',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _pickedMonth = DateTime(picked.year, picked.month);
    });
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
      helpText: '选择合并时间范围',
    );
    if (picked == null) {
      return;
    }
    setState(() => _customRange = picked);
  }

  Future<void> _executeMerge(List<LedgerBook> ledgers) async {
    final targetId = _targetLedgerId;
    final items = _analysisItems;
    if (targetId == null || items == null) {
      return;
    }
    final toMerge = items.where((item) => item.willMerge).map((item) => item.source).toList();
    if (toMerge.isEmpty) {
      _showMessage('没有可合并的记录');
      return;
    }

    setState(() => _busy = true);
    try {
      final added = await ledgerStore.mergeRecordsToLedger(
        targetLedgerId: targetId,
        records: toMerge,
      );
      if (!mounted) {
        return;
      }
      final targetName = _ledgerById(targetId, ledgers)?.name ?? '目标账本';
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已成功合并 $added 笔记录到「$targetName」')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _setDisposition(AnalyzedMergeRecord item, MergeRecordDisposition disposition) {
    setState(() {
      item.userDisposition = disposition;
    });
  }

  Widget _buildSelectStep(List<LedgerBook> ledgers) {
    final sourceCount = _sourceRecordsInRange().length;
    return SingleChildScrollView(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: '源账本（从哪里合并）',
            child: _LedgerDropdown(
              ledgers: ledgers,
              value: _sourceLedgerId,
              excludeId: _targetLedgerId,
              onChanged: (value) => setState(() => _sourceLedgerId = value),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '目标账本（合并到哪里）',
            child: _LedgerDropdown(
              ledgers: ledgers,
              value: _targetLedgerId,
              excludeId: _sourceLedgerId,
              onChanged: (value) => setState(() => _targetLedgerId = value),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '合并范围',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<_MergeRange>(
                  segments: const [
                    ButtonSegment(value: _MergeRange.month, label: Text('本月')),
                    ButtonSegment(value: _MergeRange.pickMonth, label: Text('指定月')),
                    ButtonSegment(value: _MergeRange.all, label: Text('全部')),
                    ButtonSegment(value: _MergeRange.custom, label: Text('自定义')),
                  ],
                  selected: {_range},
                  onSelectionChanged: (values) {
                    setState(() {
                      _range = values.first;
                      if (_range == _MergeRange.custom && _customRange == null) {
                        final now = DateTime.now();
                        _customRange = DateTimeRange(
                          start: DateTime(now.year, now.month, 1),
                          end: DateTime(now.year, now.month, now.day),
                        );
                      }
                    });
                  },
                ),
                if (_range == _MergeRange.pickMonth) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickMonth,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      _pickedMonth == null
                          ? '选择月份'
                          : '${_pickedMonth!.year}年${_pickedMonth!.month}月',
                    ),
                  ),
                ],
                if (_range == _MergeRange.custom) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickCustomRange,
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(_rangeLabel()),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '预计分析 $sourceCount 笔记录',
                  style: AppTextStyles.bodyMuted(context),
                ),
                Text(
                  '当前范围：${_rangeLabel()}',
                  style: AppTextStyles.bodyMuted(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppDecorations.surface(context),
            child: Text(
              '重复检测规则：时间（精确到秒）+ 分类 + 金额 + 类型。源账本记录在合并后保留，是否删除由你自行决定。',
              style: AppTextStyles.bodyMuted(context),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _canProceedFromSelect ? _runAnalysis : null,
            child: const Text('开始分析'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeStep(List<LedgerBook> ledgers) {
    final items = _analysisItems ?? const <AnalyzedMergeRecord>[];
    final source = _ledgerById(_sourceLedgerId, ledgers);
    final target = _ledgerById(_targetLedgerId, ledgers);
    final filteredCount = _countByDisposition(MergeRecordDisposition.filtered);
    final suspectedCount = _countByDisposition(MergeRecordDisposition.suspected);
    final mergeCount = _willMergeCount;

    return SingleChildScrollView(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${source?.name ?? ''} → ${target?.name ?? ''}',
            style: AppTextStyles.sectionTitle(context),
          ),
          Text(
            '${_rangeLabel()} · 共分析 ${items.length} 笔',
            style: AppTextStyles.bodyMuted(context),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '待分析',
                  value: '${items.length}',
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: '已过滤',
                  value: '$filteredCount',
                  color: context.colors.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: '将合并',
                  value: '$mergeCount',
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          if (suspectedCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: AppDecorations.surface(context),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: context.colors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$suspectedCount 笔疑似重复，建议人工确认后再合并。',
                      style: AppTextStyles.bodyStrong(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppDecorations.surface(context),
            child: Text(
              '匹配规则：目标账本中存在「时间（秒级）+ 分类 + 金额 + 类型」完全一致的记录时，自动过滤。同日同分类同金额但时间不同则标记为疑似。',
              style: AppTextStyles.bodyMuted(context),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: items.isEmpty ? null : _goNextStep,
            child: const Text('查看详情并调整'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(List<LedgerBook> ledgers) {
    final items = _filteredReviewItems();
    final mergeCount = _willMergeCount;
    final filteredCount = _countByDisposition(MergeRecordDisposition.filtered);
    final suspectedCount = _countByDisposition(MergeRecordDisposition.suspected);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: SegmentedButton<_ReviewTab>(
            segments: [
              ButtonSegment(
                value: _ReviewTab.toMerge,
                label: Text('将合并 ($mergeCount)'),
              ),
              ButtonSegment(
                value: _ReviewTab.filtered,
                label: Text('已过滤 ($filteredCount)'),
              ),
              ButtonSegment(
                value: _ReviewTab.suspected,
                label: Text('疑似 ($suspectedCount)'),
              ),
            ],
            selected: {_reviewTab},
            onSelectionChanged: (values) {
              setState(() => _reviewTab = values.first);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索名称、分类或金额',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: AppRadii.card),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    '当前列表暂无记录',
                    style: AppTextStyles.bodyMuted(context),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _MergeRecordTile(
                      item: items[index],
                      tab: _reviewTab,
                      onMoveToMerge: () =>
                          _setDisposition(items[index], MergeRecordDisposition.toMerge),
                      onMoveToFiltered: () =>
                          _setDisposition(items[index], MergeRecordDisposition.filtered),
                      onReset: () {
                        setState(items[index].resetOverride);
                      },
                    );
                  },
                ),
        ),
        Padding(
          padding: AppSpacing.page,
          child: FilledButton(
            onPressed: mergeCount == 0 ? null : _goNextStep,
            child: Text('下一步 · 将合并 $mergeCount 笔'),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep(List<LedgerBook> ledgers) {
    final source = _ledgerById(_sourceLedgerId, ledgers);
    final target = _ledgerById(_targetLedgerId, ledgers);
    final mergeCount = _willMergeCount;
    final filteredCount = _countByDisposition(MergeRecordDisposition.filtered);
    final skippedCount = (_analysisItems?.length ?? 0) - mergeCount;

    return SingleChildScrollView(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.surface(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('合并摘要', style: AppTextStyles.sectionTitle(context)),
                const SizedBox(height: 12),
                _SummaryRow(label: '源账本', value: source?.name ?? ''),
                _SummaryRow(label: '目标账本', value: target?.name ?? ''),
                _SummaryRow(label: '时间范围', value: _rangeLabel()),
                const Divider(height: 24),
                _SummaryRow(
                  label: '将合并',
                  value: '$mergeCount 笔',
                  valueColor: context.colors.primary,
                ),
                _SummaryRow(
                  label: '将跳过',
                  value: '$skippedCount 笔（含过滤 $filteredCount 笔）',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppDecorations.surface(context),
            child: Text(
              '源账本「${source?.name ?? ''}」中的记录将保留，合并仅在目标账本中追加副本。',
              style: AppTextStyles.bodyMuted(context),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _goBackStep,
                  child: const Text('返回调整'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _busy || mergeCount == 0
                      ? null
                      : () => _executeMerge(ledgers),
                  child: Text(_busy ? '合并中...' : '确认合并'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final _MergeStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stepIndex = step.index;
    const labels = ['选择', '分析', '调整', '确认'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            if (index > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: index <= stepIndex
                      ? colors.primary
                      : colors.divider,
                ),
              ),
            Column(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: index <= stepIndex
                      ? colors.primary
                      : colors.softFill,
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.caption(context).copyWith(
                      color: index <= stepIndex
                          ? colors.onStrong
                          : colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[index],
                  style: AppTextStyles.caption(context).copyWith(
                    color: index <= stepIndex
                        ? colors.textPrimary
                        : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle(context)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LedgerDropdown extends StatelessWidget {
  const _LedgerDropdown({
    required this.ledgers,
    required this.value,
    required this.onChanged,
    this.excludeId,
  });

  final List<LedgerBook> ledgers;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? excludeId;

  @override
  Widget build(BuildContext context) {
    final options = ledgers.where((ledger) => ledger.id != excludeId).toList();
    final effectiveValue =
        options.any((ledger) => ledger.id == value) ? value : options.firstOrNull?.id;
    return DropdownButtonFormField<String>(
      initialValue: effectiveValue,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final ledger in options)
          DropdownMenuItem(
            value: ledger.id,
            child: Text(
              '${ledger.name} (${ledgerStore.recordsForLedger(ledger.id).length} 笔)',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: AppDecorations.surface(context),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.sectionTitle(context).copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodyMuted(context)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: AppTextStyles.bodyMuted(context)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyStrong(context).copyWith(
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MergeRecordTile extends StatelessWidget {
  const _MergeRecordTile({
    required this.item,
    required this.tab,
    required this.onMoveToMerge,
    required this.onMoveToFiltered,
    required this.onReset,
  });

  final AnalyzedMergeRecord item;
  final _ReviewTab tab;
  final VoidCallback onMoveToMerge;
  final VoidCallback onMoveToFiltered;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final record = item.source;
    final matched = item.matchedTarget;
    final hasOverride = item.userDisposition != null;

    return Container(
      decoration: AppDecorations.surface(context),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatMergeDateTime(record.createdAt)} · ${ledgerStore.categoryLabelForRecord(record)}',
                    style: AppTextStyles.bodyMuted(context),
                  ),
                ],
              ),
            ),
            Text(
              formatRecordAmount(record),
              style: AppTextStyles.bodyStrong(context).copyWith(
                color: record.isIncome ? colors.positiveText : colors.textPrimary,
              ),
            ),
          ],
        ),
        subtitle: hasOverride
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '已手动调整',
                  style: AppTextStyles.bodyMuted(context).copyWith(
                    color: colors.info,
                  ),
                ),
              )
            : null,
        children: [
          if (matched != null && tab != _ReviewTab.toMerge) ...[
            Text('目标账本匹配记录', style: AppTextStyles.bodyStrong(context)),
            const SizedBox(height: 6),
            _MatchedRecordPreview(record: matched),
            const SizedBox(height: 10),
          ],
          if (item.matchedTargets.length > 1) ...[
            Text(
              '共 ${item.matchedTargets.length} 条相似记录',
              style: AppTextStyles.bodyMuted(context),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (tab != _ReviewTab.toMerge)
                OutlinedButton(
                  onPressed: onMoveToMerge,
                  child: const Text('移入合并'),
                ),
              if (tab != _ReviewTab.filtered)
                OutlinedButton(
                  onPressed: onMoveToFiltered,
                  child: const Text('移入过滤'),
                ),
              if (hasOverride)
                TextButton(onPressed: onReset, child: const Text('恢复自动判定')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchedRecordPreview extends StatelessWidget {
  const _MatchedRecordPreview({required this.record});

  final LedgerRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colors.softFill,
        borderRadius: AppRadii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(record.title, style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 4),
          Text(
            '${formatMergeDateTime(record.createdAt)} · ${ledgerStore.categoryLabelForRecord(record)} · ${formatRecordAmount(record)}',
            style: AppTextStyles.bodyMuted(context),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
