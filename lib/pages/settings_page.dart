import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SectionTitle(title: '外观'),
              SizedBox(height: 12),
              _ThemePanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePanel extends StatelessWidget {
  const _ThemePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.surface(context),
      child: ValueListenableBuilder<AppThemeOption>(
        valueListenable: themeController,
        builder: (context, selectedTheme, child) {
          return Column(
            children: [
              _ThemeCurrentTile(selectedTheme: selectedTheme),
              const _PanelDivider(),
              _ThemeSelectorGrid(selectedTheme: selectedTheme),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeCurrentTile extends StatelessWidget {
  const _ThemeCurrentTile({required this.selectedTheme});

  final AppThemeOption selectedTheme;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: AppDecorations.softFill(context),
            child: Icon(
              Icons.palette_outlined,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '主题色系',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong(context),
                ),
                const SizedBox(height: 3),
                Text(
                  '当前：${selectedTheme.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMuted(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelectorGrid extends StatelessWidget {
  const _ThemeSelectorGrid({required this.selectedTheme});

  final AppThemeOption selectedTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final option in themeController.availableThemes)
            _ThemeOptionTile(
              option: option,
              selected: option.id == selectedTheme.id,
              onTap: () => themeController.setTheme(option),
            ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.primarySoft : colors.softFill,
          borderRadius: AppRadii.card,
          border: Border.all(
            color: selected ? colors.primary : colors.surfaceBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: option.previewColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: option.brightness == Brightness.light
                      ? colors.surfaceBorder
                      : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textBody,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, color: colors.primary, size: 16),
          ],
        ),
      ),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 66,
      color: context.colors.divider,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.sectionTitle(context));
  }
}
