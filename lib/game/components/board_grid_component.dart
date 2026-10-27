import 'dart:ui';

import '../gomoku_board_geometry.dart';
import 'board_layer_component.dart';

/// 棋盘背景、网格线与星位。
///
/// 这些元素只随尺寸、棋盘大小与配色变化，因此整块烘焙成 [Picture] 缓存，
/// 每帧只做一次 `drawPicture`，避免重复画几十条线与星位。
class BoardGridComponent extends BoardLayerComponent {
  BoardGridComponent({
    required super.source,
    required super.palette,
    super.priority,
  });

  Picture? _picture;
  double _bakedWidth = 0;
  double _bakedHeight = 0;
  int _bakedBoardSize = 0;
  Color? _bakedBoardColor;
  Color? _bakedLineColor;
  Color? _bakedBorderColor;

  @override
  void render(Canvas canvas) {
    canvas.drawPicture(_bakedPicture());
  }

  @override
  void onRemove() {
    _disposePicture();
    super.onRemove();
  }

  bool get _dirty =>
      _picture == null ||
      _bakedWidth != size.x ||
      _bakedHeight != size.y ||
      _bakedBoardSize != source.boardSize ||
      _bakedBoardColor != palette.boardColor ||
      _bakedLineColor != palette.lineColor ||
      _bakedBorderColor != palette.borderColor;

  Picture _bakedPicture() {
    if (!_dirty) return _picture!;
    _disposePicture();
    final picture = _bake(size.x, size.y);
    _picture = picture;
    _bakedWidth = size.x;
    _bakedHeight = size.y;
    _bakedBoardSize = source.boardSize;
    _bakedBoardColor = palette.boardColor;
    _bakedLineColor = palette.lineColor;
    _bakedBorderColor = palette.borderColor;
    return picture;
  }

  /// 按 worldSize 坐标绘制后整体缩放到组件尺寸（正常情况为 1:1）。
  Picture _bake(double width, double height) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    const worldSize = GomokuBoardGeometry.worldSize;
    if (width != worldSize || height != worldSize) {
      canvas.scale(width / worldSize, height / worldSize);
    }

    final g = geometry;
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, worldSize, worldSize),
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

    return recorder.endRecording();
  }

  void _disposePicture() {
    _picture?.dispose();
    _picture = null;
  }
}
