import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class MonthNavRow extends StatelessWidget {
  const MonthNavRow({
    super.key,
    required this.title,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    this.titleStyle,
  });

  final String title;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final TextStyle Function(BuildContext context)? titleStyle;

  @override
  Widget build(BuildContext context) {
    final style = titleStyle ?? AppTextStyles.pageTitle;

    return Row(
      children: [
        _MonthNavButton(
          icon: Icons.chevron_left,
          tooltip: '上个月',
          onPressed: canGoPrevious ? onPrevious : null,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: style(context),
          ),
        ),
        _MonthNavButton(
          icon: Icons.chevron_right,
          tooltip: '下个月',
          onPressed: canGoNext ? onNext : null,
        ),
      ],
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        color: onPressed == null
            ? colors.textSecondary.withValues(alpha: 0.4)
            : colors.textPrimary,
      ),
    );
  }
}
