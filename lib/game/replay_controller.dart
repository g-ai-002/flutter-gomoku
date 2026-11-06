import 'package:flutter/foundation.dart';

import '../models/move_record.dart';
import 'board_state.dart';
import 'board_view.dart';
import 'handicap.dart';

/// 复盘控制器：按步回放一局棋谱，棋盘从开局局面逐着重演。
class ReplayController extends ChangeNotifier implements BoardView {
  ReplayController({
    required List<MoveRecord> moves,
    this.handicap = Handicap.none,
  }) : moves = List.unmodifiable(moves) {
    _validate();
    _board = GomokuBoard(handicap: handicap);
  }

  /// 完整棋谱，超出当前进度的部分视为「未来」。
  final List<MoveRecord> moves;

  /// 该局使用的让子方案，重演前先预置黑子。
  final Handicap handicap;

  late GomokuBoard _board;
  int _cursor = 0;

  GomokuBoard get board => _board;

  int get cursor => _cursor;

  int get total => moves.length;

  bool get canPrevious => _cursor > 0;

  bool get canNext => _cursor < moves.length;

  /// 自动回放是否已到终局。
  bool get finished => !canNext;

  String get progressText => '第 $_cursor / $total 手';

  @override
  Uint8List get cells => _board.cells;

  @override
  List<MoveRecord> get history => _board.history;

  @override
  int? get lastIndex => _board.lastIndex;

  @override
  List<int> get winningLine => _board.winningLine;

  @override
  int? get hintIndex => null;

  @override
  bool get showCoordinates => true;

  @override
  Set<int> get forbiddenPoints => const {};

  @override
  bool get allowsReplace => false;

  @override
  int get revision => 0;

  @override
  bool get canInteract => false;

  @override
  int get sideToMove => _board.sideToMove;

  void next() => jumpTo(_cursor + 1);

  void previous() => jumpTo(_cursor - 1);

  void first() => jumpTo(0);

  void last() => jumpTo(moves.length);

  /// 跳到第 [cursor] 手之后（0 为开局局面），越界时自动收敛。
  ///
  /// 后退时回到空盘重演，避免维护逆向着法。
  void jumpTo(int cursor) {
    final target = cursor.clamp(0, moves.length);
    if (target == _cursor) return;
    if (target < _cursor) {
      _board = GomokuBoard(handicap: handicap);
      _cursor = 0;
    }
    while (_cursor < target) {
      if (_board.apply(moves[_cursor].index) == null) {
        throw ArgumentError(
          '第 ${_cursor + 1} 手「${moves[_cursor].notation}」不是合法着法',
        );
      }
      _cursor++;
    }
    notifyListeners();
  }

  @override
  void tapCell(int index) {}

  /// 构造时整体校验一遍，非法棋谱在进入复盘页前就暴露出来。
  void _validate() {
    final board = GomokuBoard(handicap: handicap);
    for (var index = 0; index < moves.length; index++) {
      if (board.apply(moves[index].index) == null) {
        throw ArgumentError('第 ${index + 1} 手「${moves[index].notation}」不是合法着法');
      }
    }
  }
}
