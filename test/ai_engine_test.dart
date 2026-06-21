import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gomoku/ai/ai_engine.dart';
import 'package:flutter_gomoku/models/game_state.dart';

void main() {
  group('AIDifficulty', () {
    test('label', () {
      expect(AIDifficulty.easy.label, equals('简单'));
      expect(AIDifficulty.medium.label, equals('中等'));
      expect(AIDifficulty.hard.label, equals('困难'));
    });
  });

  group('GomokuAI easy', () {
    final ai = GomokuAI(AIDifficulty.easy);

    test('空棋盘返回中心附近', () {
      final state = GameState.initial(15);
      final move = ai.findBestMove(state);
      expect(move, isNotNull);
      expect(move!.row, inInclusiveRange(0, 14));
      expect(move.col, inInclusiveRange(0, 14));
    });

    test('有棋子时返回空位', () {
      var state = GameState.initial(15);
      // 手动放一些棋子
      final newBoard = state.board.map((r) => List<StoneColor?>.from(r)).toList();
      newBoard[7][7] = StoneColor.black;
      newBoard[7][8] = StoneColor.white;
      state = state.copyWith(board: newBoard);
      final move = ai.findBestMove(state);
      expect(move, isNotNull);
      expect(state.board[move!.row][move.col], isNull);
    });

    test('满棋盘返回 null', () {
      final board = List.generate(
        9,
        (r) => List.generate(9, (c) => r % 2 == 0 ? StoneColor.black : StoneColor.white),
      );
      final state = GameState.initial(9).copyWith(board: board);
      final move = ai.findBestMove(state);
      expect(move, isNull);
    });
  });

  group('GomokuAI medium', () {
    final ai = GomokuAI(AIDifficulty.medium);

    test('空棋盘返回有效位置', () {
      final state = GameState.initial(15);
      final move = ai.findBestMove(state);
      expect(move, isNotNull);
      expect(move!.row, inInclusiveRange(0, 14));
      expect(move.col, inInclusiveRange(0, 14));
    });

    test('能识别即将获胜的位置', () {
      var state = GameState.initial(15);
      final newBoard = state.board.map((r) => List<StoneColor?>.from(r)).toList();
      // 黑棋已有四连
      newBoard[7][0] = StoneColor.black;
      newBoard[7][1] = StoneColor.black;
      newBoard[7][2] = StoneColor.black;
      newBoard[7][3] = StoneColor.black;
      state = state.copyWith(board: newBoard, currentPlayer: StoneColor.black);
      final move = ai.findBestMove(state);
      expect(move, isNotNull);
      // 应该下在 (7,4) 完成五连
      expect(move!.row, equals(7));
      expect(move.col, equals(4));
    });

    test('能防守对手即将获胜', () {
      var state = GameState.initial(15);
      final newBoard = state.board.map((r) => List<StoneColor?>.from(r)).toList();
      // 白棋已有四连
      newBoard[7][0] = StoneColor.white;
      newBoard[7][1] = StoneColor.white;
      newBoard[7][2] = StoneColor.white;
      newBoard[7][3] = StoneColor.white;
      state = state.copyWith(board: newBoard, currentPlayer: StoneColor.black);
      final move = ai.findBestMove(state);
      expect(move, isNotNull);
      // 应该堵在 (7,4)
      expect(move!.row, equals(7));
      expect(move.col, equals(4));
    });
  });

  group('GomokuAI hard', () {
    final ai = GomokuAI(AIDifficulty.hard);

    test('空棋盘返回有效位置', () {
      final state = GameState.initial(15);
      final move = ai.findBestMove(state);
      expect(move, isNotNull);
      expect(move!.row, inInclusiveRange(0, 14));
      expect(move.col, inInclusiveRange(0, 14));
    });

    test('能识别即将获胜的位置', () {
      var state = GameState.initial(15);
      final newBoard = state.board.map((r) => List<StoneColor?>.from(r)).toList();
      newBoard[7][0] = StoneColor.black;
      newBoard[7][1] = StoneColor.black;
      newBoard[7][2] = StoneColor.black;
      newBoard[7][3] = StoneColor.black;
      state = state.copyWith(board: newBoard, currentPlayer: StoneColor.black);
      final move = ai.findBestMove(state);
      expect(move, isNotNull);
      expect(move!.row, equals(7));
      expect(move.col, equals(4));
    });

    test('能防守对手即将获胜', () {
      var state = GameState.initial(15);
      final newBoard = state.board.map((r) => List<StoneColor?>.from(r)).toList();
      newBoard[7][0] = StoneColor.white;
      newBoard[7][1] = StoneColor.white;
      newBoard[7][2] = StoneColor.white;
      newBoard[7][3] = StoneColor.white;
      state = state.copyWith(board: newBoard, currentPlayer: StoneColor.black);
      final move = ai.findBestMove(state);
      expect(move, isNotNull);
      expect(move!.row, equals(7));
      expect(move.col, equals(4));
    });
  });
}
