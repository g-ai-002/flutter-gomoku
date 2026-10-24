import 'dart:ui';

import '../models/game_state.dart';

/// 棋盘坐标换算：固定 600×600 世界坐标 ↔ 棋盘交叉点。
///
/// 交叉点 `(row, col)` 的圆心位于
/// `(padding + col * cellSize, padding + row * cellSize)`，与旧
/// `BoardPainter` 的布局口径一致，点击时吸附到最近的交叉点。
class GomokuBoardGeometry {
  /// Flame 世界的固定分辨率边长。
  static const double worldSize = 600;

  /// 棋盘四周留白（换算前的逻辑尺寸）。
  static const double margin = 32;

  final int boardSize;
  final double cellSize;
  final double padding;

  const GomokuBoardGeometry({
    required this.boardSize,
    required this.cellSize,
    required this.padding,
  });

  factory GomokuBoardGeometry.forBoard(int boardSize) {
    final cell = (worldSize - margin) / boardSize;
    final span = cell * (boardSize - 1);
    return GomokuBoardGeometry(
      boardSize: boardSize,
      cellSize: cell,
      padding: (worldSize - span) / 2,
    );
  }

  /// 交叉点圆心。
  Offset centerOf(int row, int col) => Offset(
        padding + col * cellSize,
        padding + row * cellSize,
      );

  /// 把世界坐标吸附到最近的交叉点；落在棋盘外返回 null。
  Position? positionAt(Offset point) {
    final col = ((point.dx - padding) / cellSize).round();
    final row = ((point.dy - padding) / cellSize).round();
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
      return null;
    }
    return Position(row, col);
  }

  /// 星位（天元与边星）。
  List<(int, int)> get starPoints {
    if (boardSize == 15) {
      return const [
        (3, 3), (3, 7), (3, 11),
        (7, 3), (7, 7), (7, 11),
        (11, 3), (11, 7), (11, 11),
      ];
    }
    if (boardSize == 19) {
      return const [
        (3, 3), (3, 9), (3, 15),
        (9, 3), (9, 9), (9, 15),
        (15, 3), (15, 9), (15, 15),
      ];
    }
    final c = boardSize ~/ 2;
    final e = boardSize - 4;
    return [(3, 3), (3, e), (e, 3), (e, e), (c, c)];
  }
}
