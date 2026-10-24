import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../providers/game_provider.dart';
import 'components/board_grid_component.dart';
import 'components/stone_layer_component.dart';
import 'components/win_line_component.dart';
import 'gomoku_board_geometry.dart';
import 'gomoku_world.dart';
import 'input/board_input_component.dart';

/// 基于 Flame 的五子棋对局。
///
/// 棋盘、棋子与胜利连线由 [World] 内的组件渲染；对局规则仍由
/// [GameProvider] 持有，组件每帧从 provider 同步状态。
class GomokuGame extends FlameGame<GomokuWorld> {
  GomokuGame({
    required this.provider,
    required this.surfaceColor,
    required this.boardColor,
    required this.lineColor,
    required this.borderColor,
  }) : super(
          world: GomokuWorld(),
          camera: CameraComponent.withFixedResolution(
            width: GomokuBoardGeometry.worldSize,
            height: GomokuBoardGeometry.worldSize,
          ),
        );

  final GameProvider provider;
  final Color surfaceColor;
  final Color boardColor;
  final Color lineColor;
  final Color borderColor;

  @override
  Color backgroundColor() => surfaceColor;

  @override
  Future<void> onLoad() async {
    await world.addAll([
      BoardGridComponent(
        provider: provider,
        boardColor: boardColor,
        lineColor: lineColor,
        borderColor: borderColor,
        priority: 0,
      ),
      StoneLayerComponent(provider: provider, priority: 1),
      WinLineComponent(provider: provider, priority: 2),
      BoardInputComponent(provider: provider, priority: 10),
    ]);

    const half = GomokuBoardGeometry.worldSize / 2;
    camera.viewfinder.position = Vector2(half, half);
    camera.viewfinder.zoom = 1;
  }
}
