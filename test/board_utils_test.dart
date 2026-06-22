import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gomoku/models/game_state.dart';
import 'package:flutter_gomoku/utils/board_utils.dart';

void main() {
  group('BoardUtils.checkWin', () {
    List<List<StoneColor?>> _emptyBoard(int size) =>
        List.generate(size, (_) => List.filled(size, null));

    test('空棋盘无获胜', () {
      final board = _emptyBoard(15);
      final result = BoardUtils.checkWin(board, const Position(7, 7));
      expect(result, isNull);
    });

    test('水平五连获胜', () {
      final board = _emptyBoard(15);
      for (int c = 3; c <= 7; c++) {
        board[7][c] = StoneColor.black;
      }
      final result = BoardUtils.checkWin(board, const Position(7, 5));
      expect(result, isNotNull);
      expect(result!.$1, equals(const Position(7, 3)));
      expect(result.$2, equals(const Position(7, 7)));
    });

    test('垂直五连获胜', () {
      final board = _emptyBoard(15);
      for (int r = 2; r <= 6; r++) {
        board[r][4] = StoneColor.white;
      }
      final result = BoardUtils.checkWin(board, const Position(4, 4));
      expect(result, isNotNull);
      expect(result!.$1, equals(const Position(2, 4)));
      expect(result.$2, equals(const Position(6, 4)));
    });

    test('对角线五连获胜', () {
      final board = _emptyBoard(15);
      for (int i = 0; i < 5; i++) {
        board[3 + i][3 + i] = StoneColor.black;
      }
      final result = BoardUtils.checkWin(board, const Position(5, 5));
      expect(result, isNotNull);
      expect(result!.$1, equals(const Position(3, 3)));
      expect(result.$2, equals(const Position(7, 7)));
    });

    test('反对角线五连获胜', () {
      final board = _emptyBoard(15);
      for (int i = 0; i < 5; i++) {
        board[3 + i][7 - i] = StoneColor.white;
      }
      final result = BoardUtils.checkWin(board, const Position(5, 5));
      expect(result, isNotNull);
      expect(result!.$1, equals(const Position(3, 7)));
      expect(result.$2, equals(const Position(7, 3)));
    });

    test('四连不获胜', () {
      final board = _emptyBoard(15);
      for (int c = 3; c <= 6; c++) {
        board[7][c] = StoneColor.black;
      }
      final result = BoardUtils.checkWin(board, const Position(7, 5));
      expect(result, isNull);
    });

    test('六连获胜', () {
      final board = _emptyBoard(15);
      for (int c = 2; c <= 7; c++) {
        board[7][c] = StoneColor.black;
      }
      final result = BoardUtils.checkWin(board, const Position(7, 4));
      expect(result, isNotNull);
      expect(result!.$1, equals(const Position(7, 2)));
      expect(result.$2, equals(const Position(7, 7)));
    });

    test('边界位置不越界', () {
      final board = _emptyBoard(15);
      board[0][0] = StoneColor.black;
      board[0][1] = StoneColor.black;
      board[0][2] = StoneColor.black;
      board[0][3] = StoneColor.black;
      board[0][4] = StoneColor.black;
      final result = BoardUtils.checkWin(board, const Position(0, 0));
      expect(result, isNotNull);
    });

    test('越界位置返回 null', () {
      final board = _emptyBoard(15);
      final result = BoardUtils.checkWin(board, const Position(-1, 0));
      expect(result, isNull);
    });

    test('空位置返回 null', () {
      final board = _emptyBoard(15);
      board[7][3] = StoneColor.black;
      board[7][4] = StoneColor.black;
      board[7][5] = StoneColor.black;
      board[7][6] = StoneColor.black;
      board[7][7] = StoneColor.black;
      final result = BoardUtils.checkWin(board, const Position(7, 8));
      expect(result, isNull);
    });
  });

  group('BoardUtils.copyBoard', () {
    test('深拷贝后修改不影响原棋盘', () {
      final original = List.generate(15, (_) => List.filled(15, null));
      original[7][7] = StoneColor.black;
      final copy = BoardUtils.copyBoard(original);
      copy[7][7] = StoneColor.white;
      expect(original[7][7], equals(StoneColor.black));
      expect(copy[7][7], equals(StoneColor.white));
    });

    test('空棋盘拷贝', () {
      final original = List.generate(9, (_) => List.filled(9, null));
      final copy = BoardUtils.copyBoard(original);
      expect(copy.length, equals(9));
      expect(copy[0].length, equals(9));
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          expect(copy[r][c], isNull);
        }
      }
    });
  });
}
