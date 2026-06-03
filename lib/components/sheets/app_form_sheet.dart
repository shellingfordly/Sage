import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';

/// 通用底部表单弹窗：统一布局、动效与操作区样式。
Future<T?> showAppFormSheet<T>(
  BuildContext context, {
  required Widget sheet,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.46),
    transitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (context, animation, secondaryAnimation) => sheet,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slide = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final fade = CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.65, curve: Curves.easeOut),
        reverseCurve: const Interval(0, 0.45, curve: Curves.easeIn),
      );

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(slide),
          child: child,
        ),
      );
    },
  );
}

class AppFormSheet extends StatelessWidget {
  const AppFormSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.cancelText = '取消',
    required this.confirmText,
    required this.onConfirm,
    this.onCancel,
    this.confirmEnabled = true,
    this.maxHeightFactor = 0.92,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final String cancelText;
  final String confirmText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool confirmEnabled;
  final double maxHeightFactor;
  final Widget child;

  void _handleCancel(BuildContext context) {
    if (onCancel != null) {
      onCancel!();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(color: colors.surfaceBorder.withValues(alpha: 0.7)),
                left: BorderSide(color: colors.surfaceBorder.withValues(alpha: 0.7)),
                right: BorderSide(color: colors.surfaceBorder.withValues(alpha: 0.7)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: AppTextStyles.sectionTitle(context)),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(subtitle!, style: AppTextStyles.bodyMuted(context)),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _handleCancel(context),
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: AppDecorations.softFill(context),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: child,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleCancel(context),
                            child: Text(cancelText),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: confirmEnabled ? onConfirm : null,
                            child: Text(confirmText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppFormTextField extends StatelessWidget {
  const AppFormTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.maxLength,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          maxLength: maxLength,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: AppTextStyles.bodyStrong(context).copyWith(
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: colors.softFill,
            counterText: maxLength != null ? '' : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: AppRadii.card,
              borderSide: BorderSide(color: colors.surfaceBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.card,
              borderSide: BorderSide(color: colors.surfaceBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.card,
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadii.card,
              borderSide: BorderSide(color: colors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadii.card,
              borderSide: BorderSide(color: colors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class AppFormSectionLabel extends StatelessWidget {
  const AppFormSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.bodyStrong(context));
  }
}
