import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/board_state.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/engine/forbidden.dart';
import 'package:gomoku/game/engine/search.dart';
import 'package:gomoku/game/game_controller.dart';
import 'package:gomoku/models/game_models.dart';

const _aiMove = 15; // A2，与人类首手 H8 不冲突

void _placeRow(Uint8List cells, int side, int row, int from, int to) {
  for (var col = from; col <= to; col++) {
    cells[indexOf(row, col)] = side;
  }
}

GameController _controller({
  GameMode mode = GameMode.vsAi,
  int humanSide = black,
  GomokuBoard? board,
  TimeControl timeControl = TimeControl.none,
  Future<SearchResult> Function(
    Uint8List,
    int,
    Difficulty, {
    bool? forbidBlack,
  })?
  aiMove,
  Future<int?> Function(Uint8List, int, {bool? forbidBlack})? hintMove,
  bool forbidBlack = false,
}) {
  final controller = GameController(
    mode: mode,
    difficulty: Difficulty.normal,
    humanSide: humanSide,
    board: board,
    timeControl: timeControl,
    forbidBlack: forbidBlack,
    aiMove:
        aiMove ??
        (cells, side, difficulty, {bool? forbidBlack}) async =>
            const SearchResult(move: _aiMove, score: 1, depth: 1, nodes: 1),
    hintMove:
        hintMove ?? (cells, side, {bool? forbidBlack}) async => indexOf(9, 9),
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('对局控制器', () {
    test('人类落子后 AI 自动回棋', () async {
      final controller = _controller();
      controller.start();
      expect(controller.canInteractive, isTrue);

      controller.tapCell(indexOf(7, 7));
      expect(controller.history.length, 1);
      expect(controller.thinking, isTrue);
      expect(controller.canInteractive, isFalse);

      await pumpEventQueue();
      expect(controller.history.length, 2);
      expect(controller.history.last.side, white);
      expect(controller.canInteractive, isTrue);
    });

    test('已有棋子与越界点击被忽略', () async {
      final controller = _controller(mode: GameMode.twoPlayers);
      controller.start();
      controller.tapCell(indexOf(7, 7));
      controller.tapCell(indexOf(7, 7));
      controller.tapCell(-5);
      controller.tapCell(cellCount + 3);
      expect(controller.history.length, 1);
      expect(controller.thinking, isFalse);
    });

    test('人类执白时 AI 先行', () async {
      final controller = _controller(humanSide: white);
      controller.start();
      await pumpEventQueue();
      expect(controller.history.length, 1);
      expect(controller.history.first.side, black);
      expect(controller.canInteractive, isTrue);
    });

    test('人机对战悔棋同时撤回双方各一手', () async {
      final controller = _controller();
      controller.start();
      controller.tapCell(centerIndex);
      await pumpEventQueue();
      expect(controller.history.length, 2);

      controller.undo();
      expect(controller.history, isEmpty);
      expect(controller.board.sideToMove, black);
      expect(controller.canInteractive, isTrue);
    });

    test('重开清空局面并重置结果', () async {
      final controller = _controller(mode: GameMode.twoPlayers);
      controller.start();
      controller.tapCell(centerIndex);
      controller.restart();
      expect(controller.history, isEmpty);
      expect(controller.board.sideToMove, black);
      expect(controller.result, isNull);
    });

    test('认输判对手胜', () {
      final controller = _controller(mode: GameMode.twoPlayers);
      controller.start();
      controller.resign();
      expect(controller.result, isNotNull);
      expect(controller.result!.winner, white);
      expect(controller.result!.reason, '认输');
    });

    test('五连后立即终局', () {
      final cells = emptyCells();
      for (var col = 3; col <= 6; col++) {
        cells[indexOf(7, col)] = black;
      }
      for (var col = 3; col <= 5; col++) {
        cells[indexOf(9, col)] = white;
      }
      final board = GomokuBoard.fromCells(cells);
      final controller = _controller(mode: GameMode.twoPlayers, board: board);
      controller.start();
      controller.tapCell(indexOf(7, 7));
      expect(controller.result, isNotNull);
      expect(controller.result!.winner, black);
      expect(controller.result!.reason, '五连');
      expect(controller.winningLine.length, 5);
      expect(controller.canInteract, isFalse);
    });

    test('走子提示返回推荐点并在落子后清除', () async {
      final controller = _controller();
      controller.start();
      await controller.requestHint();
      expect(controller.hintIndex, indexOf(9, 9));
      expect(controller.hintLoading, isFalse);
      controller.tapCell(indexOf(7, 7));
      expect(controller.hintIndex, isNull);
      await pumpEventQueue();
    });

    test('棋钟超时判负', () {
      final controller = _controller(
        mode: GameMode.twoPlayers,
        timeControl: TimeControl.blitz,
      );
      controller.start();
      expect(controller.clock, isNotNull);
      controller.tickClock(const Duration(minutes: 5));
      expect(controller.result, isNotNull);
      expect(controller.result!.winner, white);
      expect(controller.result!.reason, '超时');
      expect(controller.clock!.remainingMs(black), 0);
    });

    test('AI 思考中重开不会落子', () async {
      final completer = Completer<SearchResult>();
      final controller = _controller(
        aiMove: (cells, side, difficulty, {bool? forbidBlack}) =>
            completer.future,
      );
      controller.start();
      controller.tapCell(centerIndex);
      expect(controller.thinking, isTrue);
      controller.restart();
      completer.complete(
        const SearchResult(move: _aiMove, score: 1, depth: 1, nodes: 1),
      );
      await pumpEventQueue();
      expect(controller.history, isEmpty);
      expect(controller.thinking, isFalse);
    });

    test('AI 返回非法着法时兜底优先自己成五', () async {
      final cells = emptyCells();
      _placeRow(cells, white, 2, 3, 6);
      _placeRow(cells, black, 10, 3, 6);
      final controller = _controller(
        board: GomokuBoard.fromCells(cells),
        aiMove: (cells, side, difficulty, {bool? forbidBlack}) async =>
            const SearchResult(move: -1, score: 0, depth: 0, nodes: 0),
      );
      controller.start();
      controller.tapCell(indexOf(12, 12));
      await pumpEventQueue();

      expect(controller.result?.winner, white);
      expect(controller.result?.reason, '五连');
      expect(
        controller.history.last.index,
        anyOf(indexOf(2, 2), indexOf(2, 7)),
      );
    });

    test('启用禁手时人类禁手落子被拒绝并记录原因', () {
      final source = emptyCells();
      for (final col in [3, 4, 5, 7, 8]) {
        source[indexOf(7, col)] = black;
      }
      final controller = _controller(
        mode: GameMode.twoPlayers,
        board: GomokuBoard.fromCells(source),
        forbidBlack: true,
      );
      controller.start();
      expect(controller.forbiddenPoints, contains(indexOf(7, 6)));

      controller.tapCell(indexOf(7, 6));
      expect(controller.history, isEmpty);
      expect(controller.violationCount, 1);
      expect(controller.lastViolation, ForbiddenReason.overline);

      controller.tapCell(indexOf(0, 0));
      expect(controller.history.length, 1);
      expect(controller.lastViolation, isNull);
      expect(controller.forbiddenPoints, isEmpty);
    });

    test('AI 返回黑棋禁手着法时改用合法兜底', () async {
      final source = emptyCells();
      for (final col in [3, 4, 5, 7, 8]) {
        source[indexOf(7, col)] = black;
      }
      final controller = _controller(
        humanSide: white,
        board: GomokuBoard.fromCells(source),
        forbidBlack: true,
        aiMove: (cells, side, difficulty, {bool? forbidBlack}) async =>
            SearchResult(move: indexOf(7, 6), score: 1, depth: 1, nodes: 1),
      );
      controller.start();
      await pumpEventQueue();
      expect(controller.history.length, 1);
      expect(controller.history.single.index, isNot(indexOf(7, 6)));
    });

    test('提示不会给出禁手点', () async {
      final source = emptyCells();
      for (final col in [3, 4, 5, 7, 8]) {
        source[indexOf(7, col)] = black;
      }
      final controller = _controller(
        mode: GameMode.twoPlayers,
        board: GomokuBoard.fromCells(source),
        forbidBlack: true,
        hintMove: (cells, side, {bool? forbidBlack}) async => indexOf(7, 6),
      );
      controller.start();
      await controller.requestHint();
      expect(controller.hintIndex, isNull);
    });

    test('空盘提示与悔棋按钮状态', () {
      final controller = _controller(mode: GameMode.twoPlayers);
      controller.start();
      expect(controller.canUndo, isFalse);
      expect(controller.lastSide, isNull);
      controller.tapCell(centerIndex);
      expect(controller.canUndo, isTrue);
      expect(controller.lastSide, black);
    });
  });
}
