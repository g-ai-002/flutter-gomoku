import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../utils/constants.dart';
import 'board_layer_component.dart';

/// 棋子层：把棋盘数据源同步成带落子弹入动画的棋子。
class StoneLayerComponent extends BoardLayerComponent {
  StoneLayerComponent({
    required super.source,
    required super.palette,
    super.priority,
  });

  /// 落子弹入时长（秒）。
  static const double popDuration = 0.18;

  final Map<int, _Stone> _stones = {};
  final Paint _shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.18);
  final Paint _fillPaint = Paint();
  final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1;
  final Paint _glossPaint = Paint();
  final Paint _markPaint = Paint()
    ..style = PaintingStyle.stroke;

  double _elapsed = 0;
  int _boardSize = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _sync();
  }

  void _sync() {
    if (source.boardSize != _boardSize) {
      _boardSize = source.boardSize;
      _stones.clear();
    }

    final board = source.board;
    final present = <int>{};
    for (var row = 0; row < _boardSize; row++) {
      for (var col = 0; col < _boardSize; col++) {
        final stone = board[row][col];
        if (stone == null) {
          continue;
        }
        final key = row * _boardSize + col;
        present.add(key);
        final existing = _stones[key];
        if (existing == null || existing.color != stone) {
          _stones[key] = _Stone(stone, _elapsed);
        }
      }
    }
    _stones.removeWhere((key, _) => !present.contains(key));
  }

  @override
  void render(Canvas canvas) {
    final g = geometry;
    final radius = g.cellSize * AppConstants.stoneRadiusRatio;
    final lastMove = source.lastMove;

    _stones.forEach((key, stone) {
      final row = key ~/ _boardSize;
      final col = key % _boardSize;
      final progress =
          ((_elapsed - stone.bornAt) / popDuration).clamp(0.0, 1.0).toDouble();
      _drawStone(
        canvas,
        g.centerOf(row, col),
        radius,
        stone.color,
        _easeOutBack(progress),
      );

      final isLast = source.isPlaying &&
          lastMove != null &&
          lastMove.row == row &&
          lastMove.col == col;
      if (isLast && progress >= 1) {
        _markPaint
          ..color = const Color(0xFFFF5252)
          ..strokeWidth = g.cellSize * 0.06;
        canvas.drawCircle(g.centerOf(row, col), radius * 0.34, _markPaint);
      }
    });
  }

  void _drawStone(
    Canvas canvas,
    Offset center,
    double radius,
    StoneColor color,
    double scale,
  ) {
    if (scale <= 0.01) {
      return;
    }
    final r = radius * scale;
    final isBlack = color == StoneColor.black;

    canvas.drawCircle(center + Offset(r * 0.08, r * 0.1), r, _shadowPaint);

    _fillPaint.color =
        isBlack ? AppConstants.blackStoneDark : AppConstants.whiteStoneDark;
    canvas.drawCircle(center, r, _fillPaint);

    _fillPaint.color =
        isBlack ? AppConstants.blackStoneLight : AppConstants.whiteStoneLight;
    canvas.drawCircle(center - Offset(r * 0.06, r * 0.08), r * 0.92, _fillPaint);

    _borderPaint.color = isBlack
        ? AppConstants.blackStoneBorder
        : AppConstants.whiteStoneBorder;
    canvas.drawCircle(center, r, _borderPaint);

    _glossPaint.color =
        Colors.white.withValues(alpha: isBlack ? 0.16 : 0.55);
    canvas.drawCircle(
      center - Offset(r * 0.3, r * 0.32),
      math.max(1.0, r * 0.22),
      _glossPaint,
    );
  }

  /// 缓出回弹曲线
  double _easeOutBack(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return (1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)).toDouble();
  }
}

class _Stone {
  _Stone(this.color, this.bornAt);

  final StoneColor color;
  final double bornAt;
}
