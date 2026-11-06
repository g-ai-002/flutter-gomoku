import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/search.dart';
import 'package:gomoku/game/opening_book.dart';
import 'package:gomoku/game/self_play_trainer.dart';

/// 固定 1 层搜索，保证每次训练走出同一批对局，测试结果可复现。
SelfPlayTrainer _trainer() => SelfPlayTrainer(
  search: (cells, side) => GomokuSearch.bestMove(
    cells: cells,
    side: side,
    depth: 1,
    timeLimitMillis: 200,
  ).move,
);

void main() {
  group('自对弈训练', () {
    test('训练产出与内置开局同源的八手精研线', () async {
      final report = await _trainer().run(games: 6);
      expect(report.cancelled, isFalse);
      expect(report.book.lines.length, kOpeningLines.length);
      for (final line in report.book.lines) {
        final base = kOpeningLines.firstWhere(
          (opening) => opening.id == line.opening.id,
        );
        expect(line.opening.name, '${base.name}·精研');
        expect(line.opening.moves.length, SelfPlayTrainer.sampleMoves);
        expect(line.opening.moves.take(6), base.moves);
        expect(line.wins, greaterThan(0));
      }
    });

    test('取消训练返回空结果', () async {
      final report = await _trainer().run(
        games: 2,
        isCancelled: () => true,
      );
      expect(report.cancelled, isTrue);
      expect(report.book.isEmpty, isTrue);
    });

    test('进度回调按局数与累计手数递增', () async {
      final games = <int>[];
      final plies = <int>[];
      await _trainer().run(
        games: 1,
        onProgress: (game, count) {
          games.add(game);
          plies.add(count);
        },
      );
      expect(games, isNotEmpty);
      expect(games.last, 1);
      expect(plies, orderedEquals([for (var i = 1; i <= plies.length; i++) i]));
    });
  });
}
