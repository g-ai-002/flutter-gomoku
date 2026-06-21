import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gomoku/ai/ai_engine.dart';
import 'package:flutter_gomoku/providers/game_provider.dart';
import 'package:flutter_gomoku/models/game_state.dart';
import 'package:flutter_gomoku/services/storage_service.dart';
import 'package:flutter_gomoku/utils/constants.dart';

void main() {
  late StorageService storage;
  late GameProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.instance;
    await storage.setBoardSize(AppConstants.defaultBoardSize);
    await storage.setGameMode(GameMode.pvp);
    provider = GameProvider(storage);
  });

  group('GameProvider 基础', () {
    test('初始状态', () {
      expect(provider.boardSize, equals(15));
      expect(provider.currentPlayer, equals(StoneColor.black));
      expect(provider.status, equals(GameStatus.playing));
      expect(provider.history, isEmpty);
      expect(provider.canUndo, isFalse);
      expect(provider.isGameOver, isFalse);
      expect(provider.mode, equals(GameMode.pvp));
      expect(provider.aiThinking, isFalse);
    });

    test('落子成功', () {
      final result = provider.placeStone(7, 7);
      expect(result, isTrue);
      expect(provider.board[7][7], equals(StoneColor.black));
      expect(provider.currentPlayer, equals(StoneColor.white));
      expect(provider.history.length, equals(1));
      expect(provider.canUndo, isTrue);
    });

    test('同一位置不能重复落子', () {
      provider.placeStone(7, 7);
      final result = provider.placeStone(7, 7);
      expect(result, isFalse);
    });

    test('越界落子返回 false', () {
      expect(provider.placeStone(-1, 0), isFalse);
      expect(provider.placeStone(0, 15), isFalse);
      expect(provider.placeStone(15, 0), isFalse);
    });

    test('游戏结束后不能落子', () {
      for (int i = 0; i < 5; i++) {
        provider.placeStone(i, 0); // 黑
        if (i < 4) provider.placeStone(i, 1); // 白
      }
      expect(provider.isGameOver, isTrue);
      final result = provider.placeStone(8, 8);
      expect(result, isFalse);
    });

    test('悔棋', () {
      provider.placeStone(7, 7);
      provider.placeStone(7, 8);
      expect(provider.history.length, equals(2));

      final result = provider.undo();
      expect(result, isTrue);
      expect(provider.history.length, equals(1));
      expect(provider.currentPlayer, equals(StoneColor.white));
      expect(provider.board[7][8], isNull);
      expect(provider.board[7][7], equals(StoneColor.black));
    });

    test('无棋可悔时返回 false', () {
      expect(provider.canUndo, isFalse);
      expect(provider.undo(), isFalse);
    });

    test('重新开始', () {
      provider.placeStone(7, 7);
      provider.placeStone(7, 8);
      provider.restart();
      expect(provider.history, isEmpty);
      expect(provider.currentPlayer, equals(StoneColor.black));
      expect(provider.status, equals(GameStatus.playing));
      expect(provider.board[7][7], isNull);
    });

    test('设置棋盘大小', () {
      provider.setBoardSize(19);
      expect(provider.boardSize, equals(19));
      expect(provider.board.length, equals(19));
      expect(provider.history, isEmpty);
    });

    test('无效棋盘大小不生效', () {
      provider.setBoardSize(5);
      expect(provider.boardSize, equals(15));
      provider.setBoardSize(25);
      expect(provider.boardSize, equals(15));
    });
  });

  group('游戏模式', () {
    test('默认双人对弈', () {
      expect(provider.mode, equals(GameMode.pvp));
    });

    test('切换为人机对弈', () {
      provider.setGameMode(GameMode.pve);
      expect(provider.mode, equals(GameMode.pve));
      expect(provider.history, isEmpty);
    });

    test('切换模式重置游戏', () {
      provider.placeStone(7, 7);
      provider.setGameMode(GameMode.pve);
      expect(provider.history, isEmpty);
      expect(provider.status, equals(GameStatus.playing));
    });

    test('设置 AI 难度', () {
      provider.setAIDifficulty(AIDifficulty.easy);
      expect(provider.aiDifficulty, equals(AIDifficulty.easy));
      provider.setAIDifficulty(AIDifficulty.hard);
      expect(provider.aiDifficulty, equals(AIDifficulty.hard));
    });

    test('设置 AI 难度重置游戏', () {
      provider.placeStone(7, 7);
      provider.setAIDifficulty(AIDifficulty.hard);
      expect(provider.history, isEmpty);
    });
  });

  group('人机对弈', () {
    setUp(() async {
      provider.setGameMode(GameMode.pve);
    });

    test('玩家落子后 AI 开始思考', () {
      provider.placeStone(7, 7);
      expect(provider.aiThinking, isTrue);
    });

    test('AI 思考中不能落子', () {
      provider.placeStone(7, 7);
      expect(provider.aiThinking, isTrue);
      final result = provider.placeStone(8, 8);
      expect(result, isFalse);
    });

    test('AI 思考中不能悔棋', () {
      provider.placeStone(7, 7);
      expect(provider.aiThinking, isTrue);
      final result = provider.undo();
      expect(result, isFalse);
    });

    test('人机模式悔棋悔两步', () async {
      provider.placeStone(7, 7); // 玩家
      // 等待 AI 落子
      await Future.delayed(const Duration(milliseconds: 300));
      expect(provider.history.length, equals(2));
      expect(provider.aiThinking, isFalse);

      provider.undo();
      expect(provider.history.length, equals(0));
      expect(provider.currentPlayer, equals(StoneColor.black));
    });
  });

  group('胜负判定', () {
    test('水平五连', () {
      for (int i = 0; i < 5; i++) {
        provider.placeStone(7, i); // 黑
        if (i < 4) provider.placeStone(8, i); // 白
      }
      expect(provider.status, equals(GameStatus.blackWin));
    });

    test('垂直五连', () {
      for (int i = 0; i < 5; i++) {
        provider.placeStone(i, 7); // 黑
        if (i < 4) provider.placeStone(i, 8); // 白
      }
      expect(provider.status, equals(GameStatus.blackWin));
    });

    test('对角线五连', () {
      for (int i = 0; i < 5; i++) {
        provider.placeStone(i, i); // 黑
        if (i < 4) provider.placeStone(i, i + 1); // 白
      }
      expect(provider.status, equals(GameStatus.blackWin));
    });

    test('反对角线五连', () {
      for (int i = 0; i < 5; i++) {
        provider.placeStone(i, 10 - i); // 黑
        if (i < 4) provider.placeStone(i, 9 - i); // 白
      }
      expect(provider.status, equals(GameStatus.blackWin));
    });

    test('白棋获胜', () {
      provider.placeStone(0, 0); // 黑
      provider.placeStone(0, 7); // 白
      provider.placeStone(0, 1); // 黑
      provider.placeStone(1, 7); // 白
      provider.placeStone(0, 2); // 黑
      provider.placeStone(2, 7); // 白
      provider.placeStone(0, 3); // 黑
      provider.placeStone(3, 7); // 白
      provider.placeStone(1, 0); // 黑
      provider.placeStone(4, 7); // 白
      expect(provider.status, equals(GameStatus.whiteWin));
    });

    test('四连不算赢', () {
      for (int i = 0; i < 4; i++) {
        provider.placeStone(7, i); // 黑
        provider.placeStone(8, i); // 白
      }
      expect(provider.status, equals(GameStatus.playing));
    });

    test('平局判定', () {
      final drawState = GameState.initial(15).copyWith(status: GameStatus.draw);
      expect(drawState.status, equals(GameStatus.draw));
      expect(drawState.isGameOver, isTrue);
    });

    test('悔棋后胜负状态重置', () {
      for (int i = 0; i < 5; i++) {
        provider.placeStone(7, i);
        if (i < 4) provider.placeStone(8, i);
      }
      expect(provider.status, equals(GameStatus.blackWin));
      expect(provider.canUndo, isTrue);
      provider.undo();
      expect(provider.status, equals(GameStatus.playing));
    });

    test('设置棋盘大小后状态重置', () {
      provider.placeStone(7, 7);
      provider.placeStone(7, 8);
      provider.setBoardSize(13);
      expect(provider.boardSize, equals(13));
      expect(provider.history, isEmpty);
      expect(provider.status, equals(GameStatus.playing));
    });

    test('边界位置落子', () {
      expect(provider.placeStone(0, 0), isTrue);
      expect(provider.placeStone(14, 14), isTrue);
      expect(provider.placeStone(0, 14), isTrue);
      expect(provider.placeStone(14, 0), isTrue);
    });
  });
}
