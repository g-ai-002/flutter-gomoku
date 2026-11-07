import 'package:flutter/material.dart';

import 'board_stage.dart';

/// 棋盘页布局骨架：棋盘永远按可用空间取最大边长，信息区只让位、不挤压。
///
/// 三种骨架按窗口形状择优：宽屏（侧栏后棋盘不失地）为「棋盘 + 右侧棋谱栏」；
/// 扁平窗口为「棋盘 + 200 宽竖栏」，横屏手机也能拿到接近满高的棋盘；
/// 竖向窗口把状态贴棋盘上沿、操作贴下沿，富余高度常驻棋谱。
/// 棋盘边长只由窗口尺寸决定，提示、棋钟与棋谱变化都不会推动或缩放棋盘。
class PlayLayout extends StatelessWidget {
  const PlayLayout({
    super.key,
    required this.board,
    required this.sidePanel,
    this.status,
    this.actions,
    this.footer,
    this.controller,
  });

  final Widget board;

  /// 棋谱栏内容，宽屏侧栏与扁平窗口的竖栏共用。
  final WidgetBuilder sidePanel;

  /// 行棋方、棋钟等状态信息，位于棋盘上方或棋谱栏顶部。
  final WidgetBuilder? status;

  /// 操作区；[showMoves] 为 true 时额外提供棋谱弹窗入口。
  final Widget Function(BuildContext context, bool showMoves)? actions;

  /// 竖向窗口的常驻棋谱，空间不足时退回按钮弹窗。
  final WidgetBuilder? footer;

  /// 传入后各区域在该控制器通知时重建，棋盘保持稳定不重建。
  final Listenable? controller;

  static const double _gutter = 12;
  static const double _sidePanelWidth = 292;
  static const double _railWidth = 200;
  static const double _railGap = 12;

  /// 竖向排布时状态区、棋钟与操作区的总高度预算。
  static const double _hudReserve = 140;

  /// 常驻棋谱至少要有的高度，低于该值改为按钮弹窗。
  static const double _footerMin = 108;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = Size(
          constraints.maxWidth - _gutter * 2,
          constraints.maxHeight,
        );
        if (_fitsWide(area)) return _buildWide(context);
        final rail = boardSideFor(
          Size(area.width - _railWidth - _railGap, area.height),
        );
        if (rail >= 200 && rail > _stackSide(area) + 12) {
          return _buildRail(context);
        }
        return _buildStack(context, area);
      },
    );
  }

  bool _fitsWide(Size area) {
    if (area.width < 856) return false;
    final full = boardSideFor(area);
    final panel = boardSideFor(
      Size(area.width - _sidePanelWidth - 58, area.height - 16),
    );
    return panel >= full * 0.8;
  }

  double _stackSide(Size area) => boardSideFor(
    Size(area.width, area.height - _hudReserve - (area.width < 300 ? 56 : 0)),
  );

  Widget _buildWide(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
    child: Row(
      children: [
        Expanded(child: board),
        const SizedBox(width: 18),
        SizedBox(width: _sidePanelWidth, child: _buildPanel(context)),
      ],
    ),
  );

  /// 扁平窗口：棋盘居左，状态、棋谱与操作收进窄竖栏，不再挤占棋盘高度。
  Widget _buildRail(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: _gutter),
    child: Row(
      children: [
        Expanded(child: board),
        const SizedBox(width: _railGap),
        SizedBox(width: _railWidth, child: _buildPanel(context)),
      ],
    ),
  );

  /// 侧栏与竖栏共用：状态在上、棋谱居中、操作在下。
  Widget _buildPanel(BuildContext context) => Column(
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

  /// 竖向窗口：状态与操作贴住棋盘上下沿，剩余高度交给常驻棋谱。
  Widget _buildStack(BuildContext context, Size area) {
    final side = _stackSide(area);
    final withFooter =
        footer != null && area.height - side - _hudReserve >= _footerMin;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _gutter),
      child: Center(
        child: SizedBox(
          width: side,
          height: withFooter ? area.height : null,
          child: Column(
            mainAxisAlignment: withFooter
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              if (status != null) ...[
                _build(context, status!),
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 6),
              SizedBox.square(dimension: side, child: board),
              if (actions != null) ...[
                const SizedBox(height: 8),
                _build(context, _actionBuilder(!withFooter)!),
              ],
              if (withFooter) ...[
                const SizedBox(height: 10),
                Expanded(child: _build(context, footer!)),
              ],
            ],
          ),
        ),
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
