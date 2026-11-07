import 'package:flutter/material.dart';

import '../../game/engine/board_utils.dart';
import '../../theme/board_painting.dart';
import '../../theme/board_skin.dart';

/// 首页装饰：一张缩小的 15 路棋盘，黑白各两子，使用统一棋盘配色。
class BoardPreview extends StatelessWidget {
  const BoardPreview({super.key, this.side = 172});

  /// 预览边长，横屏分栏时收窄以给入口列表让出高度。
  final double side;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size.square(side),
        painter: const _BoardPreviewPainter(),
      ),
    );
  }
}

class _BoardPreviewPainter extends CustomPainter {
  const _BoardPreviewPainter();

  /// 预览用的几手棋：黑白交替，落在天元附近。
  static const List<int> _stones = [112, 128, 98, 126];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..shader = kBoardGradient.createShader(rect),
    );

    const pad = 14.0;
    final cell = (size.width - pad * 2) / 14;
    final origin = Offset(pad, (size.height - cell * 14) / 2);
    paintBoardGrid(
      canvas,
      topLeft: origin,
      cell: cell,
      linePaint: Paint()
        ..color = kBoardLine.withValues(alpha: 0.55)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke,
      starPaint: Paint()..color = kBoardLine.withValues(alpha: 0.75),
      borderPaint: Paint()
        ..color = kBoardLine.withValues(alpha: 0.55)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < _stones.length; i++) {
      final index = _stones[i];
      paintStoneDisc(
        canvas,
        center: origin + Offset(colOf(index) * cell, rowOf(index) * cell),
        radius: cell * 0.44,
        face: faceOf(i.isEven ? black : white),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPreviewPainter oldDelegate) => false;
}
