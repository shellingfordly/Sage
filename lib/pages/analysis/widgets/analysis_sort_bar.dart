import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../analysis_query.dart';

const _iconSlotSize = 20.0;
const _iconSize = 18.0;

class AnalysisSortControls extends StatelessWidget {
  const AnalysisSortControls({
    super.key,
    required this.sort,
    required this.onSortChanged,
  });

  final AnalysisSortOption sort;
  final ValueChanged<AnalysisSortOption> onSortChanged;

  void _onTimeTap() {
    if (sort.isTimeSort) {
      onSortChanged(sort.toggleDirection());
      return;
    }
    onSortChanged(AnalysisSortOption.timeDesc);
  }

  void _onAmountTap() {
    if (sort.isAmountSort) {
      onSortChanged(sort.toggleDirection());
      return;
    }
    onSortChanged(AnalysisSortOption.amountDesc);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SortIconButton(
          tooltip: sort.isTimeSort
              ? (sort.isAscending ? '时间升序' : '时间降序')
              : '按时间排序',
          active: sort.isTimeSort,
          ascending: sort.isTimeSort && sort.isAscending,
          dimension: _SortDimension.time,
          onTap: _onTimeTap,
        ),
        const ToolbarIconDivider(),
        _SortIconButton(
          tooltip: sort.isAmountSort
              ? (sort.isAscending ? '金额升序' : '金额降序')
              : '按金额排序',
          active: sort.isAmountSort,
          ascending: sort.isAmountSort && sort.isAscending,
          dimension: _SortDimension.amount,
          onTap: _onAmountTap,
        ),
      ],
    );
  }
}

class ToolbarIconDivider extends StatelessWidget {
  const ToolbarIconDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '|',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: context.colors.textSecondary.withValues(alpha: 0.45),
          height: 1.1,
        ),
      ),
    );
  }
}

enum _SortDimension { time, amount }

class _SortIconButton extends StatelessWidget {
  const _SortIconButton({
    required this.tooltip,
    required this.dimension,
    required this.active,
    required this.ascending,
    required this.onTap,
  });

  final String tooltip;
  final _SortDimension dimension;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = active
        ? colors.primary
        : colors.textSecondary.withValues(alpha: 0.55);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: _SortDimensionIcon(
            dimension: dimension,
            active: active,
            ascending: ascending,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// 时钟/钞票 + 方向箭头的组合排序图标，固定占位避免切换时跳动。
class _SortDimensionIcon extends StatelessWidget {
  const _SortDimensionIcon({
    required this.dimension,
    required this.active,
    required this.ascending,
    required this.color,
  });

  final _SortDimension dimension;
  final bool active;
  final bool ascending;
  final Color color;

  Widget _buildMainIcon() {
    if (dimension == _SortDimension.time) {
      return Icon(Icons.schedule_outlined, size: _iconSize, color: color);
    }
    return _BanknoteIcon(color: color, size: _iconSize);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _iconSlotSize,
      height: _iconSlotSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _buildMainIcon(),
          if (active)
            Positioned(
              right: -1,
              bottom: -1,
              child: Icon(
                ascending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: _iconSize * 0.48,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

/// 钞票轮廓 + ¥，用于金额排序。
class _BanknoteIcon extends StatelessWidget {
  const _BanknoteIcon({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BanknoteIconPainter(color: color),
        child: Center(
          child: Text(
            '¥',
            style: TextStyle(
              fontSize: size * 0.40,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _BanknoteIconPainter extends CustomPainter {
  const _BanknoteIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bar = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 1.15
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    final note = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.24, w * 0.88, h * 0.52),
      Radius.circular(w * 0.10),
    );
    canvas.drawRRect(note, outline);

    canvas.drawLine(Offset(w * 0.22, h * 0.36), Offset(w * 0.22, h * 0.64), bar);
    canvas.drawLine(Offset(w * 0.78, h * 0.36), Offset(w * 0.78, h * 0.64), bar);
  }

  @override
  bool shouldRepaint(covariant _BanknoteIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
