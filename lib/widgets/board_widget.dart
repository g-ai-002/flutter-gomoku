import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'board_painter.dart';

/// 棋盘组件
class BoardWidget extends StatefulWidget {
  const BoardWidget({super.key});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _lastHistoryLength = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final state = game.state;
    final boardSize = state.boardSize;

    // 检测新落子，触发动画
    if (state.history.length > _lastHistoryLength) {
      _animController.forward(from: 0);
    }
    _lastHistoryLength = state.history.length;

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
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(maxSize, maxSize),
                painter: BoardPainter(
                  boardSize: boardSize,
                  cellSize: cellSize,
                  padding: padding,
                  board: state.board,
                  lastMove: state.lastMove,
                  winStart: state.winStart,
                  winEnd: state.winEnd,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  stoneAnimProgress: _animController.value,
                  isGameOver: state.status != GameStatus.playing,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
