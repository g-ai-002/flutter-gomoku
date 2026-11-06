import 'dart:typed_data';

import '../models/move_record.dart';
import 'board_state.dart';
import 'board_view.dart';

/// 把 [GomokuBoard] 的只读状态映射为 [BoardView]，供对局、复盘与残局共用。
///
/// 各控制器只负责处理点击与异步流程，不再各自重复声明棋盘的
/// cells、history、行棋方与胜利连线等纯转发 getter。
mixin BoardViewAdapter implements BoardView {
  GomokuBoard get board;

  @override
  Uint8List get cells => board.cells;

  @override
  List<MoveRecord> get history => board.history;

  @override
  int? get lastIndex => board.lastIndex;

  @override
  List<int> get winningLine => board.winningLine;

  @override
  int get sideToMove => board.sideToMove;

  @override
  int? get hintIndex => null;

  @override
  Set<int> get forbiddenPoints => const {};

  @override
  int get revision => 0;

  @override
  bool get allowsReplace => false;
}
