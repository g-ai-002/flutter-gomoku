import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide PointerMoveEvent;

import '../game/board_view.dart';
import '../game/engine/board_utils.dart';
import '../game/logic_rate.dart';
import '../services/sound_service.dart';
import '../theme/board_painting.dart';
import '../theme/board_skin.dart';

const double _animDuration = 0.26;

/// Flame 棋盘组件：绘制棋盘、棋子、提示与落子动画，并处理点击与悬停。
///
/// 棋盘底纹与坐标、静止棋子分别录制为图片复用，落子动画单独绘制，
/// Web 端也能保持流畅。
class BoardComponent extends PositionComponent
    with TapCallbacks, PointerMoveCallbacks {
  BoardComponent({
    required this.view,
    this.onIdle,
    this.onWake,
    LogicRate logicRate = LogicRate.hz60,
  }) : _stepper = FixedStepClock(logicRate.step);

  final BoardView view;

  /// 静止后回调暂停渲染，需要重绘时回调唤醒，由 [GomokuGame] 接管。
  final VoidCallback? onIdle;
  final VoidCallback? onWake;

  /// 落子动画与脉冲时间的推进步长，由设置页的逻辑更新速率决定。
  final FixedStepClock _stepper;

  double _cell = 0;
  double _originX = 0;
  double _originY = 0;
  double _time = 0;
  double _idle = 0;
  int _seenMoves = 0;
  int _seenRevision = 0;
  int _layoutToken = 0;
  _StoneAnim? _anim;
  int? _hoverIndex;

  static const double _idlePauseAfter = 0.5;

  bool get needsFrames => _anim != null || view.hintIndex != null;

  List<TextPainter>? _coordPainters;
  final _PictureLayer _boardLayer = _PictureLayer();
  final _PictureLayer _stoneLayer = _PictureLayer();

  // 浮层与标记每帧重绘，复用描边/填充画笔，避免逐帧创建 Paint。
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _fill = Paint();

  /// 坐标文字按尺寸缓存，缩放后须整体释放，避免按尺寸累积。
  void _disposeCoordPainters() {
    for (final painter in _coordPainters ?? const <TextPainter>[]) {
      painter.dispose();
    }
    _coordPainters = null;
  }

  /// 释放录制图层与坐标文字缓存；页面销毁时由 [GomokuGame] 调用。
  ///
  /// Flame 不会在 GameWidget 卸载时逐个调用子组件的 onRemove，
  /// 这里显式回收 ui.Picture，避免反复进出对局页累积原生图片内存。
  void disposeResources() {
    _disposeCoordPainters();
    _boardLayer.clear();
    _stoneLayer.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _stepper.advance(dt, _stepLogic);
    // 空闲判定用真实时间：低刷新率下暂停时机与视觉一致。
    if (needsFrames) {
      _idle = 0;
    } else if ((_idle += dt) >= _idlePauseAfter) {
      _idle = 0;
      onIdle?.call();
    }
  }

  /// 推进一个逻辑步：局面 revision、着法与落子动画都按固定步长前进。
  void _stepLogic(double span) {
    _time += span;
    if (view.revision != _seenRevision) {
      _seenRevision = view.revision;
      _anim = null;
      _seenMoves = view.history.length;
      _invalidateStones();
    }
    _syncMoves();
    final anim = _anim;
    if (anim == null) return;
    anim.elapsed += span;
    if (anim.elapsed >= _animDuration) {
      _anim = null;
      _invalidateStones();
    }
  }

  /// 新落子排队播放动画；悔棋、重开或复盘跳转时直接对齐当前局面。
  void _syncMoves() {
    final count = view.history.length;
    if (count == _seenMoves) return;
    if (count != _seenMoves + 1) {
      _anim = null;
      _seenMoves = count;
      _invalidateStones();
      return;
    }
    final record = view.history.last;
    _anim = _StoneAnim(index: record.index, side: record.side);
    _seenMoves = count;
    _hoverIndex = null;
    _invalidateStones();
  }

  void _invalidateStones() => _stoneLayer.clear();

  void _layout(double width, double height) {
    final hasCoords = view.showCoordinates;
    final cell = math.min(width, height) / (hasCoords ? 16.4 : 15.4);
    // 窗口缩放时同步丢弃坐标文字缓存，避免按尺寸累积 TextPainter。
    if ((cell - _cell).abs() > 0.01) _disposeCoordPainters();
    _cell = cell;
    _originX = width / 2 - _cell * 7;
    _originY = height / 2 - _cell * 7;
    // 图层缓存键用整数哈希：逐帧渲染不再构造字符串，减少 GC 压力。
    _layoutToken = Object.hash(width, height, cell);
  }

  Offset _centerOf(int index) =>
      Offset(_originX + colOf(index) * _cell, _originY + rowOf(index) * _cell);

  static Offset _offsetOf(Vector2 position) => Offset(position.x, position.y);

  int? _indexAt(Offset local) {
    if (_cell <= 0) return null;
    final col = ((local.dx - _originX) / _cell).round();
    final row = ((local.dy - _originY) / _cell).round();
    if (!inBoard(row, col)) return null;
    final center = Offset(_originX + col * _cell, _originY + row * _cell);
    if ((local - center).distance > _cell * 0.62) return null;
    return indexOf(row, col);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final index = _indexAt(_offsetOf(event.localPosition));
    if (index == null) return;
    if (!view.canInteract) return;
    if (view.cells[index] != empty && !view.allowsReplace) return;
    onWake?.call();
    SoundService.tap();
    view.tapCell(index);
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    final index = _indexAt(_offsetOf(event.localPosition));
    final next = index != null && view.cells[index] == empty && view.canInteract
        ? index
        : null;
    if (next == _hoverIndex) return;
    _hoverIndex = next;
    _idle = 0;
    onWake?.call();
  }

  @override
  void onPointerMoveStop(PointerMoveEvent event) {
    if (_hoverIndex == null) return;
    _hoverIndex = null;
    _idle = 0;
    onWake?.call();
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    _layout(size.x, size.y);
    canvas.save();
    canvas.drawPicture(_boardPicture());
    canvas.drawPicture(_stonePicture());
    _drawHint(canvas);
    _drawForbidden(canvas);
    _drawHover(canvas);
    _drawWinningLine(canvas);
    _drawAnim(canvas);
    _drawLastMarker(canvas);
    canvas.restore();
  }

  ui.Picture _boardPicture() {
    final key = Object.hash(_layoutToken, view.showCoordinates);
    return _boardLayer.paint(key, (canvas) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()
          ..shader = kBoardGradient.createShader(
            Rect.fromLTWH(0, 0, size.x, size.y),
          ),
      );
      _drawGrain(canvas);

      final Paint linePaint = Paint()
        ..color = kBoardLine.withValues(alpha: 0.72)
        ..strokeWidth = math.max(0.7, _cell * 0.035)
        ..style = PaintingStyle.stroke;
      paintBoardGrid(
        canvas,
        topLeft: Offset(_originX, _originY),
        cell: _cell,
        linePaint: linePaint,
        starPaint: Paint()..color = kBoardLine.withValues(alpha: 0.85),
        borderPaint: Paint()
          ..color = kBoardLine.withValues(alpha: 0.9)
          ..strokeWidth = math.max(1.1, _cell * 0.07)
          ..style = PaintingStyle.stroke,
      );
      if (view.showCoordinates) _drawCoords(canvas);
    });
  }

  void _drawGrain(Canvas canvas) {
    final paint = Paint()
      ..color = kBoardLine.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cell * 0.06;
    for (var band = 0; band < 6; band++) {
      final baseY = size.y * (0.10 + band * 0.155);
      final path = Path()..moveTo(0, baseY);
      final amplitude = _cell * (0.18 + band * 0.03);
      const segments = 5;
      for (var i = 1; i <= segments; i++) {
        final x = size.x * i / segments;
        final previousX = size.x * (i - 1) / segments;
        final y = baseY + amplitude * math.sin(i * 1.7 + band);
        path.quadraticBezierTo((previousX + x) / 2, y - amplitude * 0.8, x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawCoords(Canvas canvas) {
    final painters = _coordPainters ??= [
      for (var index = 0; index < boardSize; index++)
        _coordPainter(String.fromCharCode(65 + index)),
      for (var index = 0; index < boardSize; index++)
        _coordPainter('${index + 1}'),
    ];
    for (var index = 0; index < boardSize; index++) {
      final columnPainter = painters[index];
      columnPainter.paint(
        canvas,
        Offset(
          _originX + index * _cell - columnPainter.width / 2,
          _originY + (boardSize - 1) * _cell + _cell * 0.72,
        ),
      );
      final rowPainter = painters[boardSize + index];
      rowPainter.paint(
        canvas,
        Offset(
          _originX - _cell * 0.72 - rowPainter.width / 2,
          _originY + index * _cell - rowPainter.height / 2,
        ),
      );
    }
  }

  TextPainter _coordPainter(String text) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: math.max(7, _cell * 0.34),
        color: kBoardLine.withValues(alpha: 0.55),
        fontWeight: FontWeight.w500,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  ui.Picture _stonePicture() {
    final key = Object.hash(
      _layoutToken,
      view.history.length,
      view.lastIndex,
      _anim?.index,
    );
    return _stoneLayer.paint(key, (canvas) {
      final radius = _cell * 0.46;
      final animating = _anim?.index;
      for (var index = 0; index < cellCount; index++) {
        final side = view.cells[index];
        if (side == empty) continue;
        if (index == animating) continue;
        paintStoneDisc(
          canvas,
          center: _centerOf(index),
          radius: radius,
          face: faceOf(side),
        );
      }
    });
  }

  void _drawAnim(Canvas canvas) {
    final anim = _anim;
    if (anim == null) return;
    final progress = (anim.elapsed / _animDuration).clamp(0.0, 1.0);
    final center = _centerOf(anim.index);
    final radius = _cell * 0.46;
    final scale = 0.62 + 0.38 * Curves.easeOutBack.transform(progress);
    paintStoneDisc(
      canvas,
      center: center,
      radius: radius * scale,
      face: faceOf(anim.side),
      opacity: math.min(1, progress * 4),
      highlight: progress > 0.6,
    );
    _stroke
      ..strokeWidth = math.max(1, _cell * 0.035)
      ..color = kBoardAccent.withValues(alpha: (1 - progress) * 0.45);
    canvas.drawCircle(center, radius * (1 + progress * 0.9), _stroke);
  }

  void _drawLastMarker(Canvas canvas) {
    final index = view.lastIndex;
    if (index == null || _anim != null) return;
    final side = view.cells[index];
    if (side == empty) return;
    _fill.color = side == black
        ? kWhiteStone.light.withValues(alpha: 0.92)
        : kBlackStone.dark.withValues(alpha: 0.8);
    canvas.drawCircle(_centerOf(index), _cell * 0.46 * 0.16, _fill);
  }

  void _drawHint(Canvas canvas) {
    final index = view.hintIndex;
    if (index == null || view.cells[index] != empty) return;
    final center = _centerOf(index);
    final radius = _cell * 0.46;
    final pulse = 0.92 + 0.08 * math.sin(_time * 4.2);
    _stroke
      ..strokeWidth = math.max(1.4, _cell * 0.05)
      ..color = kBoardAccent.withValues(alpha: 0.85);
    canvas.drawCircle(center, radius * 0.78 * pulse, _stroke);
    _fill.color = kBoardAccent.withValues(alpha: 0.7);
    canvas.drawCircle(center, radius * 0.22, _fill);
  }

  /// 禁手点：细红圈加斜杠，与提示圆环区分。
  void _drawForbidden(Canvas canvas) {
    final points = view.forbiddenPoints;
    if (points.isEmpty) return;
    _stroke
      ..strokeWidth = math.max(1.1, _cell * 0.042)
      ..color = const Color(0xFFB23A2B).withValues(alpha: 0.62);
    for (final index in points) {
      final center = _centerOf(index);
      final radius = _cell * 0.30;
      canvas.drawCircle(center, radius, _stroke);
      final offset = radius * 0.68;
      canvas.drawLine(
        center + Offset(-offset, -offset),
        center + Offset(offset, offset),
        _stroke,
      );
    }
  }

  void _drawHover(Canvas canvas) {
    final index = _hoverIndex;
    if (index == null || view.cells[index] != empty) return;
    if (!view.canInteract) return;
    paintStoneDisc(
      canvas,
      center: _centerOf(index),
      radius: _cell * 0.46,
      face: faceOf(view.sideToMove),
      opacity: 0.34,
      highlight: false,
    );
  }

  void _drawWinningLine(Canvas canvas) {
    final line = view.winningLine;
    if (line.length < 2) return;
    final start = _centerOf(line.first);
    final end = _centerOf(line.last);
    final pulse = 0.75 + 0.25 * math.sin(_time * 3.2);
    _stroke
      ..strokeWidth = _cell * 0.5
      ..color = kBoardAccent.withValues(alpha: 0.16 * pulse);
    canvas.drawLine(start, end, _stroke);
    _stroke
      ..strokeWidth = math.max(2, _cell * 0.11)
      ..color = kBoardAccent.withValues(alpha: 0.9 * pulse);
    canvas.drawLine(start, end, _stroke);
    _fill.color = kBoardAccent.withValues(alpha: 0.9);
    for (final index in [line.first, line.last]) {
      canvas.drawCircle(_centerOf(index), _cell * 0.2, _fill);
    }
  }
}

class _StoneAnim {
  _StoneAnim({required this.index, required this.side});

  final int index;
  final int side;
  double elapsed = 0;
}

/// 按 key 缓存的录制图层，key 变化时释放旧图片并重新录制。
class _PictureLayer {
  ui.Picture? _picture;
  int? _key;

  ui.Picture paint(int key, void Function(Canvas canvas) draw) {
    final cached = _picture;
    if (cached != null && _key == key) return cached;
    _picture?.dispose();
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final picture = recorder.endRecording();
    _picture = picture;
    _key = key;
    return picture;
  }

  void clear() {
    _picture?.dispose();
    _picture = null;
    _key = null;
  }
}
