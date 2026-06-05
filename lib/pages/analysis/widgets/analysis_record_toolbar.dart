import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_text_styles.dart';
import '../analysis_query.dart';
import 'analysis_sort_bar.dart';

class AnalysisRecordToolbar extends StatefulWidget {
  const AnalysisRecordToolbar({
    super.key,
    required this.searchController,
    required this.count,
    required this.sort,
    required this.onSortChanged,
    required this.onSearchChanged,
    required this.onOpenAiInsight,
    this.decorated = true,
  });

  final TextEditingController searchController;
  final int count;
  final AnalysisSortOption sort;
  final ValueChanged<AnalysisSortOption> onSortChanged;
  final VoidCallback onSearchChanged;
  final VoidCallback onOpenAiInsight;
  final bool decorated;

  @override
  State<AnalysisRecordToolbar> createState() => _AnalysisRecordToolbarState();
}

class _AnalysisRecordToolbarState extends State<AnalysisRecordToolbar> {
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchExpanded = widget.searchController.text.isNotEmpty;
  }

  void _toggleSearch() {
    setState(() => _searchExpanded = !_searchExpanded);
  }

  void _clearSearch() {
    widget.searchController.clear();
    widget.onSearchChanged();
    if (_searchExpanded) {
      setState(() => _searchExpanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasQuery = widget.searchController.text.isNotEmpty;

    final recordRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Text(
            '${widget.count} 条记录',
            style: AppTextStyles.bodyMuted(context).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SearchIconButton(
                active: _searchExpanded || hasQuery,
                onTap: _toggleSearch,
              ),
              const ToolbarIconDivider(),
              _AiIconButton(onTap: widget.onOpenAiInsight),
              const ToolbarIconDivider(),
              AnalysisSortControls(
                sort: widget.sort,
                onSortChanged: widget.onSortChanged,
              ),
            ],
          ),
        ],
      ),
    );

    final searchField = AnimatedCrossFade(
      duration: const Duration(milliseconds: 180),
      crossFadeState: _searchExpanded
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      sizeCurve: Curves.easeOut,
      firstChild: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: TextField(
          controller: widget.searchController,
          autofocus: true,
          onChanged: (_) => widget.onSearchChanged(),
          style: AppTextStyles.bodyStrong(context)
              .copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: '搜索标题、分类、备注或金额',
            hintStyle: AppTextStyles.bodyMuted(context),
            isDense: true,
            prefixIcon:
                Icon(Icons.search, size: 18, color: colors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(Icons.close, size: 16, color: colors.textSecondary),
              onPressed: _clearSearch,
              visualDensity: VisualDensity.compact,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: colors.softFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.surfaceBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.surfaceBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: colors.primary.withValues(alpha: 0.65)),
            ),
          ),
        ),
      ),
      secondChild: const SizedBox.shrink(),
    );

    if (!widget.decorated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          recordRow,
          searchField,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.zero,
          decoration: AppDecorations.surface(context),
          child: recordRow,
        ),
        searchField,
      ],
    );
  }
}

class _SearchIconButton extends StatelessWidget {
  const _SearchIconButton({
    required this.active,
    required this.onTap,
  });

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.search,
            size: 18,
            color: active ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AiIconButton extends StatelessWidget {
  const _AiIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: '分析',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.insights_outlined,
              size: 18,
              color: colors.primary.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}
