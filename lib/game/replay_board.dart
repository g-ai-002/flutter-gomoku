import '../models/game_state.dart';
import '../utils/board_utils.dart';
import 'gomoku_board_source.dart';

/// 回放用的可变棋盘视图。
///
/// 通过 [seek] 增量前进/回退，避免拖动进度条时每次都从空棋盘重放。
class ReplayBoard implements GomokuBoardSource {
  ReplayBoard(this.boardSize)
      : board = List.generate(
          boardSize,
          (_) => List<StoneColor?>.filled(boardSize, null),
        );

  @override
  final int boardSize;

  @override
  List<List<StoneColor?>> board;

  @override
  Position? lastMove;

  @override
  Position? winStart;

  @override
  Position? winEnd;

  GameStatus status = GameStatus.playing;

  int _applied = 0;

  /// 当前棋盘上已落子的手数。
  int get appliedMoves => _applied;

  @override
  bool get isPlaying => status == GameStatus.playing;

  void reset() {
    board = List.generate(
      boardSize,
      (_) => List<StoneColor?>.filled(boardSize, null),
    );
    lastMove = null;
    winStart = null;
    winEnd = null;
    status = GameStatus.playing;
    _applied = 0;
  }

  /// 把棋盘推进/回退到第 [target] 手（0 表示空棋盘）。
  ///
  /// 只应用与撤销差值部分，复杂度与移动步数成正比。
  void seek(int target, List<Move> moves) {
    final int clamped =
        target < 0 ? 0 : (target > moves.length ? moves.length : target);
    while (_applied < clamped) {
      _applyMove(moves[_applied]);
      _applied++;
    }
    while (_applied > clamped) {
      _applied--;
      _undoMove(moves[_applied]);
      lastMove = _applied > 0 ? moves[_applied - 1].position : null;
    }
  }

  void _applyMove(Move move) {
    board[move.position.row][move.position.col] = move.color;
    lastMove = move.position;
    if (status != GameStatus.playing) {
      return;
    }
    final win = BoardUtils.checkWin(board, move.position);
    if (win == null) {
      return;
    }
    winStart = win.$1;
    winEnd = win.$2;
    status = move.color == StoneColor.black
        ? GameStatus.blackWin
        : GameStatus.whiteWin;
  }

  void _undoMove(Move move) {
    board[move.position.row][move.position.col] = null;
    winStart = null;
    winEnd = null;
    status = GameStatus.playing;
  }
}
