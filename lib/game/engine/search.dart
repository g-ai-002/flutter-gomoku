import 'dart:math' as math;
import 'dart:typed_data';

import 'board_utils.dart';
import 'evaluation.dart';
import 'rules.dart';

/// 搜索回包：最佳着法、评分、实际完成层数与节点数。
class SearchResult {
  const SearchResult({
    required this.move,
    required this.score,
    required this.depth,
    required this.nodes,
  });

  final int move;
  final int score;
  final int depth;
  final int nodes;
}

const int _infinity = 1 << 30;

class _SearchTimeout implements Exception {
  const _SearchTimeout();
}

/// 棋型评估 + Alpha-Beta 搜索。
///
/// 先处理「一手成五」与「必须封堵对手成五」的战术着法，再做迭代加深；
/// 候选点限定在已有棋子附近两格，并按双方形态分排序，同等时间下算得更深。
class GomokuSearch {
  GomokuSearch._();

  static const int winScore = 100000000;

  static SearchResult bestMove({
    required Uint8List cells,
    required int side,
    required int depth,
    int randomness = 0,
    int timeLimitMillis = 4000,
    math.Random? random,
  }) {
    final board = Uint8List.fromList(cells);
    final searcher = _Searcher(board, math.max(100, timeLimitMillis));

    final wins = GomokuRules.immediateWins(board, side);
    if (wins.isNotEmpty) {
      return SearchResult(
        move: wins.first,
        score: winScore,
        depth: 1,
        nodes: wins.length,
      );
    }
    final opponent = opponentOf(side);
    final blocks = GomokuRules.immediateWins(board, opponent);
    final candidates = GomokuRules.candidateMoves(board);
    if (candidates.isEmpty) {
      return const SearchResult(move: -1, score: 0, depth: 0, nodes: 0);
    }
    final roots = searcher.ordered(
      blocks.isNotEmpty ? blocks : candidates,
      side,
      limit: blocks.isNotEmpty ? blocks.length : 20,
    );

    var bestMove = roots.first;
    var bestScore = -_infinity;
    var completedDepth = 0;
    final maxDepth = math.max(1, depth);
    for (var current = 1; current <= maxDepth; current++) {
      try {
        final scored = searcher.searchRoot(roots, side, current);
        if (scored.isEmpty) break;
        scored.sort((a, b) => b.score.compareTo(a.score));
        bestScore = scored.first.score;
        completedDepth = current;
        final tolerance = randomness;
        final pool = scored
            .where((entry) => entry.score >= bestScore - tolerance)
            .toList();
        final pick = (random ?? math.Random()).nextInt(pool.length);
        bestMove = pool[pick].move;
        if (bestScore >= winScore - 1000) break;
      } on _SearchTimeout {
        break;
      }
    }

    return SearchResult(
      move: bestMove,
      score: bestScore == -_infinity ? 0 : bestScore,
      depth: completedDepth,
      nodes: searcher.nodes,
    );
  }
}

class _ScoredMove {
  const _ScoredMove(this.move, this.score);

  final int move;
  final int score;
}

class _Searcher {
  _Searcher(this.board, int timeLimitMillis)
    : _watch = Stopwatch()..start(),
      _timeLimitMillis = timeLimitMillis;

  final Uint8List board;
  final Stopwatch _watch;
  final int _timeLimitMillis;
  int nodes = 0;

  bool get _expired => _watch.elapsedMilliseconds >= _timeLimitMillis;

  /// 按双方在该点的形态分排序，截取前 [limit] 个。
  List<int> ordered(List<int> moves, int side, {required int limit}) {
    final opponent = opponentOf(side);
    final scored = <_ScoredMove>[];
    for (final move in moves) {
      board[move] = side;
      final own = GomokuEvaluation.pointScore(board, move, side);
      board[move] = empty;
      final defense = GomokuEvaluation.pointScore(board, move, opponent);
      scored.add(_ScoredMove(move, own * 2 + defense));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    final count = math.min(limit, scored.length);
    return [for (var i = 0; i < count; i++) scored[i].move];
  }

  /// 根节点：逐个候选着法搜索，返回评分列表供随机度筛选。
  List<_ScoredMove> searchRoot(List<int> roots, int side, int depth) {
    final results = <_ScoredMove>[];
    for (final move in roots) {
      if (_expired) throw const _SearchTimeout();
      board[move] = side;
      int score;
      if (GomokuRules.hasFive(board, move, side)) {
        score = GomokuSearch.winScore;
      } else {
        score = -_negamax(
          opponentOf(side),
          depth - 1,
          -_infinity,
          _infinity,
          1,
        );
      }
      board[move] = empty;
      results.add(_ScoredMove(move, score));
    }
    return results;
  }

  int _negamax(int side, int depth, int alpha, int beta, int ply) {
    nodes++;
    if ((nodes & 511) == 0 && _expired) throw const _SearchTimeout();
    if (depth <= 0) return GomokuEvaluation.evaluate(board, side);

    final moves = GomokuRules.candidateMoves(board);
    if (moves.isEmpty) return 0;
    final orderedMoves = ordered(moves, side, limit: 12);
    var best = -_infinity;
    for (final move in orderedMoves) {
      board[move] = side;
      int score;
      if (GomokuRules.hasFive(board, move, side)) {
        score = GomokuSearch.winScore - ply;
      } else {
        score = -_negamax(opponentOf(side), depth - 1, -beta, -alpha, ply + 1);
      }
      board[move] = empty;
      if (score > best) best = score;
      if (score > alpha) alpha = score;
      if (alpha >= beta) break;
    }
    return best;
  }
}
