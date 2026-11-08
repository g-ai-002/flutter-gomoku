import 'package:flutter/material.dart';

/// 棋盘页骨架：棋盘居中，状态与提示悬浮在棋盘上方左右，操作按钮悬浮在下方。
///
/// 棋盘边长只由剩余空间决定，状态条、棋钟与按钮的变化不会推动或缩放棋盘；
/// 棋谱改由操作区的「棋谱」按钮弹出，不再占用显示空间。
class PlayLayout extends StatelessWidget {
  const PlayLayout({
    super.key,
    required this.board,
    this.status,
    this.actions,
    this.controller,
  });

  final Widget board;

  /// 行棋方、棋钟等状态信息，位于棋盘上方。
  final WidgetBuilder? status;

  /// 底部操作区，内含棋谱弹窗入口。
  final WidgetBuilder? actions;

  /// 传入后状态区与操作区在该控制器通知时重建，棋盘保持稳定不重建。
  final Listenable? controller;

  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) => Padding(
    padding: _padding,
    child: Column(
      children: [
        if (status != null) ...[
          _build(context, status!),
          const SizedBox(height: _gap),
        ],
        Expanded(child: board),
        if (actions != null) ...[
          const SizedBox(height: _gap),
          _build(context, actions!),
        ],
      ],
    ),
  );

  Widget _build(BuildContext context, WidgetBuilder builder) {
    final listenable = controller;
    return listenable == null
        ? builder(context)
        : AnimatedBuilder(
            animation: listenable,
            builder: (context, _) => builder(context),
          );
  }
}
