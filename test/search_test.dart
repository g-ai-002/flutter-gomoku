import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/engine/rules.dart';
import 'package:gomoku/game/engine/search.dart';

void _put(Uint8List cells, int side, List<(int, int)> points) {
  for (final (row, col) in points) {
    cells[indexOf(row, col)] = side;
  }
}

void main() {
  group('AI 搜索', () {
    test('空盘第一手落在天元', () {
      final result = GomokuSearch.bestMove(
        cells: emptyCells(),
        side: black,
        depth: 2,
        timeLimitMillis: 1000,
      );
      expect(result.move, centerIndex);
    });

    test('发现自己的五连并立即成五', () {
      final cells = emptyCells();
      _put(cells, black, [(7, 3), (7, 4), (7, 5), (7, 6)]);
      final result = GomokuSearch.bestMove(
        cells: cells,
        side: black,
        depth: 3,
        timeLimitMillis: 1000,
      );
      expect(result.move, anyOf(indexOf(7, 2), indexOf(7, 7)));
      cells[result.move] = black;
      expect(GomokuRules.hasFive(cells, result.move, black), isTrue);
    });

    test('优先成五而非封堵对手', () {
      final cells = emptyCells();
      _put(cells, black, [(7, 3), (7, 4), (7, 5), (7, 6)]);
      _put(cells, white, [(9, 3), (9, 4), (9, 5), (9, 6)]);
      final result = GomokuSearch.bestMove(
        cells: cells,
        side: black,
        depth: 2,
        timeLimitMillis: 1000,
      );
      cells[result.move] = black;
      expect(GomokuRules.hasFive(cells, result.move, black), isTrue);
    });

    test('封堵对手的立即成五', () {
      final cells = emptyCells();
      _put(cells, white, [(7, 3), (7, 4), (7, 5), (7, 6)]);
      final result = GomokuSearch.bestMove(
        cells: cells,
        side: black,
        depth: 3,
        timeLimitMillis: 1500,
      );
      expect(result.move, anyOf(indexOf(7, 2), indexOf(7, 7)));
      expect(result.nodes, greaterThan(0));
    });

    test('中局返回合法空点', () {
      final cells = emptyCells();
      _put(cells, black, [(7, 7), (8, 8), (6, 8), (9, 9)]);
      _put(cells, white, [(7, 8), (8, 7), (6, 7), (9, 8)]);
      final result = GomokuSearch.bestMove(
        cells: cells,
        side: white,
        depth: 3,
        timeLimitMillis: 2000,
      );
      expect(result.move, isNot(-1));
      expect(cells[result.move], empty);
      expect(result.depth, greaterThan(0));
    });

    test('遵守思考时限', () {
      final cells = emptyCells();
      _put(cells, black, [(7, 7), (8, 8), (6, 8), (9, 9), (5, 5)]);
      _put(cells, white, [(7, 8), (8, 7), (6, 7), (9, 8), (5, 6)]);
      final watch = Stopwatch()..start();
      final result = GomokuSearch.bestMove(
        cells: cells,
        side: black,
        depth: 8,
        timeLimitMillis: 200,
      );
      watch.stop();
      expect(result.move, isNot(-1));
      expect(watch.elapsedMilliseconds, lessThan(3000));
    });

    test('满盘无子可落时返回 -1', () {
      final cells = emptyCells();
      for (var index = 0; index < cellCount; index++) {
        cells[index] = index.isEven ? black : white;
      }
      final result = GomokuSearch.bestMove(
        cells: cells,
        side: black,
        depth: 1,
        timeLimitMillis: 200,
      );
      expect(result.move, -1);
    });
  });
}
