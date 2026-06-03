import 'package:flutter/material.dart';

Future<String?> showLedgerNameDialog(
  BuildContext context, {
  required String title,
  required String confirmText,
  String? initialValue,
}) {
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (dialogContext) => _LedgerNameDialog(
      title: title,
      confirmText: confirmText,
      initialValue: initialValue,
    ),
  );
}

class _LedgerNameDialog extends StatefulWidget {
  const _LedgerNameDialog({
    required this.title,
    required this.confirmText,
    this.initialValue,
  });

  final String title;
  final String confirmText;
  final String? initialValue;

  @override
  State<_LedgerNameDialog> createState() => _LedgerNameDialogState();
}

class _LedgerNameDialogState extends State<_LedgerNameDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
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
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          maxLength: 16,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            hintText: '请输入账本名称',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
