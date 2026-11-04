import 'package:flutter/material.dart';

import '../../game/opening_book.dart';
import '../../theme/board_painting.dart';
import '../../theme/board_skin.dart';

/// 开局缩略图：按顺序绘制开局前几手，并在棋子上标注手数。
class OpeningPreview extends StatelessWidget {
  const OpeningPreview({
    super.key,
    required this.line,
    this.skin = kDefaultBoardSkin,
    this.size = 132,
  });

  final OpeningLine line;
  final BoardSkin skin;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _OpeningPainter(line: line, skin: skin),
      ),
    );
  }
}

class _OpeningPainter extends CustomPainter {
  const _OpeningPainter({required this.line, required this.skin});

  final OpeningLine line;
  final BoardSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rrect, Paint()..shader = skin.gradient.createShader(rect));

    const pad = 12.0;
    final cell = (size.width - pad * 2) / 14;
    final top = (size.height - cell * 14) / 2;
    final topLeft = Offset(pad, top);

    paintBoardGrid(
      canvas,
      topLeft: topLeft,
      cell: cell,
      linePaint: Paint()
        ..color = skin.line.withValues(alpha: 0.5)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke,
      starPaint: Paint()..color = skin.line.withValues(alpha: 0.6),
      borderPaint: Paint()
        ..color = skin.line.withValues(alpha: 0.65)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    for (var i = 0; i < line.moves.length; i++) {
      final index = line.moves[i];
      final row = index ~/ 15;
      final col = index % 15;
      final center = Offset(topLeft.dx + col * cell, topLeft.dy + row * cell);
      paintStoneDisc(
        canvas,
        center: center,
        radius: cell * 0.44,
        face: skin.faceOf(i.isEven ? 1 : 2),
      );
      final painter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            fontSize: cell * 0.52,
            fontWeight: FontWeight.w700,
            color: i.isEven ? skin.whiteStone.light : skin.blackStone.dark,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        center - Offset(painter.width / 2, painter.height / 2),
      );
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _OpeningPainter oldDelegate) =>
      oldDelegate.line.id != line.id || oldDelegate.skin != skin;
}
