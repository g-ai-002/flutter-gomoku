import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'package:provider/provider.dart';

/// 棋盘组件
class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final state = game.state;
    final boardSize = state.boardSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = constraints.maxWidth;
        final cellSize = (maxSize - 16) / boardSize;
        final boardPixelSize = cellSize * (boardSize - 1);
        final padding = (maxSize - boardPixelSize) / 2;

        return GestureDetector(
          onTapUp: (details) {
            if (state.status != GameStatus.playing) return;
            final col = ((details.localPosition.dx - padding + cellSize / 2) / cellSize).round();
            final row = ((details.localPosition.dy - padding + cellSize / 2) / cellSize).round();
            if (row >= 0 && row < boardSize && col >= 0 && col < boardSize) {
              game.placeStone(row, col);
            }
          },
          child: CustomPaint(
            size: Size(maxSize, maxSize),
            painter: _BoardPainter(
              boardSize: boardSize,
              cellSize: cellSize,
              padding: padding,
              board: state.board,
              lastMove: state.lastMove,
              winStart: state.winStart,
              winEnd: state.winEnd,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  final int boardSize;
  final double cellSize;
  final double padding;
  final List<List<StoneColor?>> board;
  final Position? lastMove;
  final Position? winStart;
  final Position? winEnd;
  final bool isDark;

  _BoardPainter({
    required this.boardSize,
    required this.cellSize,
    required this.padding,
    required this.board,
    this.lastMove,
    this.winStart,
    this.winEnd,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoard(canvas);
    _drawStones(canvas);
  }

  void _drawBoard(Canvas canvas) {
    final linePaint = Paint()
      ..color = isDark ? const Color(0xFF5A5A5A) : const Color(0xFF8D6E63)
      ..strokeWidth = 0.8;

    final starPaint = Paint()
      ..color = isDark ? const Color(0xFF5A5A5A) : const Color(0xFF8D6E63);

    // 画网格线
    for (int i = 0; i < boardSize; i++) {
      final offset = padding + i * cellSize;
      canvas.drawLine(
        Offset(padding, offset),
        Offset(padding + (boardSize - 1) * cellSize, offset),
        linePaint,
      );
      canvas.drawLine(
        Offset(offset, padding),
        Offset(offset, padding + (boardSize - 1) * cellSize),
        linePaint,
      );
    }

    // 画星位
    final starPoints = _getStarPoints();
    for (final (r, c) in starPoints) {
      canvas.drawCircle(
        Offset(padding + c * cellSize, padding + r * cellSize),
        3,
        starPaint,
      );
    }
  }

  List<(int, int)> _getStarPoints() {
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
    // 其他大小：四角和中心
    final c = boardSize ~/ 2;
    final e = boardSize - 4;
    return [(3, 3), (3, e), (e, 3), (e, e), (c, c)];
  }

  void _drawStones(Canvas canvas) {
    final radius = cellSize * 0.43;

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final stone = board[r][c];
        if (stone == null) continue;

        final center = Offset(padding + c * cellSize, padding + r * cellSize);

        // 阴影
        final shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(center + const Offset(1, 1.5), radius, shadowPaint);

        // 棋子主体
        final gradient = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: stone == StoneColor.black
              ? [const Color(0xFF555555), const Color(0xFF111111)]
              : [const Color(0xFFFFFFFF), const Color(0xFFCCCCCC)],
        );

        final stonePaint = Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: radius),
          );

        canvas.drawCircle(center, radius, stonePaint);

        // 边框
        final borderPaint = Paint()
          ..color = stone == StoneColor.black
              ? const Color(0xFF333333)
              : const Color(0xFFAAAAAA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawCircle(center, radius, borderPaint);

        // 最后落子标记
        if (lastMove != null && lastMove!.row == r && lastMove!.col == c) {
          final markPaint = Paint()
            ..color = stone == StoneColor.black
                ? const Color(0xFFFF5252)
                : const Color(0xFFFF5252)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawCircle(center, radius * 0.35, markPaint);
        }
      }
    }

    // 获胜连线高亮
    if (winStart != null && winEnd != null) {
      _drawWinLine(canvas);
    }
  }

  void _drawWinLine(Canvas canvas) {
    final start = Offset(
      padding + winStart!.col * cellSize,
      padding + winStart!.row * cellSize,
    );
    final end = Offset(
      padding + winEnd!.col * cellSize,
      padding + winEnd!.row * cellSize,
    );

    final paint = Paint()
      ..color = const Color(0xFFFF5252)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
