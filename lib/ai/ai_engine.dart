import 'dart:math';
import '../models/game_state.dart';
import '../utils/board_utils.dart';

/// AI 难度
enum AIDifficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case AIDifficulty.easy:
        return '简单';
      case AIDifficulty.medium:
        return '中等';
      case AIDifficulty.hard:
        return '困难';
    }
  }
}

/// 五子棋 AI 引擎
class GomokuAI {
  final AIDifficulty difficulty;
  final Random _random = Random();

  GomokuAI(this.difficulty);

  // ---- 评分常量 ----
  static const int _winScore = 1000000;
  static const int _liveFourScore = 100000;
  static const int _deadFourScore = 10000;
  static const int _liveThreeScore = 10000;
  static const int _deadThreeScore = 1000;
  static const int _liveTwoScore = 1000;
  static const int _deadTwoScore = 100;
  static const int _liveOneScore = 100;
  static const int _deadOneScore = 10;
  static const int _minScore = -99999999;
  static const int _maxScore = 99999999;

  /// Minimax 搜索深度
  static const int _searchDepth = 3;

  /// 候选位置数量上限
  static const int _candidateLimit = 15;

  /// 候选位置搜索范围（已有棋子周围格数）
  static const int _candidateRange = 2;

  /// 寻找最佳落子位置
  Position? findBestMove(GameState state) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return _easyMove(state);
      case AIDifficulty.medium:
        return _mediumMove(state);
      case AIDifficulty.hard:
        return _hardMove(state);
    }
  }

  /// 简单：随机落子
  Position? _easyMove(GameState state) {
    final empty = <Position>[];
    for (int r = 0; r < state.boardSize; r++) {
      for (int c = 0; c < state.boardSize; c++) {
        if (state.board[r][c] == null) empty.add(Position(r, c));
      }
    }
    if (empty.isEmpty) return null;
    return empty[_random.nextInt(empty.length)];
  }

  /// 中等：评分策略
  Position? _mediumMove(GameState state) {
    return _bestByScore(state, state.currentPlayer);
  }

  /// 困难：Minimax + Alpha-Beta 剪枝
  Position? _hardMove(GameState state) {
    final aiColor = state.currentPlayer;
    final candidates = _getCandidateMoves(state);
    if (candidates.isEmpty) return null;

    int bestScore = _minScore;
    Position? best;

    for (final pos in candidates) {
      final newBoard = BoardUtils.copyBoard(state.board);
      newBoard[pos.row][pos.col] = aiColor;
      final newState = state.copyWith(
        board: newBoard,
        currentPlayer: aiColor.opponent,
        lastMove: pos,
      );
      final score = _minimax(newState, _searchDepth, _minScore, _maxScore, false, aiColor);
      if (score > bestScore) {
        bestScore = score;
        best = pos;
      }
    }
    return best;
  }

  /// Minimax 搜索
  int _minimax(
    GameState state,
    int depth,
    int alpha,
    int beta,
    bool isMaximizing,
    StoneColor aiColor,
  ) {
    final winCheck = BoardUtils.checkWin(state.board, state.lastMove ?? const Position(-1, -1));
    if (winCheck != null) {
      final winner = state.board[winCheck.$1.row][winCheck.$1.col];
      return winner == aiColor ? _winScore + depth : -_winScore - depth;
    }

    if (depth == 0) {
      return _evaluateBoard(state.board, aiColor);
    }

    final candidates = _getCandidateMoves(state);
    if (candidates.isEmpty) return 0;

    if (isMaximizing) {
      int maxScore = _minScore;
      for (final pos in candidates) {
        final newBoard = BoardUtils.copyBoard(state.board);
        newBoard[pos.row][pos.col] = aiColor;
        final newState = state.copyWith(
          board: newBoard,
          currentPlayer: aiColor.opponent,
          lastMove: pos,
        );
        final score = _minimax(newState, depth - 1, alpha, beta, false, aiColor);
        maxScore = max(maxScore, score);
        alpha = max(alpha, score);
        if (beta <= alpha) break;
      }
      return maxScore;
    } else {
      int minScore = _maxScore;
      final opponent = aiColor.opponent;
      for (final pos in candidates) {
        final newBoard = BoardUtils.copyBoard(state.board);
        newBoard[pos.row][pos.col] = opponent;
        final newState = state.copyWith(
          board: newBoard,
          currentPlayer: aiColor,
          lastMove: pos,
        );
        final score = _minimax(newState, depth - 1, alpha, beta, true, aiColor);
        minScore = min(minScore, score);
        beta = min(beta, score);
        if (beta <= alpha) break;
      }
      return minScore;
    }
  }

  /// 获取候选落子位置（已有棋子周围 N 格内）
  List<Position> _getCandidateMoves(GameState state) {
    final size = state.boardSize;
    final candidates = <Position>{};
    bool hasStone = false;

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (state.board[r][c] != null) {
          hasStone = true;
          for (int dr = -_candidateRange; dr <= _candidateRange; dr++) {
            for (int dc = -_candidateRange; dc <= _candidateRange; dc++) {
              final nr = r + dr;
              final nc = c + dc;
              if (nr >= 0 && nr < size && nc >= 0 && nc < size && state.board[nr][nc] == null) {
                candidates.add(Position(nr, nc));
              }
            }
          }
        }
      }
    }

    if (!hasStone) {
      final center = size ~/ 2;
      return [Position(center, center)];
    }

    final list = candidates.toList();
    // 按评分排序，取前 N 个减少搜索空间
    list.sort((a, b) {
      final scoreA = _quickScore(state.board, a, state.currentPlayer);
      final scoreB = _quickScore(state.board, b, state.currentPlayer);
      return scoreB.compareTo(scoreA);
    });
    return list.take(_candidateLimit).toList();
  }

  /// 快速评分（用于候选排序）
  int _quickScore(List<List<StoneColor?>> board, Position pos, StoneColor color) {
    int score = 0;
    final size = board.length;

    for (final (dr, dc) in BoardUtils.directions) {
      int count = 1;
      int openEnds = 0;

      int r = pos.row + dr;
      int c = pos.col + dc;
      while (r >= 0 && r < size && c >= 0 && c < size && board[r][c] == color) {
        count++;
        r += dr;
        c += dc;
      }
      if (r >= 0 && r < size && c >= 0 && c < size && board[r][c] == null) openEnds++;

      r = pos.row - dr;
      c = pos.col - dc;
      while (r >= 0 && r < size && c >= 0 && c < size && board[r][c] == color) {
        count++;
        r -= dr;
        c -= dc;
      }
      if (r >= 0 && r < size && c >= 0 && c < size && board[r][c] == null) openEnds++;

      score += _patternScore(count, openEnds);
    }
    return score;
  }

  /// 评分策略：对每个空位打分
  Position? _bestByScore(GameState state, StoneColor color) {
    final size = state.boardSize;
    Position? best;
    int bestScore = -1;

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (state.board[r][c] != null) continue;
        final attackScore = _quickScore(state.board, Position(r, c), color);
        final defendScore = _quickScore(state.board, Position(r, c), color.opponent);
        final score = max(attackScore, defendScore);
        if (score > bestScore) {
          bestScore = score;
          best = Position(r, c);
        }
      }
    }
    return best;
  }

  /// 棋盘评估
  int _evaluateBoard(List<List<StoneColor?>> board, StoneColor aiColor) {
    int score = 0;
    final size = board.length;
    final opponent = aiColor.opponent;

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final stone = board[r][c];
        if (stone == null) continue;

        for (final (dr, dc) in BoardUtils.directions) {
          // 只从每个方向的起点开始计数（避免重复）
          final pr = r - dr;
          final pc = c - dc;
          if (pr >= 0 && pr < size && pc >= 0 && pc < size && board[pr][pc] == stone) {
            continue;
          }

          int count = 1;
          int openEnds = 0;

          int nr = r + dr;
          int nc = c + dc;
          while (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == stone) {
            count++;
            nr += dr;
            nc += dc;
          }
          if (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == null) {
            openEnds++;
          }

          if (pr >= 0 && pr < size && pc >= 0 && pc < size && board[pr][pc] == null) {
            openEnds++;
          }

          final lineScore = _patternScore(count, openEnds);
          if (stone == aiColor) {
            score += lineScore;
          } else {
            score -= lineScore;
          }
        }
      }
    }
    return score;
  }

  /// 模式评分
  int _patternScore(int count, int openEnds) {
    if (count >= 5) return _winScore;
    if (openEnds == 0) return 0;

    switch (count) {
      case 4:
        return openEnds == 2 ? _liveFourScore : _deadFourScore;
      case 3:
        return openEnds == 2 ? _liveThreeScore : _deadThreeScore;
      case 2:
        return openEnds == 2 ? _liveTwoScore : _deadTwoScore;
      case 1:
        return openEnds == 2 ? _liveOneScore : _deadOneScore;
      default:
        return 0;
    }
  }
}
