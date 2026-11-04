import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/board_state.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/replay_controller.dart';

GomokuBoard _winningGame() {
  final board = GomokuBoard();
  final moves = [
    indexOf(7, 3),
    indexOf(0, 0),
    indexOf(7, 4),
    indexOf(0, 1),
    indexOf(7, 5),
    indexOf(0, 2),
    indexOf(7, 6),
    indexOf(0, 3),
    indexOf(7, 7),
  ];
  for (final move in moves) {
    board.apply(move);
  }
  return board;
}

void main() {
  group('复盘回放', () {
    test('开局为空盘，终局包含胜利连线', () {
      final board = _winningGame();
      final replay = ReplayController(moves: board.history);
      addTearDown(replay.dispose);

      expect(replay.cursor, 0);
      expect(replay.total, 9);
      expect(replay.history, isEmpty);
      expect(replay.canPrevious, isFalse);
      expect(replay.canNext, isTrue);
      expect(replay.progressText, '第 0 / 9 手');

      replay.last();
      expect(replay.cursor, 9);
      expect(replay.history.length, 9);
      expect(replay.winningLine.length, 5);
      expect(replay.finished, isTrue);
      expect(replay.canNext, isFalse);

      replay.first();
      expect(replay.cursor, 0);
      expect(replay.winningLine, isEmpty);
    });

    test('逐步前进后退与跳转', () {
      final board = _winningGame();
      final replay = ReplayController(moves: board.history);
      addTearDown(replay.dispose);

      replay.next();
      replay.next();
      expect(replay.cursor, 2);
      expect(replay.history.length, 2);
      replay.previous();
      expect(replay.cursor, 1);
      expect(replay.history.length, 1);

      replay.jumpTo(7);
      expect(replay.cursor, 7);
      expect(replay.history.length, 7);

      replay.jumpTo(100);
      expect(replay.cursor, 9);
      replay.jumpTo(-5);
      expect(replay.cursor, 0);
      expect(replay.history, isEmpty);
    });

    test('非法棋谱在构造时抛出异常', () {
      final board = _winningGame();
      final moves = List.of(board.history)..[3] = board.history[0];
      expect(() => ReplayController(moves: moves), throwsArgumentError);
    });
  });
}
