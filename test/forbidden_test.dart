import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/board_state.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/engine/forbidden.dart';
import 'package:gomoku/game/engine/search.dart';

Uint8List _cells(
  Iterable<(int, int)> blackPoints, [
  Iterable<(int, int)> whitePoints = const [],
]) {
  final cells = emptyCells();
  for (final (row, col) in blackPoints) {
    cells[indexOf(row, col)] = black;
  }
  for (final (row, col) in whitePoints) {
    cells[indexOf(row, col)] = white;
  }
  return cells;
}

void main() {
  group('禁手判定', () {
    test('六子长连判为禁手', () {
      final cells = _cells([for (var col = 3; col <= 7; col++) (7, col)]);
      expect(
        GomokuForbidden.at(cells, indexOf(7, 8)),
        ForbiddenReason.overline,
      );
    });

    test('中间补成六子同样判为禁手', () {
      final cells = _cells([
        for (var col = 3; col <= 5; col++) (7, col),
        for (var col = 7; col <= 9; col++) (7, col),
      ]);
      expect(
        GomokuForbidden.at(cells, indexOf(7, 6)),
        ForbiddenReason.overline,
      );
    });

    test('活四只算一个四', () {
      final cells = _cells([for (var col = 4; col <= 6; col++) (7, col)]);
      expect(GomokuForbidden.at(cells, indexOf(7, 7)), isNull);
    });

    test('横竖同时成四判为四四', () {
      final cells = _cells([
        for (var col = 4; col <= 6; col++) (7, col),
        for (var row = 4; row <= 6; row++) (row, 7),
      ]);
      expect(
        GomokuForbidden.at(cells, indexOf(7, 7)),
        ForbiddenReason.doubleFour,
      );
    });

    test('横竖同时成活三判为三三', () {
      final cells = _cells([
        for (var col = 5; col <= 6; col++) (7, col),
        for (var row = 5; row <= 6; row++) (row, 7),
      ]);
      expect(
        GomokuForbidden.at(cells, indexOf(7, 7)),
        ForbiddenReason.doubleThree,
      );
    });

    test('单条活三合法', () {
      final cells = _cells([for (var col = 5; col <= 6; col++) (7, col)]);
      expect(GomokuForbidden.at(cells, indexOf(7, 7)), isNull);
    });

    test('被白棋封住一端的眠三不计入', () {
      final cells = _cells(
        [for (var col = 5; col <= 6; col++) (7, col)],
        [(7, 4)],
      );
      expect(GomokuForbidden.at(cells, indexOf(7, 7)), isNull);
    });

    test('成五优先于四四', () {
      final cells = _cells([
        for (var col = 3; col <= 6; col++) (7, col),
        for (var row = 4; row <= 6; row++) (row, 7),
      ]);
      expect(GomokuForbidden.at(cells, indexOf(7, 7)), isNull);
    });

    test('已有棋子不参与判定', () {
      final cells = _cells([(7, 6)]);
      expect(GomokuForbidden.at(cells, indexOf(7, 6)), isNull);
    });

    test('禁手点集合覆盖候选点', () {
      final cells = _cells([for (var col = 3; col <= 7; col++) (7, col)]);
      expect(GomokuForbidden.points(cells), contains(indexOf(7, 8)));
    });

    test('搜索开启禁手后回避长连点', () {
      final cells = _cells([
        for (final col in [3, 4, 5, 7, 8]) (7, col),
      ]);
      final free = GomokuSearch.bestMove(
        cells: cells,
        side: black,
        depth: 1,
        timeLimitMillis: 500,
      );
      expect(free.move, indexOf(7, 6));
      final legal = GomokuSearch.bestMove(
        cells: cells,
        side: black,
        depth: 1,
        timeLimitMillis: 500,
        forbidBlack: true,
      );
      expect(legal.move, isNot(indexOf(7, 6)));
    });

    test('禁手规则下 AI 对弈全程不落禁手', () {
      final board = GomokuBoard(forbidBlack: true);
      final random = math.Random(7);
      for (var ply = 0; ply < 16; ply++) {
        final reply = GomokuSearch.bestMove(
          cells: board.cells,
          side: board.sideToMove,
          depth: 2,
          timeLimitMillis: 200,
          forbidBlack: true,
          random: random,
        );
        expect(reply.move, greaterThanOrEqualTo(0));
        expect(board.forbiddenAt(reply.move), isNull);
        expect(board.apply(reply.move), isNotNull);
        if (board.winner != null || board.isFull) break;
      }
      expect(board.history.length, greaterThan(4));
    });

    test('黑棋过滤禁手着法，白棋不受限制', () {
      final cells = _cells([for (var col = 3; col <= 7; col++) (7, col)]);
      final moves = [indexOf(7, 8), indexOf(6, 6)];
      expect(GomokuForbidden.legalMoves(cells, black, moves), [indexOf(6, 6)]);
      expect(GomokuForbidden.legalMoves(cells, white, moves), moves);
    });
  });
}
