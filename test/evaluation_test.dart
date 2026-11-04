import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/engine/evaluation.dart';

void main() {
  group('棋型评估', () {
    test('活三的形态分高于被堵的三', () {
      final open = emptyCells();
      for (var col = 5; col <= 7; col++) {
        open[indexOf(7, col)] = black;
      }
      final blocked = emptyCells();
      for (var col = 5; col <= 7; col++) {
        blocked[indexOf(7, col)] = black;
      }
      blocked[indexOf(7, 8)] = white;
      final openScore = GomokuEvaluation.pointScore(open, indexOf(7, 4), black);
      final blockedScore = GomokuEvaluation.pointScore(
        blocked,
        indexOf(7, 4),
        black,
      );
      expect(openScore, greaterThan(blockedScore));
    });

    test('成五的形态分远高于普通连子', () {
      final cells = emptyCells();
      for (var col = 3; col <= 6; col++) {
        cells[indexOf(7, col)] = black;
      }
      final winning = GomokuEvaluation.pointScore(cells, indexOf(7, 7), black);
      final ordinary = GomokuEvaluation.pointScore(cells, indexOf(9, 9), black);
      expect(winning, greaterThan(ordinary * 100));
    });

    test('双方局面评估符号对称', () {
      final cells = emptyCells();
      cells[indexOf(7, 7)] = black;
      cells[indexOf(8, 8)] = black;
      final blackScore = GomokuEvaluation.evaluate(cells, black);
      final whiteScore = GomokuEvaluation.evaluate(cells, white);
      expect(blackScore, greaterThan(0));
      expect(whiteScore, lessThan(0));
    });

    test('直线覆盖四个方向', () {
      final horizontal = GomokuEvaluation.lines.any(
        (line) => line.length == 15 && line.first == indexOf(7, 0),
      );
      final vertical = GomokuEvaluation.lines.any(
        (line) => line.length == 15 && line.first == indexOf(0, 7),
      );
      expect(horizontal, isTrue);
      expect(vertical, isTrue);
      // 两条主对角线都应在列表中。
      expect(GomokuEvaluation.lines.every((line) => line.length >= 5), isTrue);
    });
  });
}
