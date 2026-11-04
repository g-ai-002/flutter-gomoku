/// 一步已落子的记录。
class MoveRecord {
  const MoveRecord({
    required this.index,
    required this.side,
    required this.notation,
    required this.moveNumber,
  });

  /// 交叉点线性下标。
  final int index;
  final int side;

  /// 坐标记法，例如 `H8`。
  final String notation;

  /// 从 1 开始的着法序号。
  final int moveNumber;
}
