import 'dart:typed_data';

import 'board_state.dart';
import 'engine/rules.dart';
import 'engine/search.dart';
import 'learned_book.dart';
import 'opening_book.dart';

/// 自对弈训练结果：学到的精研开局，以及训练是否被中途取消。
class TrainingReport {
  const TrainingReport({required this.book, this.cancelled = false});

  final LearnedBook book;
  final bool cancelled;
}

/// 自对弈训练器：以六条内置开局为种子，双方 AI 对弈到分出胜负，
/// 把胜方前八手按开局聚合，出现次数最多的延伸写入精研库。
class SelfPlayTrainer {
  SelfPlayTrainer({int Function(Uint8List cells, int side)? search})
    : _search = search ?? _defaultSearch;

  /// 精研线保留的手数：前六手来自内置开局，后两手来自胜方棋谱。
  static const int sampleMoves = 8;

  /// 单局手数上限，避免长局拖慢训练。
  static const int maxPlies = 60;

  final int Function(Uint8List cells, int side) _search;

  static int _defaultSearch(Uint8List cells, int side) => GomokuSearch.bestMove(
    cells: cells,
    side: side,
    depth: 2,
    randomness: 600,
    timeLimitMillis: 200,
  ).move;

  /// 训练 [games] 局；每一步之间让出事件循环，界面可刷新进度并取消。
  Future<TrainingReport> run({
    int games = 8,
    void Function(int game, int plies)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final tally = <String, Map<String, int>>{};
    var plies = 0;

    for (var game = 0; game < games; game++) {
      final opening = kOpeningLines[game % kOpeningLines.length];
      final board = GomokuBoard();
      for (final move in opening.moves) {
        board.apply(move);
      }
      while (board.winner == null &&
          !board.isFull &&
          board.history.length < maxPlies) {
        if (isCancelled?.call() ?? false) {
          return const TrainingReport(book: LearnedBook.empty, cancelled: true);
        }
        final side = board.sideToMove;
        final cells = Uint8List.fromList(board.cells);
        final move = GomokuRules.pickMove(cells, side, _search(cells, side));
        if (move == null) break;
        board.apply(move);
        plies++;
        onProgress?.call(game + 1, plies);
        await Future<void>.delayed(Duration.zero);
      }
      if (board.winner == null || board.history.length < sampleMoves) continue;
      final key = [
        for (final record in board.history.take(sampleMoves)) record.index,
      ].join('.');
      final bucket = tally.putIfAbsent(opening.id, () => {});
      bucket[key] = (bucket[key] ?? 0) + 1;
    }

    final lines = <LearnedLine>[];
    for (final opening in kOpeningLines) {
      final bucket = tally[opening.id];
      if (bucket == null || bucket.isEmpty) continue;
      final best = bucket.entries.reduce((a, b) => a.value >= b.value ? a : b);
      lines.add((
        opening: OpeningLine(
          id: opening.id,
          name: '${opening.name}·精研',
          moves: [for (final token in best.key.split('.')) int.parse(token)],
        ),
        wins: best.value,
      ));
    }
    return TrainingReport(book: LearnedBook(lines));
  }
}
