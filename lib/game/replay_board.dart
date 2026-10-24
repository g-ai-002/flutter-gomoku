import '../models/game_state.dart';
import 'gomoku_board_source.dart';

/// 回放用的可变棋盘视图。
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
  }
}
