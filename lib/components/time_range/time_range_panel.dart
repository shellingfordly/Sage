import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_font_scale.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/theme_controller.dart';
import '../../utils/record_import_parser.dart';
import 'package:ledger_app/components/time_range/export_range.dart';

class TimeRangePanel extends StatelessWidget {
  const TimeRangePanel({
    super.key,
    required this.selectedRange,
    required this.periodRangeText,
    required this.onRangeChanged,
    this.customRange,
    this.onPickCustomRange,
    this.onClearCustomRange,
    this.enabled = true,
    this.presets = defaultExportRangePresets,
    this.customRangeHelpText = '选择时间范围',
  });

  final ExportRange selectedRange;
  final String periodRangeText;
  final ValueChanged<ExportRange> onRangeChanged;
  final DateTimeRange? customRange;
  final VoidCallback? onPickCustomRange;
  final VoidCallback? onClearCustomRange;
  final bool enabled;
  final List<ExportRange> presets;
  final String customRangeHelpText;

  @override
  Widget build(BuildContext context) {
    final scale = themeController.fontScale;
    final panelPadding = EdgeInsets.fromLTRB(
      AppTypography.scaled(scale, 12),
      AppTypography.scaled(scale, 10),
      AppTypography.scaled(scale, 12),
      AppTypography.scaled(scale, 8),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: panelPadding,
          child: _TimeRangePresetStrip(
            presets: presets,
            selectedRange: selectedRange,
            enabled: enabled,
            onRangeChanged: onRangeChanged,
          ),
        ),
        if (selectedRange == ExportRange.custom &&
            onPickCustomRange != null) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppTypography.scaled(scale, 12),
              0,
              AppTypography.scaled(scale, 12),
              AppTypography.scaled(scale, 10),
            ),
            child: _TimeRangeCustomPicker(
              customRange: customRange,
              enabled: enabled,
              onPick: onPickCustomRange!,
              onClear: onClearCustomRange,
            ),
          ),
        ] else
          SizedBox(height: AppTypography.scaled(scale, 2)),
        _TimeRangeFooter(periodRangeText: periodRangeText),
      ],
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.surface(context),
      child: content,
    );
  }
}

class _TimeRangePresetStrip extends StatefulWidget {
  const _TimeRangePresetStrip({
    required this.presets,
    required this.selectedRange,
    required this.enabled,
    required this.onRangeChanged,
  });

  final List<ExportRange> presets;
  final ExportRange selectedRange;
  final bool enabled;
  final ValueChanged<ExportRange> onRangeChanged;

  @override
  State<_TimeRangePresetStrip> createState() => _TimeRangePresetStripState();
}

class _TimeRangePresetStripState extends State<_TimeRangePresetStrip> {
  final ScrollController _scrollController = ScrollController();

  double get _itemStride =>
      AppTypography.presetItemStride(themeController.fontScale);

  int get _selectedIndex {
    final index = widget.presets.indexOf(widget.selectedRange);
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant _TimeRangePresetStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRange != widget.selectedRange) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients || widget.presets.isEmpty) {
      return;
    }
    final index = _selectedIndex.clamp(0, widget.presets.length - 1);
    final offset = (index * _itemStride - _itemStride).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = themeController.fontScale;
    final chipHeight = AppTypography.compactControlHeight(scale);

    return SizedBox(
      height: chipHeight,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(right: AppTypography.scaled(scale, 4)),
          itemCount: widget.presets.length,
          separatorBuilder: (context, index) =>
              SizedBox(width: AppTypography.compactGap(scale)),
          itemBuilder: (context, index) {
            final preset = widget.presets[index];
            return _TimeRangePresetChip(
              label: exportRangeLabel(preset),
              selected: widget.selectedRange == preset,
              enabled: widget.enabled,
              onTap: () => widget.onRangeChanged(preset),
            );
          },
        ),
      ),
    );
  }
}

class _TimeRangePresetChip extends StatelessWidget {
  const _TimeRangePresetChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scale = themeController.fontScale;
    final chipHeight = AppTypography.compactControlHeight(scale);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: chipHeight,
          padding: EdgeInsets.symmetric(
            horizontal: AppTypography.scaled(scale, 12),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.softFill,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : colors.surfaceBorder.withValues(alpha: 0.85),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: AppTextStyles.chip(context, selected: selected).copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeRangeCustomPicker extends StatelessWidget {
  const _TimeRangeCustomPicker({
    required this.customRange,
    required this.enabled,
    required this.onPick,
    this.onClear,
  });

  final DateTimeRange? customRange;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scale = themeController.fontScale;
    final iconSize = AppTypography.compactIconSize(scale);
    final actionIconSize = AppTypography.compactIconSizeLarge(scale);
    final actionSize = AppTypography.scaled(scale, 28);
    final rangeLabel = customRange == null
        ? '选择时间范围'
        : formatDateRangeLabelCompact(customRange!.start, customRange!.end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('自定义时间范围', style: AppTextStyles.bodyMuted(context)),
        SizedBox(height: AppTypography.compactGap(scale)),
        Material(
          color: colors.surface,
          borderRadius: AppRadii.card,
          child: InkWell(
            onTap: enabled ? onPick : null,
            borderRadius: AppRadii.card,
            child: Container(
              padding: AppTypography.compactControlPadding(scale),
              decoration: BoxDecoration(
                borderRadius: AppRadii.card,
                border: Border.all(color: colors.surfaceBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range_outlined,
                    size: iconSize,
                    color: colors.primary.withValues(alpha: 0.9),
                  ),
                  SizedBox(width: AppTypography.compactGap(scale)),
                  Expanded(
                    child: Text(
                      rangeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.pageSubtitle(context).copyWith(
                        color: customRange == null
                            ? colors.textSecondary
                            : colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (customRange != null && onClear != null) ...[
                    IconButton(
                      onPressed: enabled ? onClear : null,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: actionSize,
                        minHeight: actionSize,
                      ),
                      tooltip: '清除',
                      icon: Icon(
                        Icons.close,
                        size: iconSize,
                        color: colors.textSecondary,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.expand_more,
                      size: actionIconSize,
                      color: colors.chevron,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeRangeFooter extends StatelessWidget {
  const _TimeRangeFooter({required this.periodRangeText});

  final String periodRangeText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scale = themeController.fontScale;
    final iconSize = AppTypography.scaled(scale, 13);

    return Container(
      padding: AppTypography.compactFooterPadding(scale),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.primary.withValues(alpha: 0.08),
          colors.surface,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: AppRadii.card.bottomLeft,
        ),
        border: Border(
          top: BorderSide(
            color: colors.surfaceBorder.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: iconSize,
            color: colors.primary.withValues(alpha: 0.9),
          ),
          SizedBox(width: AppTypography.compactGap(scale)),
          Expanded(
            child: Text(
              periodRangeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMuted(context).copyWith(
                color: colors.textBody,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
