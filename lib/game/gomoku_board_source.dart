import '../models/game_state.dart';

/// 棋盘只读视图：对局与回放共用同一套 Flame 组件。
abstract class GomokuBoardSource {
  int get boardSize;
  List<List<StoneColor?>> get board;
  Position? get lastMove;
  Position? get winStart;
  Position? get winEnd;
  bool get isPlaying;
}
