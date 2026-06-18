import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/ledger_store.dart';
import '../../../components/charts/liquid_category_disk.dart';
import '../../../models/ledger_record.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/ledger_formatters.dart';
import 'charts_common_widgets.dart';

class CategoryBreakdownPanel extends StatelessWidget {
  const CategoryBreakdownPanel({super.key, required this.categories});

  static const _itemGap = 12.0;
  static const _minDiskSize = 48.0;
  static const _maxDiskSize = 76.0;
  static const _diskPadding = 8.0;

  final List<CategoryTotal> categories;

  static _CategoryGridLayout? _layoutFor(double width, int totalItems) {
    if (totalItems == 0 || width <= 0) {
      return null;
    }

    final minCellWidth = _minDiskSize + _diskPadding;
    final maxColumns = math.min(
      totalItems,
      ((width + _itemGap) / (minCellWidth + _itemGap)).floor(),
    );

    if (maxColumns < 2) {
      return null;
    }

    final columns = maxColumns >= totalItems ? totalItems : maxColumns;
    final cellWidth = (width - (columns - 1) * _itemGap) / columns;
    final diskSize = (cellWidth - _diskPadding).clamp(_minDiskSize, _maxDiskSize);

    return _CategoryGridLayout(
      itemsPerRow: columns,
      diskSize: diskSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const ChartsEmptyPanel(
        icon: Icons.pie_chart_outline,
        title: '暂无分类数据',
        subtitle: '添加支出记录后会显示分类占比',
      );
    }

    final colors = context.colors;
    final diskColors = [
      colors.primary,
      colors.danger,
      colors.info,
      colors.positiveText,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: AppDecorations.surface(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _layoutFor(constraints.maxWidth, categories.length);
          if (layout == null) {
            return const SizedBox.shrink();
          }

          final rows = <Widget>[];
          for (var start = 0;
              start < categories.length;
              start += layout.itemsPerRow) {
            final end = math.min(start + layout.itemsPerRow, categories.length);
            rows.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = start; index < end; index++) ...[
                    if (index > start) const SizedBox(width: _itemGap),
                    Expanded(
                      child: _CategoryDisk(
                        category: categories[index],
                        color: diskColors[index % diskColors.length],
                        diskSize: layout.diskSize,
                      ),
                    ),
                  ],
                ],
              ),
            );
            if (end < categories.length) {
              rows.add(const SizedBox(height: 16));
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          );
        },
      ),
    );
  }
}

class _CategoryGridLayout {
  const _CategoryGridLayout({
    required this.itemsPerRow,
    required this.diskSize,
  });

  final int itemsPerRow;
  final double diskSize;
}

class _CategoryDisk extends StatelessWidget {
  const _CategoryDisk({
    required this.category,
    required this.color,
    required this.diskSize,
  });

  final CategoryTotal category;
  final Color color;
  final double diskSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LiquidCategoryDisk(
          amountLabel: formatCurrency(category.amount),
          progress: category.percent,
          color: color,
          size: diskSize,
        ),
        const SizedBox(height: 8),
        Text(
          ledgerStore.categoryLabelFor(
            category.category,
            LedgerRecordType.expense,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted(context),
        ),
      ],
    );
  }
}
