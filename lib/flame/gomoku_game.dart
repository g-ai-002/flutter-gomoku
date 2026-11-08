import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/board_view.dart';
import '../game/logic_rate.dart';
import 'board_component.dart';

/// Flame 游戏入口：棋盘组件铺满可用区域。
///
/// 棋盘没有逐帧变化的内容时暂停渲染循环，落子、提示或悬停再唤醒；
/// [repaint] 通常传入对局控制器，局面变化会立即唤醒循环。
class GomokuGame extends FlameGame {
  GomokuGame({
    required this.view,
    this.repaint,
    this.logicRate = LogicRate.hz60,
  }) {
    repaint?.addListener(wake);
  }

  final BoardView view;

  /// 棋盘逻辑更新速率，落子动画与脉冲按该步长推进。
  final LogicRate logicRate;

  final Listenable? repaint;
  BoardComponent? _board;
  bool _idlePaused = false;
  bool _stopped = false;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    final board = BoardComponent(
      view: view,
      onIdle: pauseForIdle,
      onWake: wake,
      logicRate: logicRate,
    );
    _board = board;
    _fit(board);
    await add(board);
  }

  /// 唤醒棋盘渲染；只在空闲暂停时恢复，避免覆盖系统后台暂停。
  void wake() {
    if (_idlePaused) {
      _idlePaused = false;
      if (!_stopped) resumeEngine();
    }
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

  /// 页面关闭时立即停循环、解绑监听并释放录制图层，不留后台帧任务。
  /// 可重复调用，GameWidget 卸载时再次触发只做幂等清理。
  void stop() {
    if (_stopped) return;
    _stopped = true;
    repaint?.removeListener(wake);
    _idlePaused = false;
    if (!paused) pauseEngine();
    _board?.disposeResources();
    _board = null;
  }

  @override
  void onDispose() {
    stop();
    super.onDispose();
  }
}
