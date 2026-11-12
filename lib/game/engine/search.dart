import 'dart:math' as math;
import 'dart:typed_data';

import 'board_utils.dart';
import 'evaluation.dart';
import 'forbidden.dart';
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
    bool forbidBlack = false,
  }) {
    final board = Uint8List.fromList(cells);
    final searcher = _Searcher(board, math.max(100, timeLimitMillis));

    // 只在根节点过滤黑棋禁手：保证最终着法合法，深层仍按无禁手估值，
    // 避免每个节点都做禁手判定拖慢搜索。
    final candidates = forbidBlack
        ? GomokuForbidden.legalMoves(
            board,
            side,
            GomokuRules.candidateMoves(board),
          )
        : GomokuRules.candidateMoves(board);
    if (candidates.isEmpty) {
      return const SearchResult(move: -1, score: 0, depth: 0, nodes: 0);
    }
    final wins = GomokuRules.immediateWins(board, side, candidates: candidates);
    if (wins.isNotEmpty) {
      return SearchResult(
        move: wins.first,
        score: winScore,
        depth: 1,
        nodes: wins.length,
      );
    }
    final opponent = opponentOf(side);
    final blocks = GomokuRules.immediateWins(
      board,
      opponent,
      candidates: candidates,
    );
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
        final scored = searcher.searchRoot(
          roots,
          side,
          current,
          tolerance: randomness,
        );
        if (scored.isEmpty) break;
        scored.sort((a, b) => b.score.compareTo(a.score));
        bestScore = scored.first.score;
        completedDepth = current;
        final pool = scored
            .where((entry) => entry.score >= bestScore - randomness)
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

class _Searcher {
  _Searcher(this.board, int timeLimitMillis)
    : _watch = Stopwatch()..start(),
      _timeLimitMillis = timeLimitMillis,
      _scores = LineScoreBoard(board);

  final Uint8List board;
  final Stopwatch _watch;
  final int _timeLimitMillis;
  final LineScoreBoard _scores;
  int nodes = 0;

  bool get _expired => _watch.elapsedMilliseconds >= _timeLimitMillis;

  /// 从 [side] 视角取棋型分，与 [GomokuEvaluation.evaluate] 口径一致。
  int _evaluate(int side) {
    final total = _scores.total;
    return total[side - 1] - (total[opponentOf(side) - 1] * 1.05).round();
  }

  /// 按双方在该点的形态分取出前 [limit] 个着法。
  ///
  /// 逐点插入有序缓冲：每个搜索节点只需保留前 [limit] 个候选，
  /// 不必构造整份评分列表再整体排序，避免大量临时对象与比较开销。
  List<int> ordered(List<int> moves, int side, {required int limit}) {
    final count = math.min(limit, moves.length);
    if (count == 0) return const [];
    final opponent = opponentOf(side);
    final picked = List<int>.filled(count, 0);
    final scores = Int32List(count);
    var size = 0;
    for (final move in moves) {
      board[move] = side;
      final own = GomokuEvaluation.pointScore(board, move, side);
      board[move] = empty;
      final defense = GomokuEvaluation.pointScore(board, move, opponent);
      final score = own * 2 + defense;
      if (size == count && score <= scores[count - 1]) continue;
      var at = size < count ? size++ : count - 1;
      while (at > 0 && scores[at - 1] < score) {
        scores[at] = scores[at - 1];
        picked[at] = picked[at - 1];
        at--;
      }
      scores[at] = score;
      picked[at] = move;
    }
    return picked;
  }

  /// 根节点：逐个候选着法搜索，返回评分列表供随机度筛选。
  ///
  /// [tolerance] 是评分容差：劣于当前最优超过容差的着法用窗口直接剪掉、
  /// 不再完整搜索，因此返回的列表可能只含仍有希望的着法。
  List<({int move, int score})> searchRoot(
    List<int> roots,
    int side,
    int depth, {
    int tolerance = 0,
  }) {
    final results = <({int move, int score})>[];
    var floor = -_infinity;
    for (final move in roots) {
      if (_expired) throw const _SearchTimeout();
      board[move] = side;
      _scores.update(move);
      int score;
      if (GomokuRules.hasFive(board, move, side)) {
        score = GomokuSearch.winScore;
      } else {
        score = -_negamax(opponentOf(side), depth - 1, -_infinity, -floor, 1);
      }
      board[move] = empty;
      _scores.update(move);
      if (score <= floor) continue;
      results.add((move: move, score: score));
      final bound = score - tolerance;
      if (bound > floor) floor = bound;
    }
    return results;
  }

  int _negamax(int side, int depth, int alpha, int beta, int ply) {
    nodes++;
    if ((nodes & 511) == 0 && _expired) throw const _SearchTimeout();
    if (depth <= 0) return _evaluate(side);

    final moves = GomokuRules.candidateMoves(board);
    if (moves.isEmpty) return 0;
    final orderedMoves = ordered(moves, side, limit: 12);
    var best = -_infinity;
    for (final move in orderedMoves) {
      board[move] = side;
      _scores.update(move);
      int score;
      if (GomokuRules.hasFive(board, move, side)) {
        score = GomokuSearch.winScore - ply;
      } else {
        score = -_negamax(opponentOf(side), depth - 1, -beta, -alpha, ply + 1);
      }
      board[move] = empty;
      _scores.update(move);
      if (score > best) best = score;
      if (score > alpha) alpha = score;
      if (alpha >= beta) break;
    }
    return best;
  }
}
