import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gomoku/models/game_state.dart';

void main() {
  group('Position', () {
    test('相等性', () {
      expect(const Position(3, 4), equals(const Position(3, 4)));
      expect(const Position(3, 4), isNot(equals(const Position(4, 3))));
    });

    test('hashCode', () {
      expect(const Position(3, 4).hashCode, equals(const Position(3, 4).hashCode));
    });
  });

  group('StoneColor', () {
    test('opponent', () {
      expect(StoneColor.black.opponent, equals(StoneColor.white));
      expect(StoneColor.white.opponent, equals(StoneColor.black));
    });

    test('label', () {
      expect(StoneColor.black.label, equals('黑棋'));
      expect(StoneColor.white.label, equals('白棋'));
    });
  });

  group('GameState', () {
    test('initial 创建正确大小的空棋盘', () {
      final state = GameState.initial(15);
      expect(state.boardSize, equals(15));
      expect(state.board.length, equals(15));
      expect(state.board[0].length, equals(15));
      expect(state.currentPlayer, equals(StoneColor.black));
      expect(state.status, equals(GameStatus.playing));
      expect(state.history, isEmpty);
      expect(state.board[0][0], isNull);
    });

    test('copyWith 部分更新', () {
      final state = GameState.initial(15);
      final updated = state.copyWith(currentPlayer: StoneColor.white);
      expect(updated.currentPlayer, equals(StoneColor.white));
      expect(updated.boardSize, equals(15));
    });
  });

  group('Move', () {
    test('创建', () {
      const move = Move(
        position: Position(7, 7),
        color: StoneColor.black,
        stepNumber: 1,
      );
      expect(move.position.row, equals(7));
      expect(move.position.col, equals(7));
      expect(move.color, equals(StoneColor.black));
      expect(move.stepNumber, equals(1));
    });
  });
}
