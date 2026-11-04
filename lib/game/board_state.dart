import 'dart:typed_data';

import '../models/move_record.dart';
import 'engine/board_utils.dart';
import 'engine/rules.dart';
import 'notation.dart';

/// 可撤销的五子棋棋局状态。
class GomokuBoard {
  GomokuBoard() : cells = emptyCells(), sideToMove = black;

  /// 从既有局面构造，供测试与棋谱导入使用。
  GomokuBoard.fromCells(Uint8List source, {this.sideToMove = black})
    : cells = Uint8List.fromList(source) {
    _adoptWinningLine();
  }

  final Uint8List cells;
  int sideToMove;
  final List<MoveRecord> history = [];
  int? lastIndex;
  List<int> winningLine = const [];
  int? winner;

  /// 落子并返回记录；非空点或越界返回 null。
  MoveRecord? apply(int index) {
    if (index < 0 || index >= cellCount || cells[index] != empty) return null;
    final side = sideToMove;
    cells[index] = side;
    sideToMove = opponentOf(side);
    final record = MoveRecord(
      index: index,
      side: side,
      notation: MoveNotation.describe(index),
      moveNumber: history.length + 1,
    );
    history.add(record);
    lastIndex = index;
    final line = GomokuRules.winningLineAt(cells, index, side);
    if (line.isNotEmpty) {
      winningLine = line;
      winner = side;
    }
    return record;
  }

  /// 导入棋谱时逐手重演，非法着法返回 false 并保留已重演部分。
  bool replay(Iterable<int> moves) {
    for (final move in moves) {
      if (apply(move) == null) return false;
    }
    return true;
  }

  void reset() {
    cells.fillRange(0, cellCount, empty);
    sideToMove = black;
    history.clear();
    lastIndex = null;
    winningLine = const [];
    winner = null;
  }

  MoveRecord? undoLast() {
    if (history.isEmpty) return null;
    final record = history.removeLast();
    cells[record.index] = empty;
    sideToMove = record.side;
    lastIndex = history.isEmpty ? null : history.last.index;
    winningLine = const [];
    winner = null;
    return record;
  }

  bool get isFull => stoneCount(cells) >= cellCount;

  int get stoneTotal => history.length;

  /// 供棋谱导入与复盘校验：当前局面是否仍有五连。
  void _adoptWinningLine() {
    for (var index = 0; index < cellCount; index++) {
      final side = cells[index];
      if (side == empty) continue;
      final line = GomokuRules.winningLineAt(cells, index, side);
      if (line.isNotEmpty) {
        winningLine = line;
        winner = side;
        return;
      }
    }
  }
}
