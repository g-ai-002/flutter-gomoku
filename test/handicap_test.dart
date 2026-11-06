import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/board_state.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/engine/search.dart';
import 'package:gomoku/game/game_archive.dart';
import 'package:gomoku/game/game_controller.dart';
import 'package:gomoku/game/handicap.dart';
import 'package:gomoku/game/replay_controller.dart';
import 'package:gomoku/models/game_models.dart';
import 'package:gomoku/models/saved_game.dart';

SearchResult _reply(int move) =>
    SearchResult(move: move, score: 1, depth: 1, nodes: 1);

GameController _controller({
  Handicap handicap = Handicap.none,
  TimeControl timeControl = TimeControl.none,
  Future<SearchResult> Function(
    Uint8List,
    int,
    Difficulty, {
    bool? forbidBlack,
  })?
  aiMove,
}) {
  final controller = GameController(
    mode: GameMode.vsAi,
    difficulty: Difficulty.normal,
    humanSide: black,
    handicap: handicap,
    timeControl: timeControl,
    aiMove:
        aiMove ??
        (cells, side, difficulty, {bool? forbidBlack}) async => _reply(0),
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('让子对局', () {
    test('让二子预置对角星位并由白方先行', () {
      final board = GomokuBoard(handicap: Handicap.two);
      expect(board.handicap, Handicap.two);
      expect(board.cells[indexOf(3, 3)], black);
      expect(board.cells[indexOf(11, 11)], black);
      expect(board.history, isEmpty);
      expect(board.sideToMove, white);
      expect(board.lastIndex, isNull);
    });

    test('重开保留让子并回到白方行棋', () {
      final board = GomokuBoard(handicap: Handicap.three);
      board.apply(indexOf(7, 7));
      board.apply(indexOf(6, 6));
      board.reset();

      expect(board.history, isEmpty);
      expect(board.cells[centerIndex], black);
      expect(board.cells[indexOf(3, 3)], black);
      expect(board.sideToMove, white);
      expect(stoneCount(board.cells), Handicap.three.count);
    });

    test('让子局悔棋回到白方行棋', () {
      final board = GomokuBoard(handicap: Handicap.one);
      board.apply(indexOf(7, 6));
      board.apply(indexOf(6, 7));
      board.undoLast();
      expect(board.sideToMove, black);
      board.undoLast();
      expect(board.sideToMove, white);
      expect(board.history, isEmpty);
      expect(board.cells[centerIndex], black);
    });

    test('AI 执白先行，人类执黑接手', () async {
      final controller = _controller(handicap: Handicap.two);
      controller.start();

      expect(controller.thinking, isTrue);
      expect(controller.board.sideToMove, white);
      await pumpEventQueue();

      expect(controller.history.length, 1);
      expect(controller.history.single.side, white);
      expect(controller.canInteractive, isTrue);
      expect(controller.board.cells[indexOf(3, 3)], black);
      expect(controller.canUndo, isFalse);
    });

    test('重开后仍由 AI 先行且让子保留', () async {
      final controller = _controller(handicap: Handicap.two);
      controller.start();
      await pumpEventQueue();
      controller.tapCell(centerIndex);
      await pumpEventQueue();

      controller.restart();
      expect(controller.history, isEmpty);
      expect(controller.board.sideToMove, white);
      expect(controller.board.cells[indexOf(3, 3)], black);

      await pumpEventQueue();
      expect(controller.history.length, 1);
      expect(controller.history.single.side, white);
    });

    test('让子棋钟从白方开始计时', () async {
      final pending = Completer<SearchResult>();
      final controller = _controller(
        handicap: Handicap.two,
        timeControl: TimeControl.blitz,
        aiMove: (cells, side, difficulty, {bool? forbidBlack}) =>
            pending.future,
      );
      controller.start();
      expect(controller.clock!.activeSide, white);

      controller.tickClock(const Duration(minutes: 5));
      expect(controller.result!.winner, black);
      expect(controller.result!.reason, '超时');
      expect(controller.clock!.remainingMs(white), 0);
    });

    test('棋谱记录让子数并可按让子局面复盘', () {
      final board = GomokuBoard(handicap: Handicap.two);
      board.apply(indexOf(7, 7));
      board.apply(indexOf(6, 6));
      board.apply(indexOf(7, 8));

      final text = GameArchive.encode(
        title: '让二子对局',
        moves: board.history,
        handicap: Handicap.two,
      );
      expect(text, contains('先手：白'));
      expect(text, contains('让子：2'));

      final decoded = GameArchive.decode(text);
      expect(decoded, isNotNull);
      expect(decoded!.handicap, Handicap.two);

      final replay = ReplayController(
        moves: board.history,
        handicap: Handicap.two,
      );
      addTearDown(replay.dispose);
      replay.jumpTo(replay.total);
      expect(replay.cells[indexOf(3, 3)], black);
      expect(replay.cells[indexOf(7, 7)], white);
      expect(replay.cells[indexOf(6, 6)], black);
      expect(replay.cells[indexOf(7, 8)], white);
    });

    test('棋谱库保存与恢复让子方案', () {
      final board = GomokuBoard(handicap: Handicap.three);
      for (final index in [indexOf(7, 6), indexOf(6, 7), indexOf(7, 8)]) {
        expect(board.apply(index), isNotNull);
      }
      final saved = SavedGame(
        id: 'handicap',
        title: '让三子对局',
        endedAt: DateTime(2026, 11, 7),
        moves: board.history,
        handicap: Handicap.three,
      );

      final restored = SavedGame.fromJson(saved.toJson());
      expect(restored, isNotNull);
      expect(restored!.handicap, Handicap.three);
      expect(restored.moves.first.side, white);
      expect(restored.toArchiveText(), contains('让子：3'));
    });

    test('未记录让子的旧棋谱按无让子解析', () {
      final board = GomokuBoard();
      board.apply(centerIndex);
      final text = GameArchive.encode(title: '旧棋谱', moves: board.history);
      final decoded = GameArchive.decode(text);
      expect(decoded!.handicap, Handicap.none);
    });

    test('让子方案按名称与子数解析', () {
      expect(Handicap.byName('four'), Handicap.four);
      expect(Handicap.byName('unknown'), Handicap.none);
      expect(Handicap.byCount(2), Handicap.two);
      expect(Handicap.byCount(null), Handicap.none);
      expect(Handicap.four.points.toSet().length, 4);
      expect(Handicap.four.label, '让四子');
    });
  });
}
