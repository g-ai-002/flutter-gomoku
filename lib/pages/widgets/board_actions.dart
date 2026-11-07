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
    final buttons = [
      (
        Icons.undo_rounded,
        '悔棋',
        canUndo ? onUndo : null,
      ),
      (Icons.refresh_rounded, '重开', onRestart),
      if (onMoves != null) (Icons.format_list_bulleted_rounded, '棋谱', onMoves),
      if (onHint != null)
        (
          Icons.lightbulb_outline,
          hintLoading ? '思考中' : '提示',
          hintEnabled && !hintLoading ? onHint : null,
        ),
      if (onResign != null) (Icons.flag_outlined, '认输', onResign),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      children: [
        for (final (icon, label, onPressed) in buttons)
          BoardActionButton(
            icon: icon,
            label: label,
            onPressed: onPressed,
          ),
      ],
    );
  }
}
