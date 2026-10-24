import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import 'board_layer_component.dart';

/// 落子/获胜的粒子反馈。
class GomokuParticlesComponent extends BoardLayerComponent {
  GomokuParticlesComponent({
    required super.source,
    required super.palette,
    super.priority,
  });

  final List<_Spark> _sparks = [];
  final math.Random _random = math.Random();
  final Paint _paint = Paint();

  void burst(Position cell, {Color color = const Color(0xFFFFD54F), int count = 10}) {
    final g = geometry;
    final center = g.centerOf(cell.row, cell.col);
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = g.cellSize * (0.8 + _random.nextDouble() * 2.2);
      final life = 0.3 + _random.nextDouble() * 0.25;
      _sparks.add(
        _Spark(
          position: Vector2(center.dx, center.dy),
          velocity: Vector2(
            math.cos(angle) * speed,
            math.sin(angle) * speed,
          ),
          color: color,
          life: life,
          radius: g.cellSize * (0.04 + _random.nextDouble() * 0.05),
        ),
      );
    }
  }

  /// 沿胜利五连撒一串粒子。
  void burstLine(Position start, Position end, {int count = 24}) {
    for (var i = 0; i < count; i++) {
      final t = count == 1 ? 0.0 : i / (count - 1);
      final row = (start.row + (end.row - start.row) * t).round();
      final col = (start.col + (end.col - start.col) * t).round();
      burst(
        Position(row, col),
        color: const Color(0xFFFF5252),
        count: 4,
      );
    }
  }

  void clear() => _sparks.clear();

  @override
  void update(double dt) {
    super.update(dt);
    final damping = math.pow(0.05, dt).toDouble();
    for (final spark in _sparks) {
      spark.life -= dt;
      spark.position += spark.velocity * dt;
      spark.velocity *= damping;
    }
    _sparks.removeWhere((spark) => spark.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    for (final spark in _sparks) {
      final t = (spark.life / spark.maxLife).clamp(0.0, 1.0).toDouble();
      _paint.color = spark.color.withValues(alpha: 0.9 * t);
      canvas.drawCircle(
        Offset(spark.position.x, spark.position.y),
        spark.radius * (0.5 + 0.7 * t),
        _paint,
      );
    }
  }
}

class _Spark {
  _Spark({
    required this.position,
    required this.velocity,
    required this.color,
    required this.life,
    required this.radius,
  }) : maxLife = life;

  Vector2 position;
  Vector2 velocity;
  final Color color;
  final double maxLife;
  final double radius;
  double life;
}
