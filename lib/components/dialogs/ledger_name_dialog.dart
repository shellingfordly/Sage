import 'package:flutter/material.dart';

import '../sheets/app_form_sheet.dart';

Future<String?> showLedgerNameDialog(
  BuildContext context, {
  required String title,
  required String confirmText,
  String? initialValue,
  String? subtitle,
}) {
  return showAppFormSheet<String>(
    context,
    sheet: _LedgerNameSheet(
      title: title,
      subtitle: subtitle,
      confirmText: confirmText,
      initialValue: initialValue,
    ),
  );
}

class _LedgerNameSheet extends StatefulWidget {
  const _LedgerNameSheet({
    required this.title,
    required this.confirmText,
    this.subtitle,
    this.initialValue,
  });

  final String title;
  final String? subtitle;
  final String confirmText;
  final String? initialValue;

  @override
  State<_LedgerNameSheet> createState() => _LedgerNameSheetState();
}

class _LedgerNameSheetState extends State<_LedgerNameSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focusNode = FocusNode();
    _canSubmit = _controller.text.trim().isNotEmpty;
    _controller.addListener(_syncSubmitState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _syncSubmitState() {
    final enabled = _controller.text.trim().isNotEmpty;
    if (enabled != _canSubmit) {
      setState(() => _canSubmit = enabled);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncSubmitState);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.title,
      subtitle: widget.subtitle ?? '最多 16 个字符',
      confirmText: widget.confirmText,
      confirmEnabled: _canSubmit,
      onConfirm: _submit,
      child: AppFormTextField(
        controller: _controller,
        focusNode: _focusNode,
        label: '账本名称',
        hintText: '请输入账本名称',
        maxLength: 16,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
