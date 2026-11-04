import 'package:flutter/material.dart';

/// 页面轻提示：先收起上一条，避免连续操作时提示排队等待。
void showSnack(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message), duration: duration));
}
