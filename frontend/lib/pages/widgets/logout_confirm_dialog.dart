import 'package:flutter/material.dart';

Future<bool> showLogoutConfirmDialog(
  BuildContext context, {
  String title = '退出登录',
  String message = '确定要退出当前账号吗？',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认退出'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
