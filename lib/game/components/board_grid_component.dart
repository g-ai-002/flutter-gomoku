import 'dart:ui';

import '../gomoku_board_geometry.dart';
import 'board_layer_component.dart';

/// 棋盘背景、网格线与星位。
class BoardGridComponent extends BoardLayerComponent {
  BoardGridComponent({
    required super.source,
    required super.palette,
    super.priority,
  });

  @override
  void render(Canvas canvas) {
    const worldSize = GomokuBoardGeometry.worldSize;
    final g = geometry;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, worldSize, worldSize),
      const Radius.circular(14),
    );

    canvas.drawRRect(rect, Paint()..color = palette.boardColor);

    final linePaint = Paint()
      ..color = palette.lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final span = g.cellSize * (g.boardSize - 1);
    for (var i = 0; i < g.boardSize; i++) {
      final offset = g.padding + i * g.cellSize;
      canvas.drawLine(
        Offset(g.padding, offset),
        Offset(g.padding + span, offset),
        linePaint,
      );
      canvas.drawLine(
        Offset(offset, g.padding),
        Offset(offset, g.padding + span),
        linePaint,
      );
    }

    final starPaint = Paint()..color = palette.lineColor;
    for (final (row, col) in g.starPoints) {
      canvas.drawCircle(g.centerOf(row, col), g.cellSize * 0.09, starPaint);
    }

    canvas.drawRRect(
      rect.deflate(0.6),
      Paint()
        ..color = palette.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }
}
