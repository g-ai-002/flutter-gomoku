import 'dart:typed_data';

import '../models/move_record.dart';

/// 棋盘视图：Flame 组件只读取这些状态并回调点击，不依赖对局控制器实现。
abstract class BoardView {
  Uint8List get cells;

  List<MoveRecord> get history;

  int? get lastIndex;

  List<int> get winningLine;

  /// 走子提示的推荐点，无提示时为 null。
  int? get hintIndex;

  /// 是否在棋盘边缘绘制坐标。
  bool get showCoordinates;

  /// 当前是否允许落子（AI 思考、终局时为 false）。
  bool get canInteract;

  /// 当前行棋方，用于悬停预览的棋子颜色。
  int get sideToMove;

  /// 黑棋禁手点，供棋盘标记；未启用禁手时为空。
  Set<int> get forbiddenPoints => const {};

  void tapCell(int index);
}
