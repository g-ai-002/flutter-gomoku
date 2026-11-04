import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/board_state.dart';
import 'package:gomoku/game/engine/board_utils.dart';

GomokuBoard _boardWith(List<(int, int, int)> stones) {
  final board = GomokuBoard();
  for (final (row, col, side) in stones) {
    board.sideToMove = side;
    final record = board.apply(indexOf(row, col));
    expect(record, isNotNull);
  }
  return board;
}

void main() {
  group('棋局状态', () {
    test('初始空盘且黑棋先行', () {
      final board = GomokuBoard();
      expect(board.sideToMove, black);
      expect(board.history, isEmpty);
      expect(board.cells.every((value) => value == empty), isTrue);
      expect(board.lastIndex, isNull);
      expect(board.winner, isNull);
      expect(board.winningLine, isEmpty);
    });

    test('落子后切换行棋方并记录坐标', () {
      final board = GomokuBoard();
      final record = board.apply(indexOf(7, 7));
      expect(record, isNotNull);
      expect(record!.side, black);
      expect(record.notation, 'H8');
      expect(record.moveNumber, 1);
      expect(board.cells[indexOf(7, 7)], black);
      expect(board.sideToMove, white);
      expect(board.lastIndex, indexOf(7, 7));
    });

    test('已占点与越界落子被拒绝', () {
      final board = GomokuBoard();
      board.apply(indexOf(7, 7));
      expect(board.apply(indexOf(7, 7)), isNull);
      expect(board.apply(-1), isNull);
      expect(board.apply(cellCount), isNull);
      expect(board.history.length, 1);
      expect(board.sideToMove, white);
    });

    test('悔棋完整恢复棋盘与行棋方', () {
      final board = GomokuBoard();
      board.apply(indexOf(7, 7));
      board.apply(indexOf(8, 8));
      board.undoLast();
      expect(board.cells[indexOf(8, 8)], empty);
      expect(board.sideToMove, white);
      expect(board.lastIndex, indexOf(7, 7));
      board.undoLast();
      expect(board.sideToMove, black);
      expect(board.lastIndex, isNull);
      expect(board.history, isEmpty);
      expect(board.undoLast(), isNull);
    });

    test('空盘落满可识别满盘和棋', () {
      final board = GomokuBoard();
      for (var index = 0; index < cellCount - 1; index++) {
        board.cells[index] = index.isEven ? black : white;
      }
      expect(board.isFull, isFalse);
      board.cells[cellCount - 1] = black;
      expect(board.isFull, isTrue);
    });

    test('导入棋谱逐手重演，非法着法返回 false', () {
      final board = GomokuBoard();
      expect(board.replay([indexOf(7, 7), indexOf(7, 8)]), isTrue);
      expect(board.history.length, 2);

      final duplicate = GomokuBoard();
      expect(duplicate.replay([indexOf(7, 7), indexOf(7, 7)]), isFalse);
      expect(duplicate.history.length, 1);
    });

    test('从既有局面构造可识别已有五连', () {
      final source = emptyCells();
      for (var col = 3; col <= 7; col++) {
        source[indexOf(7, col)] = black;
      }
      final board = GomokuBoard.fromCells(source, sideToMove: white);
      expect(board.winner, black);
      expect(board.winningLine.length, 5);
      expect(board.history, isEmpty);
      expect(board.sideToMove, white);
    });

    test('重新开始清空所有状态', () {
      final board = _boardWith([(7, 7, black), (7, 8, white)]);
      board.reset();
      expect(board.history, isEmpty);
      expect(board.cells.every((value) => value == empty), isTrue);
      expect(board.sideToMove, black);
      expect(board.lastIndex, isNull);
      expect(board.winner, isNull);
    });
  });
}
