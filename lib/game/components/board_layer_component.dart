import 'package:flame/components.dart';

import '../gomoku_board_geometry.dart';
import '../gomoku_board_source.dart';
import '../gomoku_palette.dart';

/// 棋盘图层公共基类：统一持有棋盘数据源、配色与几何信息。
abstract class BoardLayerComponent extends PositionComponent {
  BoardLayerComponent({
    required this.source,
    required this.palette,
    super.priority,
  }) : super(
          size: Vector2.all(GomokuBoardGeometry.worldSize),
        );

  final GomokuBoardSource source;
  final GomokuPalette palette;

  GomokuBoardGeometry get geometry =>
      GomokuBoardGeometry.forBoard(source.boardSize);
}
