import 'package:flutter/material.dart';

import 'play_layout.dart';

/// 对局页与残局页共用的棋盘页面布局。
///
/// 只重建状态区、操作区与棋谱栏，棋盘与 Flame 画布保持稳定，
/// 避免提示、棋钟与禁手标记等浮层变化推动棋盘。
class BoardPlayLayout extends StatelessWidget {
  const BoardPlayLayout({
    super.key,
    required this.controller,
    required this.status,
    required this.board,
    required this.actions,
    required this.sidePanel,
  });

  final Listenable controller;

  /// 棋盘上方的状态区。
  final WidgetBuilder status;

  final Widget board;

  /// 底部操作区；窄屏时 [showMoves] 为 true，可额外展示棋谱入口。
  final Widget Function(BuildContext context, bool showMoves) actions;

  /// 宽屏右侧棋谱栏。
  final WidgetBuilder sidePanel;

  @override
  Widget build(BuildContext context) {
    return PlayLayout(
      status: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => status(context),
      ),
      board: board,
      actions: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => actions(context, false),
      ),
      compactBottom: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: actions(context, true),
        ),
      ),
      sidePanel: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => sidePanel(context),
      ),
    );
  }
}
