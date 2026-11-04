import 'dart:typed_data';

import 'board_utils.dart';

/// 五子棋规则：五连判定、满盘判和与候选点生成。
class GomokuRules {
  GomokuRules._();

  /// 若 [index] 处的落子构成五连，返回构成连线的所有交叉点（可能长于五子）。
  static List<int> winningLineAt(Uint8List cells, int index, int side) {
    if (index < 0 || index >= cellCount || cells[index] != side) {
      return const [];
    }
    final row = rowOf(index);
    final col = colOf(index);
    for (final (dr, dc) in kDirections) {
      final line = <int>[index];
      var r = row - dr;
      var c = col - dc;
      while (inBoard(r, c) && cells[indexOf(r, c)] == side) {
        line.insert(0, indexOf(r, c));
        r -= dr;
        c -= dc;
      }
      r = row + dr;
      c = col + dc;
      while (inBoard(r, c) && cells[indexOf(r, c)] == side) {
        line.add(indexOf(r, c));
        r += dr;
        c += dc;
      }
      if (line.length >= 5) return line;
    }
    return const [];
  }

  /// 只判断是否五连，不构造连线，供搜索高频调用。
  static bool hasFive(Uint8List cells, int index, int side) {
    final row = rowOf(index);
    final col = colOf(index);
    for (final (dr, dc) in kDirections) {
      var count = 1;
      var r = row - dr;
      var c = col - dc;
      while (inBoard(r, c) && cells[indexOf(r, c)] == side) {
        count++;
        r -= dr;
        c -= dc;
      }
      r = row + dr;
      c = col + dc;
      while (inBoard(r, c) && cells[indexOf(r, c)] == side) {
        count++;
        r += dr;
        c += dc;
      }
      if (count >= 5) return true;
    }
    return false;
  }

  /// 该点四周 [radius] 格内是否有棋子，用于限定候选范围。
  static bool _hasNeighbor(Uint8List cells, int index, int radius) {
    final row = rowOf(index);
    final col = colOf(index);
    final minRow = row - radius < 0 ? 0 : row - radius;
    final maxRow = row + radius >= boardSize ? boardSize - 1 : row + radius;
    final minCol = col - radius < 0 ? 0 : col - radius;
    final maxCol = col + radius >= boardSize ? boardSize - 1 : col + radius;
    for (var r = minRow; r <= maxRow; r++) {
      for (var c = minCol; c <= maxCol; c++) {
        if (cells[indexOf(r, c)] != empty) return true;
      }
    }
    return false;
  }

  /// 空盘返回中心点，其余返回棋子附近 [radius] 格内的空点。
  static List<int> candidateMoves(Uint8List cells, {int radius = 2}) {
    final moves = <int>[];
    for (var index = 0; index < cellCount; index++) {
      if (cells[index] != empty) continue;
      if (_hasNeighbor(cells, index, radius)) moves.add(index);
    }
    if (moves.isEmpty && cells[centerIndex] == empty) return [centerIndex];
    return moves;
  }

  /// 当前局面下 [side] 的立即获胜点，没有则为 null。
  static int? immediateWin(Uint8List cells, int side) {
    for (final index in candidateMoves(cells)) {
      if (cells[index] != empty) continue;
      cells[index] = side;
      final win = hasFive(cells, index, side);
      cells[index] = empty;
      if (win) return index;
    }
    return null;
  }

  /// 当前局面下 [side] 的全部立即获胜点，用于识别双杀。
  static List<int> immediateWins(Uint8List cells, int side) {
    final wins = <int>[];
    for (final index in candidateMoves(cells)) {
      if (cells[index] != empty) continue;
      cells[index] = side;
      final win = hasFive(cells, index, side);
      cells[index] = empty;
      if (win) wins.add(index);
    }
    return wins;
  }

  /// 落子后是否形成活四（两端皆空），供 AI 威胁判断。
  static bool makesOpenFour(Uint8List cells, int index, int side) {
    final row = rowOf(index);
    final col = colOf(index);
    for (final (dr, dc) in kDirections) {
      var left = index;
      var right = index;
      var r = row - dr;
      var c = col - dc;
      while (inBoard(r, c) && cells[indexOf(r, c)] == side) {
        left = indexOf(r, c);
        r -= dr;
        c -= dc;
      }
      r = row + dr;
      c = col + dc;
      while (inBoard(r, c) && cells[indexOf(r, c)] == side) {
        right = indexOf(r, c);
        r += dr;
        c += dc;
      }
      final length =
          (rowOf(right) - rowOf(left)).abs() +
          (colOf(right) - colOf(left)).abs() +
          1;
      if (length != 4) continue;
      final leftOpen =
          inBoard(rowOf(left) - dr, colOf(left) - dc) &&
          cells[indexOf(rowOf(left) - dr, colOf(left) - dc)] == empty;
      final rightOpen =
          inBoard(rowOf(right) + dr, colOf(right) + dc) &&
          cells[indexOf(rowOf(right) + dr, colOf(right) + dc)] == empty;
      if (leftOpen && rightOpen) return true;
    }
    return false;
  }
}
