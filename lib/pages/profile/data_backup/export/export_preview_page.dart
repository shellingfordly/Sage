import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_styles.dart';
import '../../../../theme/app_text_styles.dart';

class ExportPreviewRow {
  const ExportPreviewRow({required this.cells});
  final List<String> cells;
}

class ExportPreviewFailureRow {
  const ExportPreviewFailureRow({required this.sourceLabel, required this.reason});

  final String sourceLabel;
  final String reason;
}

class ExportPreviewPage extends StatefulWidget {
  const ExportPreviewPage({
    super.key,
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
  final List<ExportPreviewRow> rows;
  final List<ExportPreviewFailureRow> failureRows;
  final String? confirmButtonText;
  final String? cancelButtonText;

  @override
  State<ExportPreviewPage> createState() => _ExportPreviewPageState();
}

class _ExportPreviewPageState extends State<ExportPreviewPage> {
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
        _visibleRecordCount = (_visibleRecordCount + _chunkSize).clamp(
          0,
          widget.rows.length,
        );
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
        _visibleFailureCount = (_visibleFailureCount + _chunkSize).clamp(
          0,
          widget.failureRows.length,
        );
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
  final List<ExportPreviewRow> rows;
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

  final List<ExportPreviewFailureRow> rows;
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
