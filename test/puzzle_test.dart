import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/engine/rules.dart';
import 'package:gomoku/game/engine/search.dart';
import 'package:gomoku/game/puzzle_controller.dart';
import 'package:gomoku/game/puzzles.dart';
import 'package:gomoku/models/game_models.dart';
import 'package:gomoku/services/puzzle_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

SearchResult _defendAt(int index) =>
    SearchResult(move: index, score: 0, depth: 1, nodes: 1);

PuzzleController _controller(
  GomokuPuzzle puzzle, {
  int defend = 0,
  Future<SearchResult> Function(Uint8List, int, Difficulty)? aiMove,
}) {
  final controller = PuzzleController(
    puzzle: puzzle,
    aiMove: aiMove ?? (cells, side, difficulty) async => _defendAt(defend),
    hintMove: (cells, side) async => indexOf(7, 9),
  );
  addTearDown(controller.dispose);
  return controller;
}

/// 落子后形成的活三数量，用于校验双三杀。
int _openThrees(Uint8List cells, int index, int side) {
  cells[index] = side;
  var count = 0;
  for (final (dr, dc) in kDirections) {
    var row = rowOf(index);
    var col = colOf(index);
    while (inBoard(row - dr, col - dc) &&
        cells[indexOf(row - dr, col - dc)] == side) {
      row -= dr;
      col -= dc;
    }
    var length = 0;
    var r = row;
    var c = col;
    while (inBoard(r, c) && cells[indexOf(r, c)] == side) {
      length++;
      r += dr;
      c += dc;
    }
    if (length != 3) continue;
    final beforeOpen =
        inBoard(row - dr, col - dc) &&
        cells[indexOf(row - dr, col - dc)] == empty;
    final afterOpen = inBoard(r, c) && cells[indexOf(r, c)] == empty;
    if (beforeOpen && afterOpen) count++;
  }
  cells[index] = empty;
  return count;
}

void main() {
  group('残局数据', () {
    test('十道残局按难度分组且手数匹配', () {
      expect(kGomokuPuzzles.length, 10);
      expect(kGomokuPuzzles.map((puzzle) => puzzle.id).toSet().length, 10);
      expect(
        kGomokuPuzzles.where((p) => p.tier == PuzzleTier.starter).length,
        4,
      );
      expect(
        kGomokuPuzzles.where((p) => p.tier == PuzzleTier.advanced).length,
        4,
      );
      expect(
        kGomokuPuzzles.where((p) => p.tier == PuzzleTier.expert).length,
        2,
      );
      for (final puzzle in kGomokuPuzzles) {
        final expected = switch (puzzle.tier) {
          PuzzleTier.starter => 1,
          PuzzleTier.advanced => 2,
          PuzzleTier.expert => 3,
        };
        expect(puzzle.moveLimit, expected, reason: puzzle.id);
        expect(puzzle.tip, isNotEmpty);
      }
    });

    test('局面互不重叠、无越界且双方都未成五', () {
      for (final puzzle in kGomokuPuzzles) {
        final all = [...puzzle.blackStones, ...puzzle.whiteStones];
        expect(all.toSet().length, all.length, reason: puzzle.id);
        for (final index in all) {
          expect(index, inInclusiveRange(0, cellCount - 1));
        }
        final cells = puzzle.buildCells();
        expect(stoneCount(cells), all.length, reason: puzzle.id);
        expect(
          GomokuRules.immediateWins(cells, white),
          isEmpty,
          reason: '${puzzle.id} 白棋不应已有成五',
        );
      }
    });

    test('入门关存在一步成五', () {
      for (final puzzle in kGomokuPuzzles.where(
        (p) => p.tier == PuzzleTier.starter,
      )) {
        expect(
          GomokuRules.immediateWins(puzzle.buildCells(), black),
          isNotEmpty,
          reason: puzzle.id,
        );
      }
    });

    test('进阶关存在可形成活四的着法', () {
      for (final puzzle in kGomokuPuzzles.where(
        (p) => p.tier == PuzzleTier.advanced,
      )) {
        final cells = puzzle.buildCells();
        var found = false;
        for (final index in GomokuRules.candidateMoves(cells)) {
          cells[index] = black;
          if (GomokuRules.makesOpenFour(cells, index, black)) found = true;
          cells[index] = empty;
          if (found) break;
        }
        expect(found, isTrue, reason: puzzle.id);
      }
    });

    test('挑战关存在一手双三', () {
      for (final puzzle in kGomokuPuzzles.where(
        (p) => p.tier == PuzzleTier.expert,
      )) {
        final cells = puzzle.buildCells();
        var found = false;
        for (final index in GomokuRules.candidateMoves(cells)) {
          if (_openThrees(cells, index, black) >= 2) found = true;
          if (found) break;
        }
        expect(found, isTrue, reason: puzzle.id);
      }
    });
  });

  group('残局控制器', () {
    test('两步杀：活四逼迫白棋封堵后成五', () async {
      final puzzle = kGomokuPuzzles.firstWhere((p) => p.id == 'p05');
      final controller = _controller(puzzle, defend: indexOf(7, 4));
      controller.tapCell(indexOf(7, 8));
      expect(controller.playerMoves, 1);
      expect(controller.thinking, isTrue);
      await pumpEventQueue();

      expect(controller.history.length, 2);
      expect(controller.history.last.index, indexOf(7, 4));
      expect(controller.canInteract, isTrue);

      controller.tapCell(indexOf(7, 9));
      expect(controller.status, PuzzleStatus.solved);
      expect(controller.playerMoves, 2);
      expect(controller.winningLine.length, 5);
      expect(controller.isSolved, isTrue);
    });

    test('一步关走错立即失败', () {
      final puzzle = kGomokuPuzzles.firstWhere((p) => p.id == 'p01');
      final controller = _controller(puzzle);
      controller.tapCell(indexOf(0, 0));
      expect(controller.status, PuzzleStatus.failed);
      expect(controller.failureReason, contains('1 手'));
      expect(controller.canInteract, isFalse);
    });

    test('悔棋撤回玩家与白棋各一手', () async {
      final puzzle = kGomokuPuzzles.firstWhere((p) => p.id == 'p05');
      final controller = _controller(puzzle, defend: indexOf(7, 4));
      controller.tapCell(indexOf(7, 8));
      await pumpEventQueue();
      expect(controller.history.length, 2);

      controller.undo();
      expect(controller.history, isEmpty);
      expect(controller.playerMoves, 0);
      expect(controller.status, PuzzleStatus.playing);
      expect(controller.canInteract, isTrue);
    });

    test('重开恢复内置局面', () async {
      final puzzle = kGomokuPuzzles.firstWhere((p) => p.id == 'p05');
      final controller = _controller(puzzle, defend: indexOf(7, 4));
      controller.tapCell(indexOf(7, 8));
      await pumpEventQueue();
      controller.restart();

      expect(controller.history, isEmpty);
      expect(controller.playerMoves, 0);
      expect(controller.status, PuzzleStatus.playing);
      expect(
        stoneCount(controller.board.cells),
        puzzle.blackStones.length + puzzle.whiteStones.length,
      );
    });

    test('提示返回推荐着法', () async {
      final puzzle = kGomokuPuzzles.first;
      final controller = _controller(puzzle);
      await controller.requestHint();
      expect(controller.hintIndex, indexOf(7, 9));
      expect(controller.hintLoading, isFalse);
    });

    test('白棋先行成五时判失败', () async {
      final puzzle = GomokuPuzzle(
        id: 'test-white-win',
        title: '白棋成五',
        tier: PuzzleTier.advanced,
        moveLimit: 2,
        blackStones: [indexOf(0, 0)],
        whiteStones: [
          indexOf(5, 5),
          indexOf(5, 6),
          indexOf(5, 7),
          indexOf(5, 8),
        ],
        tip: '测试局面',
      );
      final controller = _controller(
        puzzle,
        aiMove: (cells, side, difficulty) async => _defendAt(indexOf(5, 9)),
      );
      controller.tapCell(indexOf(1, 1));
      await pumpEventQueue();
      expect(controller.status, PuzzleStatus.failed);
      expect(controller.failureReason, contains('白棋'));
    });
  });

  group('残局进度', () {
    test('通关记录写入并可重新加载', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PuzzleProgressService.instance;
      service.resetForTest();
      await service.load();
      expect(service.solvedCount, 0);

      await service.markSolved('p05');
      expect(service.isSolved('p05'), isTrue);

      service.resetForTest();
      await service.load();
      expect(service.isSolved('p05'), isTrue);
      expect(service.solvedCount, 1);

      await service.clear();
      expect(service.solvedCount, 0);
    });
  });
}
