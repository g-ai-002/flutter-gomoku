import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/board_view.dart';
import 'board_component.dart';

/// Flame 游戏入口：棋盘组件铺满可用区域。
///
/// 棋盘没有逐帧变化的内容时暂停渲染循环，落子、提示或悬停再唤醒；
/// [repaint] 通常传入对局控制器，局面变化会立即唤醒循环。
class GomokuGame extends FlameGame {
  GomokuGame({required this.view, this.repaint}) {
    repaint?.addListener(wake);
  }

  final BoardView view;

  final Listenable? repaint;
  BoardComponent? _board;
  bool _idlePaused = false;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    final board = BoardComponent(
      view: view,
      onIdle: pauseForIdle,
      onWake: wake,
    );
    _board = board;
    _fit(board);
    await add(board);
  }

  /// 唤醒棋盘渲染；只在空闲暂停时恢复，避免覆盖系统后台暂停。
  void wake() {
    if (!_idlePaused) return;
    _idlePaused = false;
    resumeEngine();
  }

  @visibleForTesting
  void pauseForIdle() {
    if (paused) return;
    _idlePaused = true;
    pauseEngine();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    wake();
    final board = _board;
    if (board != null) _fit(board);
  }

  /// 棋盘始终铺满游戏区域，随窗口或屏幕尺寸变化重建尺寸。
  void _fit(BoardComponent board) {
    board
      ..size = size.clone()
      ..position = Vector2.zero();
  }

  @override
  void onDispose() {
    repaint?.removeListener(wake);
    _board?.disposeResources();
    _board = null;
    super.onDispose();
  }
}
