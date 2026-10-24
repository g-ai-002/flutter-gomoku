import 'package:flutter_gomoku/game/replay_board.dart';
import 'package:flutter_gomoku/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReplayBoard.seek', () {
    test('前进与回退只应用差值部分', () {
      final view = ReplayBoard(15);
      final moves = [
        const Move(
          position: Position(7, 7),
          color: StoneColor.black,
          stepNumber: 1,
        ),
        const Move(
          position: Position(7, 8),
          color: StoneColor.white,
          stepNumber: 2,
        ),
        const Move(
          position: Position(8, 8),
          color: StoneColor.black,
          stepNumber: 3,
        ),
      ];

      view.seek(2, moves);
      expect(view.appliedMoves, 2);
      expect(view.board[7][7], StoneColor.black);
      expect(view.board[7][8], StoneColor.white);
      expect(view.board[8][8], isNull);
      expect(view.lastMove, const Position(7, 8));
      expect(view.status, GameStatus.playing);

      view.seek(0, moves);
      expect(view.appliedMoves, 0);
      expect(view.board[7][7], isNull);
      expect(view.board[7][8], isNull);
      expect(view.lastMove, isNull);

      view.seek(3, moves);
      expect(view.appliedMoves, 3);
      expect(view.board[8][8], StoneColor.black);
      expect(view.lastMove, const Position(8, 8));
    });

    test('回退清除胜负连线，再前进可重新判定', () {
      final view = ReplayBoard(15);
      final moves = <Move>[];
      for (var i = 0; i < 5; i++) {
        moves.add(Move(
          position: Position(7, 3 + i),
          color: StoneColor.black,
          stepNumber: moves.length + 1,
        ));
        if (i < 4) {
          moves.add(Move(
            position: Position(8, 3 + i),
            color: StoneColor.white,
            stepNumber: moves.length + 1,
          ));
        }
      }

      view.seek(moves.length, moves);
      expect(view.status, GameStatus.blackWin);
      expect(view.winStart, const Position(7, 3));
      expect(view.winEnd, const Position(7, 7));

      view.seek(moves.length - 1, moves);
      expect(view.status, GameStatus.playing);
      expect(view.winStart, isNull);
      expect(view.winEnd, isNull);
      expect(view.board[7][7], isNull);
      expect(view.lastMove, const Position(8, 6));

      view.seek(moves.length, moves);
      expect(view.status, GameStatus.blackWin);
      expect(view.board[7][7], StoneColor.black);
      expect(view.lastMove, const Position(7, 7));
    });

    test('目标手数会被夹到 0 与总手数之间', () {
      final view = ReplayBoard(15);
      final moves = [
        const Move(
          position: Position(3, 3),
          color: StoneColor.black,
          stepNumber: 1,
        ),
      ];

      view.seek(-5, moves);
      expect(view.appliedMoves, 0);
      expect(view.board[3][3], isNull);

      view.seek(99, moves);
      expect(view.appliedMoves, 1);
      expect(view.board[3][3], StoneColor.black);
      expect(view.lastMove, const Position(3, 3));
    });
  });
}
