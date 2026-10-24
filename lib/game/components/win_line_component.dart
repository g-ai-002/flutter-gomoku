import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'board_layer_component.dart';

/// 获胜五连的连线，随胜局出现逐段延伸。
class WinLineComponent extends BoardLayerComponent {
  WinLineComponent({
    required super.source,
    required super.palette,
    super.priority,
  });

  static const double _drawDuration = 0.28;

  final Paint _linePaint = Paint()
    ..color = const Color(0xFFFF5252)
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  double _progress = 0;

  @override
  void update(double dt) {
    super.update(dt);
    final start = source.winStart;
    final end = source.winEnd;
    if (start == null || end == null) {
      _progress = 0;
      return;
    }
    _progress = math.min(1.0, _progress + dt / _drawDuration);
  }

  @override
  void render(Canvas canvas) {
    final start = source.winStart;
    final end = source.winEnd;
    if (start == null || end == null || _progress <= 0) {
      return;
    }
    final g = geometry;
    final from = g.centerOf(start.row, start.col);
    final to = g.centerOf(end.row, end.col);
    final tip = Offset(
      from.dx + (to.dx - from.dx) * _progress,
      from.dy + (to.dy - from.dy) * _progress,
    );

    canvas.drawLine(from, tip, _linePaint);
    canvas.drawCircle(
      from,
      g.cellSize * 0.1,
      _linePaint..style = PaintingStyle.fill,
    );
    _linePaint.style = PaintingStyle.stroke;
  }
}
