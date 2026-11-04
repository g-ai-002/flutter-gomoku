import 'package:flutter/material.dart';

import 'action_button.dart';

/// 对局页与残局页共用的底部操作栏。
///
/// 各动作以回调是否为 null 决定是否展示；提示按钮在搜索期间显示
/// 「思考中」并禁用，避免重复发起请求。
class BoardActions extends StatelessWidget {
  const BoardActions({
    super.key,
    required this.canUndo,
    required this.onUndo,
    required this.onRestart,
    this.onMoves,
    this.onHint,
    this.hintEnabled = true,
    this.hintLoading = false,
    this.onResign,
  });

  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onRestart;
  final VoidCallback? onMoves;
  final VoidCallback? onHint;
  final bool hintEnabled;
  final bool hintLoading;
  final VoidCallback? onResign;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      children: [
        BoardActionButton(
          icon: Icons.undo_rounded,
          label: '悔棋',
          onPressed: canUndo ? onUndo : null,
        ),
        BoardActionButton(
          icon: Icons.refresh_rounded,
          label: '重开',
          onPressed: onRestart,
        ),
        if (onMoves != null)
          BoardActionButton(
            icon: Icons.format_list_bulleted_rounded,
            label: '棋谱',
            onPressed: onMoves,
          ),
        if (onHint != null)
          BoardActionButton(
            icon: Icons.lightbulb_outline,
            label: hintLoading ? '思考中' : '提示',
            onPressed: hintEnabled && !hintLoading ? onHint : null,
          ),
        if (onResign != null)
          BoardActionButton(
            icon: Icons.flag_outlined,
            label: '认输',
            onPressed: onResign,
          ),
      ],
    );
  }
}
