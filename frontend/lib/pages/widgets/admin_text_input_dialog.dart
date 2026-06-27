import 'package:flutter/material.dart';

Future<String?> showAdminTextInputDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  required String hintText,
  required String confirmText,
  String? initialValue,
  bool requiredInput = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _AdminTextInputDialog(
      title: title,
      labelText: labelText,
      hintText: hintText,
      confirmText: confirmText,
      initialValue: initialValue,
      requiredInput: requiredInput,
    ),
  );
}

class _AdminTextInputDialog extends StatefulWidget {
  const _AdminTextInputDialog({
    required this.title,
    required this.labelText,
    required this.hintText,
    required this.confirmText,
    required this.initialValue,
    required this.requiredInput,
  });

  final String title;
  final String labelText;
  final String hintText;
  final String confirmText;
  final String? initialValue;
  final bool requiredInput;

  @override
  State<_AdminTextInputDialog> createState() => _AdminTextInputDialogState();
}

class _AdminTextInputDialogState extends State<_AdminTextInputDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (widget.requiredInput && text.isEmpty) {
              return '请输入内容';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmText)),
      ],
    );
  }
}
