import 'package:flutter/material.dart';

import 'board_stage.dart';

/// 对局页与复盘页共用的棋盘布局骨架。
///
/// 棋盘优先吃掉全部可用空间：宽度 ≥ 880 时状态区与操作区收进右侧棋谱栏，
/// 窄屏时悬浮在页面上下边缘，横屏等扁平窗口再把操作区移到右侧竖栏。
/// 棋盘尺寸只由窗口尺寸决定，状态、棋钟与提示的文案变化都不会推动棋盘。
class PlayLayout extends StatelessWidget {
  const PlayLayout({
    super.key,
    required this.board,
    required this.sidePanel,
    this.status,
    this.actions,
    this.compactBottom,
    this.controller,
  });

  final Widget board;
  final WidgetBuilder sidePanel;

  /// 行棋方、棋钟等状态信息，宽屏时位于棋谱栏上方。
  final WidgetBuilder? status;

  /// 操作区；[showMoves] 为 true 时是窄屏版本，可额外展示棋谱入口。
  final Widget Function(BuildContext context, bool showMoves)? actions;

  /// 窄屏专用的整块底部区域，缺省时使用 [actions]。
  final WidgetBuilder? compactBottom;

  /// 传入后各区域在该控制器通知时重建，棋盘保持稳定不重建。
  final Listenable? controller;

  static const double _wideWidth = 880;
  static const double _sidePanelWidth = 292;
  static const double _railWidth = 200;

  /// 棋盘两侧的呼吸边距，悬浮的状态区与操作区也按这个宽度对齐。
  static const double _gutter = 12;

  /// 上下放不下悬浮信息时预留的固定高度。
  static const double _hudReserve = 98;

  @override
  Widget build(BuildContext context) {
    final bottom = compactBottom ?? _actionBuilder(true);
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= _wideWidth
          ? _buildWide(context)
          : _buildCompact(context, constraints, bottom),
    );
  }

  /// 宽屏：棋盘独占左列，状态区与操作区分列棋谱栏上下两端。
  Widget _buildWide(BuildContext context) {
    final panel = Column(
      children: [
        if (status != null) ...[
          _build(context, status!),
          const SizedBox(height: 8),
        ],
        Expanded(child: _build(context, sidePanel)),
        if (actions != null) ...[
          const SizedBox(height: 8),
          _build(context, _actionBuilder(false)!),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Expanded(child: board),
          const SizedBox(width: 18),
          SizedBox(width: _sidePanelWidth, child: panel),
        ],
      ),
    );
  }

  /// 窄屏：棋盘居中，状态区与操作区贴住页面上下边缘，不占棋盘高度。
  Widget _buildCompact(
    BuildContext context,
    BoxConstraints constraints,
    WidgetBuilder? bottom,
  ) {
    final area = Size(constraints.maxWidth - _gutter * 2, constraints.maxHeight);
    final base = boardSideFor(area);
    final spare = area.height - base;
    // 横屏时左右留白充足，操作区改走右侧竖栏，避免压住棋盘底部交叉点。
    final rail =
        spare < _hudReserve && (area.width - base) / 2 >= _railWidth + 24;
    final side = spare < _hudReserve && !rail
        ? boardSideFor(Size(area.width, area.height - _hudReserve))
        : base;
    final left = (area.width - side) / 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _gutter),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: SizedBox.square(dimension: side, child: board),
            ),
          ),
          if (status != null)
            Positioned(
              top: 4,
              left: rail ? 4 : left,
              width: rail ? _railWidth : side,
              child: _build(context, status!),
            ),
          if (bottom != null)
            Positioned(
              bottom: 4,
              left: rail ? null : left,
              right: rail ? 4 : null,
              width: rail ? _railWidth : side,
              child: _build(context, bottom),
            ),
        ],
      ),
    );
  }

  WidgetBuilder? _actionBuilder(bool showMoves) => actions == null
      ? null
      : (context) => actions!(context, showMoves);

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
