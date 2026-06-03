import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../components/charts/liquid_category_disk.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_text_styles.dart';
import '../statistics_period.dart';
import 'charts_common_widgets.dart';

class ExpenseTrendPanel extends StatefulWidget {
  const ExpenseTrendPanel({
    super.key,
    required this.buckets,
  });

  final List<TrendBucket> buckets;

  @override
  State<ExpenseTrendPanel> createState() => _ExpenseTrendPanelState();
}

class _ExpenseTrendPanelState extends State<ExpenseTrendPanel> {
  final ScrollController _scrollController = ScrollController();
  String? _lastAutoScrollToken;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buckets = widget.buckets;
    final maxAmount = buckets.fold<double>(
      0,
      (max, bucket) => math.max(max, bucket.amount),
    );
    final barColor = context.colors.primary;

    if (buckets.isEmpty || maxAmount == 0) {
      return const ChartsEmptyPanel(
        icon: Icons.bar_chart_outlined,
        title: '暂无趋势数据',
        subtitle: '添加支出记录后会显示趋势',
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: AppDecorations.surface(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final neededWidth =
              buckets.length * trendBarItemWidth +
              math.max(0, buckets.length - 1) * trendBarMinSpacing;
          final contentWidth = math.max(neededWidth, constraints.maxWidth);
          final spacing = buckets.length <= 1
              ? 0.0
              : (contentWidth - buckets.length * trendBarItemWidth) /
                    (buckets.length - 1);
          final canScroll = neededWidth > constraints.maxWidth;
          final firstDataIndex = buckets.indexWhere(
            (bucket) => bucket.amount > 0,
          );
          final targetIndex = firstDataIndex == -1 ? 0 : firstDataIndex;
          _scheduleAutoScroll(
            canScroll: canScroll,
            targetIndex: targetIndex,
            itemExtent: trendBarItemWidth + spacing,
            token: '${buckets.length}-$targetIndex-${canScroll ? 1 : 0}',
          );

          return ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: canScroll
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: contentWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var index = 0; index < buckets.length; index++) ...[
                      SizedBox(
                        width: trendBarItemWidth,
                        child: _TrendBar(
                          label: buckets[index].label,
                          amount: buckets[index].amount,
                          maxAmount: maxAmount,
                          color: barColor,
                        ),
                      ),
                      if (index != buckets.length - 1) SizedBox(width: spacing),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _scheduleAutoScroll({
    required bool canScroll,
    required int targetIndex,
    required double itemExtent,
    required String token,
  }) {
    if (_lastAutoScrollToken == token) {
      return;
    }
    _lastAutoScrollToken = token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final targetOffset = canScroll ? itemExtent * targetIndex : 0.0;
      final maxOffset = _scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxOffset);
      _scrollController.jumpTo(clampedOffset);
    });
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.label,
    required this.amount,
    required this.maxAmount,
    required this.color,
  });

  final String label;
  final double amount;
  final double maxAmount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final active = amount == maxAmount && amount > 0;
    final height = 18 + (amount / maxAmount * 104);
    final baseColor = active ? color : color.withValues(alpha: 0.42);
    final trackColor = Color.alphaBlend(
      color.withValues(alpha: active ? 0.16 : 0.10),
      context.colors.surface,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 16,
          height: height,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 16,
                height: height,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: AppRadii.card,
                ),
              ),
              if (amount > 0)
                Container(
                  width: 16,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.card,
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        liquidCategoryShade(baseColor, -0.08),
                        baseColor,
                        liquidCategoryShade(baseColor, 0.14),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: baseColor.withValues(alpha: 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: AppRadii.card,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        liquidCategoryShade(baseColor, 0.2).withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMuted(context).copyWith(
            color: active ? context.colors.primary : null,
            fontWeight: active ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}
