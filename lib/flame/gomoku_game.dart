import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/board_view.dart';
import '../theme/board_skin.dart';
import 'board_component.dart';

/// Flame 游戏入口：棋盘组件铺满可用区域。
class GomokuGame extends FlameGame {
  GomokuGame({required this.view, BoardSkin skin = kDefaultBoardSkin})
    : _skin = ValueNotifier(skin);

  final BoardView view;
  final ValueNotifier<BoardSkin> _skin;
  BoardComponent? _board;

  BoardSkin get skin => _skin.value;
  set skin(BoardSkin value) => _skin.value = value;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    final board = BoardComponent(view: view, skin: _skin);
    _board = board;
    _fit(board);
    await add(board);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final board = _board;
    if (board != null) _fit(board);
  }

  /// 棋盘始终铺满游戏区域，随窗口或屏幕尺寸变化重建尺寸。
  void _fit(BoardComponent board) {
    board
      ..size = size.clone()
      ..position = Vector2.zero();
  }
}
