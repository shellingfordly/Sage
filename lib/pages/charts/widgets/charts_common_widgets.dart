import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_text_styles.dart';

class ChartsHeader extends StatelessWidget {
  const ChartsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('图表', style: AppTextStyles.pageTitle(context)),
        const SizedBox(height: 4),
        Text('按月可选年份与月份，按年查看全年', style: AppTextStyles.pageSubtitle(context)),
      ],
    );
  }
}

class ChartsSectionTitle extends StatelessWidget {
  const ChartsSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.sectionTitle(context));
  }
}

class ChartsEmptyPanel extends StatelessWidget {
  const ChartsEmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.surface(context),
      child: Column(
        children: [
          Icon(icon, color: colors.primary, size: 30),
          const SizedBox(height: 10),
          Text(title, style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.bodyMuted(context)),
        ],
      ),
    );
  }
}
