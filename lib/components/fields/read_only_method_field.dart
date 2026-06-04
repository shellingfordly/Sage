import 'package:flutter/material.dart';

import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';

/// 只读展示账单「方式」，用于导入记录的编辑场景。
class ReadOnlyMethodField extends StatelessWidget {
  const ReadOnlyMethodField({
    super.key,
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '方式',
        border: OutlineInputBorder(borderRadius: AppRadii.card),
      ),
      child: Text(
        value,
        style: AppTextStyles.bodyStrong(context),
      ),
    );
  }
}
