import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gomoku/game/gomoku_board_geometry.dart';
import 'package:flutter_gomoku/models/game_state.dart';

void main() {
  group('GomokuBoardGeometry', () {
    test('棋盘居中且交叉点间距一致', () {
      for (final size in [9, 13, 15, 19]) {
        final g = GomokuBoardGeometry.forBoard(size);
        final first = g.centerOf(0, 0);
        final last = g.centerOf(size - 1, size - 1);
        expect(first.dx, closeTo(first.dy, 1e-9));
        expect(
          GomokuBoardGeometry.worldSize - last.dx,
          closeTo(first.dx, 1e-9),
        );
        expect(
          last.dx - first.dx,
          closeTo(g.cellSize * (size - 1), 1e-9),
        );
      }
    });

    test('点击换算吸附到最近交叉点', () {
      final g = GomokuBoardGeometry.forBoard(15);
      final center = g.centerOf(6, 8);
      expect(
        g.positionAt(center + Offset(g.cellSize * 0.4, -g.cellSize * 0.4)),
        const Position(6, 8),
      );
    });

    test('棋盘外的点击不落子', () {
      final g = GomokuBoardGeometry.forBoard(15);
      expect(g.positionAt(const Offset(1, 1)), isNull);
      expect(
        g.positionAt(const Offset(
          GomokuBoardGeometry.worldSize + 20,
          GomokuBoardGeometry.worldSize + 20,
        )),
        isNull,
      );
    });

    test('星位数量随棋盘尺寸变化', () {
      expect(GomokuBoardGeometry.forBoard(15).starPoints.length, 9);
      expect(GomokuBoardGeometry.forBoard(19).starPoints.length, 9);
      expect(GomokuBoardGeometry.forBoard(9).starPoints.length, 5);
    });
  });
}
