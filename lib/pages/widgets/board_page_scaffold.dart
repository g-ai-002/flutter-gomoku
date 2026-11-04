import 'package:flutter/material.dart';

/// 对局页与复盘页共用的页面骨架：双行标题 AppBar 与安全区内容。
class BoardPageScaffold extends StatelessWidget {
  const BoardPageScaffold({
    super.key,
    required this.title,
    required this.caption,
    required this.body,
    this.actions = const [],
  });

  final String title;

  /// 标题下方的副标题，展示难度、执子或棋谱名称。
  final String caption;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 58,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [...actions, const SizedBox(width: 4)],
      ),
      body: SafeArea(child: body),
    );
  }
}
