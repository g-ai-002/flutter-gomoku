import 'package:flutter/material.dart';

/// 打开一个新页面，统一页面跳转的路由类型与构建方式。
Future<T?> pushScreen<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => page));

/// 用新页面替换当前页面，用于残局「下一关」与保存后直接挑战。
Future<T?> replaceScreen<T>(BuildContext context, Widget page) =>
    Navigator.of(context)
        .pushReplacement<T, void>(MaterialPageRoute<T>(builder: (_) => page));
