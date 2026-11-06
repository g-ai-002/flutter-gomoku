import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/engine/search.dart';
import 'package:gomoku/game/game_controller.dart';
import 'package:gomoku/game/opening_book.dart';
import 'package:gomoku/models/game_models.dart';

const _fallback = SearchResult(move: 0, score: 0, depth: 1, nodes: 1);

Future<void> _waitBook() =>
    Future<void>.delayed(const Duration(milliseconds: 320));

GameController _controller({
  OpeningBook? book,
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
    openingBook: book,
    aiMove:
        aiMove ??
        (cells, side, difficulty, {bool? forbidBlack}) async {
          fail('开局库阶段不应调用搜索引擎');
        },
    hintMove: (cells, side, {bool? forbidBlack}) async => indexOf(0, 0),
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('开局库数据', () {
    test('每条开局从天元起手且六手互不重复', () {
      expect(kOpeningLines.length, 6);
      for (final line in kOpeningLines) {
        expect(line.moves.length, 6, reason: line.name);
        expect(line.moves.first, centerIndex, reason: line.name);
        expect(line.moves.toSet().length, 6, reason: line.name);
        expect(line.name, anyOf(startsWith('直指'), startsWith('斜指')));
      }
    });

    test('直指与斜指各三条', () {
      expect(
        kOpeningLines.where((line) => line.name.startsWith('直指')).length,
        3,
      );
      expect(
        kOpeningLines.where((line) => line.name.startsWith('斜指')).length,
        3,
      );
    });

    test('候选开局按前两手收敛', () {
      final book = OpeningBook.standard;
      expect(book.candidates(const []).length, 6);
      expect(book.candidates([centerIndex]).length, 6);
      expect(book.candidates([centerIndex, indexOf(7, 8)]).length, 3);
      expect(book.candidates([centerIndex, indexOf(8, 8)]).length, 3);
      final full = [...kOpeningLines.first.moves];
      expect(book.candidates(full).length, 1);
      expect(book.candidates([...full, indexOf(0, 0)]), isEmpty);
    });

    test('脱谱着法返回空匹配', () {
      final book = OpeningBook.standard;
      expect(book.candidates([centerIndex, indexOf(0, 0)]), isEmpty);
      expect(book.match([centerIndex, indexOf(0, 0)]), isNull);
    });
  });

  group('对局开局提示', () {
    test('前三手后显示开局名并给出下一手参考', () {
      final line = kOpeningLines.first;
      final book = OpeningBook([line]);
      final match = book.match([...line.moves.take(3)])!;
      expect(match.name, line.name);
      expect(match.nextMove, line.moves[3]);
      expect(book.match([...line.moves.take(2)])!.name, isNull);
      expect(book.match([...line.moves])!.nextMove, isNull);
    });

    test('开局阶段 AI 直接走棋谱着法', () async {
      final line = kOpeningLines.first;
      final controller = _controller(book: OpeningBook([line]));
      controller.start();

      await controller.requestHint();
      expect(controller.hintIndex, line.moves[0]);
      controller.tapCell(line.moves[0]);
      expect(controller.thinking, isTrue);
      await _waitBook();

      expect(controller.history.length, 2);
      expect(controller.history.last.index, line.moves[1]);
      expect(controller.openingName, isNull);

      await controller.requestHint();
      expect(controller.hintIndex, line.moves[2]);
      controller.tapCell(line.moves[2]);
      await _waitBook();

      expect(controller.history.length, 4);
      expect(controller.history.last.index, line.moves[3]);
      expect(controller.openingName, line.name);
    });

    test('走满六手后开局提示退回搜索引擎', () async {
      final line = kOpeningLines.first;
      var searched = 0;
      final controller = _controller(
        book: OpeningBook([line]),
        aiMove: (cells, side, difficulty, {bool? forbidBlack}) async {
          searched++;
          return _fallback;
        },
      );
      controller.start();
      for (var ply = 0; ply < 6; ply++) {
        if (ply.isEven) {
          controller.tapCell(line.moves[ply]);
        } else {
          await _waitBook();
        }
      }
      expect(controller.history.length, 6);
      expect(searched, 0);

      await controller.requestHint();
      expect(controller.hintIndex, indexOf(0, 0));
    });

    test('脱谱后清空开局名并改由引擎应对', () async {
      final line = kOpeningLines.first;
      var searched = 0;
      final controller = _controller(
        book: OpeningBook([line]),
        aiMove: (cells, side, difficulty, {bool? forbidBlack}) async {
          searched++;
          return const SearchResult(move: 0, score: 0, depth: 1, nodes: 1);
        },
      );
      controller.start();
      controller.tapCell(line.moves[0]);
      await _waitBook();
      expect(controller.history.length, 2);

      controller.tapCell(indexOf(0, 0));
      await pumpEventQueue();
      expect(searched, 1);
      expect(controller.openingName, isNull);
      expect(controller.openingMatch, isNull);
    });

    test('重开后重新从开局库起手', () async {
      final line = kOpeningLines.first;
      final controller = _controller(book: OpeningBook([line]));
      controller.start();
      controller.tapCell(line.moves[0]);
      await _waitBook();
      controller.restart();
      expect(controller.history, isEmpty);
      expect(controller.board.sideToMove, black);

      await controller.requestHint();
      expect(controller.hintIndex, line.moves[0]);
    });

    test('精研线替换内置开局后 AI 走延伸着法', () async {
      final base = kOpeningLines.first;
      final moves = [...base.moves, indexOf(7, 9), indexOf(8, 7)];
      final book = OpeningBook([
        OpeningLine(id: base.id, name: '${base.name}·精研', moves: moves),
      ]);
      final controller = _controller(book: book);
      controller.start();
      for (var ply = 0; ply < 6; ply++) {
        if (ply.isEven) {
          controller.tapCell(moves[ply]);
        } else {
          await _waitBook();
        }
      }
      expect(controller.history.length, 6);
      expect(controller.openingName, '${base.name}·精研');

      controller.tapCell(moves[6]);
      await _waitBook();
      expect(controller.history.length, 8);
      expect(controller.history.last.index, moves[7]);
    });
  });
}
