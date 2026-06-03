import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_font_scale.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/theme_controller.dart';

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
              _DarkModePanel(),
              SizedBox(height: 20),
              _SectionTitle(title: '外观'),
              SizedBox(height: 12),
              _FontScalePanel(),
              SizedBox(height: 20),
              _ThemePanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkModePanel extends StatelessWidget {
  const _DarkModePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.surface(context),
      child: ValueListenableBuilder<AppThemeOption>(
        valueListenable: themeController,
        builder: (context, _, child) {
          final colors = context.colors;
          final mode = themeController.modePreference;
          final isDarkMode = themeController.isDarkMode;

          return Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: AppDecorations.softFill(context),
                  child: Icon(
                    mode == ThemeModePreference.system
                        ? Icons.brightness_auto_outlined
                        : isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
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
                        '外观模式',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong(context),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        mode == ThemeModePreference.system
                            ? '跟随系统 · ${isDarkMode ? '深色' : '浅色'}'
                            : mode.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMuted(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ModeIconSelector(
                  selected: mode,
                  onSelected: themeController.setModePreference,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ModeIconSelector extends StatelessWidget {
  const _ModeIconSelector({
    required this.selected,
    required this.onSelected,
  });

  final ThemeModePreference selected;
  final ValueChanged<ThemeModePreference> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.softFill,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in ThemeModePreference.values) ...[
            _ModeIconButton(
              icon: _modeIcon(option),
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
            if (option != ThemeModePreference.values.last)
              const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }

  IconData _modeIcon(ThemeModePreference mode) {
    return switch (mode) {
      ThemeModePreference.light => Icons.wb_sunny_outlined,
      ThemeModePreference.dark => Icons.nightlight_round,
      ThemeModePreference.system => Icons.brightness_auto_outlined,
    };
  }
}

class _ModeIconButton extends StatelessWidget {
  const _ModeIconButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? colors.onStrong : colors.textSecondary,
        ),
      ),
    );
  }
}

class _FontScalePanel extends StatelessWidget {
  const _FontScalePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.surface(context),
      child: ValueListenableBuilder<AppThemeOption>(
        valueListenable: themeController,
        builder: (context, _, child) {
          final colors = context.colors;
          final scale = themeController.fontScale;

          return Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: AppDecorations.softFill(context),
                  child: Icon(
                    Icons.format_size_outlined,
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
                        '字号大小',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong(context),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '当前：${scale.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMuted(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _FontScaleSelector(
                  selected: scale,
                  onSelected: themeController.setFontScale,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FontScaleSelector extends StatelessWidget {
  const _FontScaleSelector({
    required this.selected,
    required this.onSelected,
  });

  final AppFontScale selected;
  final ValueChanged<AppFontScale> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.softFill,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in AppFontScale.values) ...[
            _FontScaleButton(
              label: option.label,
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
            if (option != AppFontScale.values.last) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

class _FontScaleButton extends StatelessWidget {
  const _FontScaleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: AppTextStyles.chip(context, selected: selected).copyWith(
            fontSize: selected ? 13 : 12,
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
        builder: (context, _, child) {
          return Column(
            children: [
              _ThemeCurrentTile(
                colorFamily: themeController.currentColorFamilyOption,
              ),
              const _PanelDivider(),
              _ThemeSelectorGrid(
                selectedFamily: themeController.colorFamily,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeCurrentTile extends StatelessWidget {
  const _ThemeCurrentTile({required this.colorFamily});

  final AppColorFamilyOption colorFamily;

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
                  '当前：${colorFamily.name}',
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
  const _ThemeSelectorGrid({required this.selectedFamily});

  final AppColorFamily selectedFamily;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final option in ThemeController.colorFamilies)
            _ThemeOptionTile(
              option: option,
              selected: option.family == selectedFamily,
              onTap: () => themeController.setColorFamily(option.family),
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

  final AppColorFamilyOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final needsBorder =
        option.previewColor.computeLuminance() > 0.92 ||
        option.previewColor.computeLuminance() < 0.08;

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
                  color: needsBorder ? colors.surfaceBorder : Colors.transparent,
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
