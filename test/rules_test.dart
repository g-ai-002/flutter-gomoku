import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/engine/rules.dart';

void _place(Uint8List cells, int side, List<(int, int)> points) {
  for (final (row, col) in points) {
    cells[indexOf(row, col)] = side;
  }
}

void main() {
  group('五连判定', () {
    test('横向五连', () {
      final cells = emptyCells();
      _place(cells, black, [(7, 3), (7, 4), (7, 5), (7, 6), (7, 7)]);
      final line = GomokuRules.winningLineAt(cells, indexOf(7, 5), black);
      expect(line.length, 5);
      expect(GomokuRules.hasFive(cells, indexOf(7, 5), black), isTrue);
      expect(line, containsAll([indexOf(7, 3), indexOf(7, 7)]));
    });

    test('纵向五连', () {
      final cells = emptyCells();
      _place(cells, white, [(2, 6), (3, 6), (4, 6), (5, 6), (6, 6)]);
      expect(GomokuRules.hasFive(cells, indexOf(4, 6), white), isTrue);
      expect(GomokuRules.winningLineAt(cells, indexOf(6, 6), white).length, 5);
    });

    test('主对角线五连', () {
      final cells = emptyCells();
      _place(cells, black, [(3, 3), (4, 4), (5, 5), (6, 6), (7, 7)]);
      expect(GomokuRules.hasFive(cells, indexOf(5, 5), black), isTrue);
    });

    test('副对角线五连', () {
      final cells = emptyCells();
      _place(cells, black, [(3, 11), (4, 10), (5, 9), (6, 8), (7, 7)]);
      expect(GomokuRules.hasFive(cells, indexOf(5, 9), black), isTrue);
    });

    test('长连同样计胜，连线包含全部棋子', () {
      final cells = emptyCells();
      _place(cells, black, [(7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 7)]);
      expect(GomokuRules.hasFive(cells, indexOf(7, 4), black), isTrue);
      expect(GomokuRules.winningLineAt(cells, indexOf(7, 4), black).length, 6);
    });

    test('四连不算胜', () {
      final cells = emptyCells();
      _place(cells, black, [(7, 3), (7, 4), (7, 5), (7, 6)]);
      expect(GomokuRules.hasFive(cells, indexOf(7, 5), black), isFalse);
      expect(GomokuRules.winningLineAt(cells, indexOf(7, 5), black), isEmpty);
    });

    test('异色棋子阻断连线', () {
      final cells = emptyCells();
      _place(cells, black, [(7, 3), (7, 4), (7, 6), (7, 7)]);
      cells[indexOf(7, 5)] = white;
      expect(GomokuRules.hasFive(cells, indexOf(7, 4), black), isFalse);
    });

    test('非本方形棋子不参与判定', () {
      final cells = emptyCells();
      _place(cells, black, [(7, 3), (7, 4), (7, 5), (7, 6), (7, 7)]);
      expect(GomokuRules.hasFive(cells, indexOf(7, 5), white), isFalse);
      expect(GomokuRules.winningLineAt(cells, indexOf(7, 5), white), isEmpty);
    });
  });

  group('战术与候选点', () {
    test('四连两端都是立即获胜点', () {
      final cells = emptyCells();
      _place(cells, black, [(7, 3), (7, 4), (7, 5), (7, 6)]);
      final wins = GomokuRules.immediateWins(cells, black);
      expect(wins.length, 2);
      expect(wins, containsAll([indexOf(7, 2), indexOf(7, 7)]));
      expect(
        GomokuRules.immediateWin(cells, black),
        anyOf(indexOf(7, 2), indexOf(7, 7)),
      );
    });

    test('没有立即获胜点时返回 null', () {
      final cells = emptyCells();
      _place(cells, black, [(7, 3), (7, 4), (7, 5)]);
      expect(GomokuRules.immediateWins(cells, black), isEmpty);
      expect(GomokuRules.immediateWin(cells, black), isNull);
    });

    test('战术兜底优先自己成五，其次封堵对手', () {
      final cells = emptyCells();
      _place(cells, black, [(7, 3), (7, 4), (7, 5), (7, 6)]);
      _place(cells, white, [(9, 3), (9, 4), (9, 5), (9, 6)]);
      expect(
        GomokuRules.tacticalMove(cells, black),
        anyOf(indexOf(7, 2), indexOf(7, 7)),
      );
      expect(
        GomokuRules.tacticalMove(cells, white),
        anyOf(indexOf(9, 2), indexOf(9, 7)),
      );
    });

    test('自己无胜点时封堵对手成五', () {
      final cells = emptyCells();
      _place(cells, black, [(7, 3), (7, 4), (7, 5)]);
      _place(cells, white, [(9, 3), (9, 4), (9, 5), (9, 6)]);
      expect(
        GomokuRules.tacticalMove(cells, black),
        anyOf(indexOf(9, 2), indexOf(9, 7)),
      );
    });

    test('复用候选点不改变棋盘', () {
      final cells = emptyCells();
      _place(cells, black, [(7, 3), (7, 4), (7, 5), (7, 6)]);
      final before = Uint8List.fromList(cells);
      final candidates = GomokuRules.candidateMoves(cells);
      final wins = GomokuRules.immediateWins(
        cells,
        black,
        candidates: candidates,
      );
      expect(wins, hasLength(2));
      expect(cells, before);
    });

    test('空盘的候选点是天元', () {
      final cells = emptyCells();
      expect(GomokuRules.candidateMoves(cells), [centerIndex]);
    });

    test('候选点限定在棋子周围两格', () {
      final cells = emptyCells();
      cells[indexOf(7, 7)] = black;
      final moves = GomokuRules.candidateMoves(cells);
      expect(moves.length, 24);
      expect(moves, isNot(contains(indexOf(7, 7))));
      expect(moves, contains(indexOf(5, 5)));
      expect(moves, isNot(contains(indexOf(4, 4))));
    });

    test('角落棋子的候选点不会越界', () {
      final cells = emptyCells();
      cells[indexOf(0, 0)] = black;
      final moves = GomokuRules.candidateMoves(cells);
      expect(moves.length, 8);
      for (final index in moves) {
        expect(index, inInclusiveRange(0, indexOf(2, 2)));
        expect(rowOf(index), lessThan(3));
        expect(colOf(index), lessThan(3));
      }
    });

    test('贴边四连不算活四', () {
      final cells = emptyCells();
      _place(cells, black, [(0, 4), (1, 4), (2, 4), (3, 4)]);
      expect(GomokuRules.makesOpenFour(cells, indexOf(3, 4), black), isFalse);
      expect(GomokuRules.hasFive(cells, indexOf(3, 4), black), isFalse);
      expect(GomokuRules.winningLineAt(cells, indexOf(3, 4), black), isEmpty);
    });

    test('四子两端皆空时为活四', () {
      final cells = emptyCells();
      _place(cells, black, [(7, 3), (7, 4), (7, 5)]);
      cells[indexOf(7, 6)] = black;
      expect(GomokuRules.makesOpenFour(cells, indexOf(7, 6), black), isTrue);
    });

    test('一端被堵时不是活四', () {
      final cells = emptyCells();
      _place(cells, black, [(7, 3), (7, 4), (7, 5), (7, 6)]);
      cells[indexOf(7, 7)] = white;
      expect(GomokuRules.makesOpenFour(cells, indexOf(7, 6), black), isFalse);
    });

    test('棋盘下满时判定满盘', () {
      final cells = emptyCells();
      for (var index = 0; index < cellCount; index++) {
        cells[index] = index.isEven ? black : white;
      }
      expect(GomokuRules.candidateMoves(cells), isEmpty);
    });
  });
}
