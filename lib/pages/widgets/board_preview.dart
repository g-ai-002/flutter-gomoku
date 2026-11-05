import 'package:flutter/material.dart';

import '../../theme/board_painting.dart';
import '../../theme/board_skin.dart';

/// 首页装饰：一张缩小的 15 路棋盘，黑白各两子，使用统一棋盘配色。
class BoardPreview extends StatelessWidget {
  const BoardPreview({super.key, this.skin = kDefaultBoardSkin});

  final BoardSkin skin;

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
        size: const Size(172, 172),
        painter: _BoardPreviewPainter(skin: skin),
      ),
    );
  }
}

class _BoardPreviewPainter extends CustomPainter {
  const _BoardPreviewPainter({required this.skin});

  final BoardSkin skin;

  /// 预览用的几手棋：黑白交替，落在天元附近。
  static const List<(int, int, int)> _stones = [
    (7, 7, 1),
    (8, 8, 2),
    (6, 8, 1),
    (8, 6, 2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, Paint()..shader = skin.gradient.createShader(rect));

    const pad = 14.0;
    final cell = (size.width - pad * 2) / 14;
    final top = (size.height - cell * 14) / 2;

    paintBoardGrid(
      canvas,
      topLeft: Offset(pad, top),
      cell: cell,
      linePaint: Paint()
        ..color = skin.line.withValues(alpha: 0.55)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke,
      starPaint: Paint()..color = skin.line.withValues(alpha: 0.75),
      borderPaint: Paint()
        ..color = skin.line.withValues(alpha: 0.55)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    for (final (row, col, side) in _stones) {
      paintStoneDisc(
        canvas,
        center: Offset(pad + col * cell, top + row * cell),
        radius: cell * 0.44,
        face: skin.faceOf(side),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPreviewPainter oldDelegate) =>
      oldDelegate.skin != skin;
}
