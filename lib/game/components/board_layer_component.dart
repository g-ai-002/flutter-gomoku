import 'package:flame/components.dart';

import '../gomoku_board_geometry.dart';
import '../../providers/game_provider.dart';

/// 棋盘图层公共基类：统一持有 provider 与棋盘几何信息。
abstract class BoardLayerComponent extends PositionComponent {
  BoardLayerComponent({
    required this.provider,
    int? priority,
  }) : super(
          priority: priority,
          size: Vector2.all(GomokuBoardGeometry.worldSize),
        );

  final GameProvider provider;

  GomokuBoardGeometry get geometry =>
      GomokuBoardGeometry.forBoard(provider.state.boardSize);
}
