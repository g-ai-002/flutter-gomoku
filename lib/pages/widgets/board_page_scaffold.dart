import 'package:flutter/material.dart';

/// 对局页与复盘页共用的页面骨架：单行紧凑标题栏与安全区内容。
///
/// 标题与副标题同处一行，标题栏只占 46 高，把纵向空间尽量留给棋盘。
class BoardPageScaffold extends StatelessWidget {
  const BoardPageScaffold({
    super.key,
    required this.title,
    required this.caption,
    required this.body,
    this.actions = const [],
  });

  final String title;

  /// 标题右侧的副标题，展示难度、执子或棋谱名称。
  final String caption;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 46,
        titleSpacing: 4,
        title: Row(
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
