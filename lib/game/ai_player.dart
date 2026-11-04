import 'package:flutter/foundation.dart';

import '../models/game_models.dart';
import 'engine/search.dart';

/// AI 搜索回包直接复用引擎结果，避免两套同构类型。
typedef AiReply = SearchResult;

typedef AiMoveProvider = Future<AiReply> Function(
  Uint8List cells,
  int side,
  Difficulty difficulty, {
  bool? forbidBlack,
});

/// 走子提示：返回推荐的交叉点，无可用着法时返回 null。
typedef HintMoveProvider = Future<int?> Function(
  Uint8List cells,
  int side, {
  bool? forbidBlack,
});

/// 一次 AI 搜索的摘要，供界面展示引擎状态。
class AiInsight {
  const AiInsight({required this.reply, required this.millis});

  factory AiInsight.of(SearchResult reply, Duration elapsed) =>
      AiInsight(reply: reply, millis: elapsed.inMilliseconds);

  final AiReply reply;
  final int millis;

  int get depth => reply.depth;
  int get nodes => reply.nodes;
  int get score => reply.score;

  /// 状态条上的紧凑文案，例如 `AI 第 4 层 · 1.2s`。
  String get label => 'AI 第 $depth 层 · ${(millis / 1000).toStringAsFixed(1)}s';

  String get detail => '节点 $nodes · 评分 $score';
}

class AiPlayer {
  AiPlayer._();

  /// 在独立 isolate 中搜索（Web 上自动退化为同线程执行）。
  ///
  /// [forbidBlack] 为 true 时黑棋不会选择三三、四四与长连等禁手着法。
  static Future<AiReply> chooseMove(
    Uint8List cells,
    int side,
    Difficulty difficulty, {
    bool? forbidBlack,
  }) {
    return compute(
      _runSearch,
      _AiRequest(
        Uint8List.fromList(cells),
        side,
        difficulty.depth,
        difficulty.randomness,
        difficulty.timeLimitMillis,
        forbidBlack ?? false,
      ),
    );
  }

  /// 走子提示：浅层搜索，不引入随机性。
  static Future<int?> hintMove(
    Uint8List cells,
    int side, {
    bool? forbidBlack,
  }) async {
    final reply = await compute(
      _runSearch,
      _AiRequest(
        Uint8List.fromList(cells),
        side,
        3,
        0,
        1200,
        forbidBlack ?? false,
      ),
    );
    return reply.move >= 0 ? reply.move : null;
  }
}

class _AiRequest {
  const _AiRequest(
    this.cells,
    this.side,
    this.depth,
    this.randomness,
    this.timeLimitMillis,
    this.forbidBlack,
  );

  final Uint8List cells;
  final int side;
  final int depth;
  final int randomness;
  final int timeLimitMillis;
  final bool forbidBlack;
}

SearchResult _runSearch(_AiRequest request) => GomokuSearch.bestMove(
  cells: request.cells,
  side: request.side,
  depth: request.depth,
  randomness: request.randomness,
  timeLimitMillis: request.timeLimitMillis,
  forbidBlack: request.forbidBlack,
);
