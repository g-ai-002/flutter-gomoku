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
    for (final (dr, dc) in kDirections) {
      final (:startRow, :startCol, :length) = runAt(cells, index, side, dr, dc);
      if (length < 5) continue;
      return [
        for (var step = 0; step < length; step++)
          indexOf(startRow + dr * step, startCol + dc * step),
      ];
    }
    return const [];
  }

  /// 只判断是否五连，不构造连线，供搜索高频调用。
  static bool hasFive(Uint8List cells, int index, int side) {
    for (final (dr, dc) in kDirections) {
      if (runAt(cells, index, side, dr, dc).length >= 5) return true;
    }
    return false;
  }

  /// 从 [index] 沿 (dr, dc) 向两端延伸，返回连续同色棋子的起点与长度。
  static ({int startRow, int startCol, int length}) runAt(
    Uint8List cells,
    int index,
    int side,
    int dr,
    int dc,
  ) {
    var startRow = rowOf(index);
    var startCol = colOf(index);
    var row = startRow - dr;
    var col = startCol - dc;
    while (inBoard(row, col) && cells[indexOf(row, col)] == side) {
      startRow = row;
      startCol = col;
      row -= dr;
      col -= dc;
    }
    var length = 0;
    row = startRow;
    col = startCol;
    while (inBoard(row, col) && cells[indexOf(row, col)] == side) {
      length++;
      row += dr;
      col += dc;
    }
    return (startRow: startRow, startCol: startCol, length: length);
  }

  /// 空盘返回中心点，其余返回棋子附近 [radius] 格内的空点。
  ///
  /// 以棋子为中心向外标记，避免逐个空点重复检查邻域。
  static List<int> candidateMoves(Uint8List cells, {int radius = 2}) {
    final near = Uint8List(cellCount);
    var hasStone = false;
    for (var index = 0; index < cellCount; index++) {
      if (cells[index] == empty) continue;
      hasStone = true;
      final row = rowOf(index);
      final col = colOf(index);
      final minRow = row > radius ? row - radius : 0;
      final maxRow = row + radius < boardSize ? row + radius : boardSize - 1;
      final minCol = col > radius ? col - radius : 0;
      final maxCol = col + radius < boardSize ? col + radius : boardSize - 1;
      for (var r = minRow; r <= maxRow; r++) {
        final base = r * boardSize;
        for (var c = minCol; c <= maxCol; c++) {
          if (cells[base + c] == empty) near[base + c] = 1;
        }
      }
    }
    if (!hasStone) {
      return cells[centerIndex] == empty ? [centerIndex] : const [];
    }
    final moves = <int>[];
    for (var index = 0; index < cellCount; index++) {
      if (near[index] == 1) moves.add(index);
    }
    return moves;
  }

  /// 当前局面下 [side] 的立即获胜点，没有则为 null。
  static int? immediateWin(Uint8List cells, int side, {List<int>? candidates}) {
    for (final index in candidates ?? candidateMoves(cells)) {
      if (_isWinningMove(cells, index, side)) return index;
    }
    return null;
  }

  /// 当前局面下 [side] 的全部立即获胜点，用于识别双杀。
  ///
  /// 传入 [candidates] 可复用已生成的候选点，避免重复扫描棋盘。
  static List<int> immediateWins(
    Uint8List cells,
    int side, {
    List<int>? candidates,
  }) {
    final wins = <int>[];
    for (final index in candidates ?? candidateMoves(cells)) {
      if (_isWinningMove(cells, index, side)) wins.add(index);
    }
    return wins;
  }

  static bool _isWinningMove(Uint8List cells, int index, int side) {
    if (cells[index] != empty) return false;
    cells[index] = side;
    final win = hasFive(cells, index, side);
    cells[index] = empty;
    return win;
  }

  /// 战术兜底：优先自己立即成五，其次封堵对手的成五点。
  static int? tacticalMove(Uint8List cells, int side) {
    final candidates = candidateMoves(cells);
    final win = immediateWin(cells, side, candidates: candidates);
    if (win != null) return win;
    return immediateWin(cells, opponentOf(side), candidates: candidates);
  }

  /// AI 搜索失败或返回非法着法时的兜底着法。
  ///
  /// 优先自己成五，其次封堵对手成五，最后取离中心最近的空点；
  /// [forbidden] 中的黑棋禁手点会被跳过，避免兜底再次落入禁手。
  static int? fallbackMove(
    Uint8List cells,
    int side, {
    Set<int> forbidden = const {},
  }) {
    final candidates = [
      for (final move in candidateMoves(cells))
        if (!forbidden.contains(move)) move,
    ];
    for (final move in immediateWins(cells, side, candidates: candidates)) {
      return move;
    }
    for (final move in immediateWins(
      cells,
      opponentOf(side),
      candidates: candidates,
    )) {
      return move;
    }
    int? nearest;
    var nearestDistance = 1 << 30;
    for (final index in candidates) {
      final distance =
          (rowOf(index) - boardSize ~/ 2).abs() +
          (colOf(index) - boardSize ~/ 2).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = index;
      }
    }
    return nearest;
  }

  /// 落子后是否形成活四（两端皆空），供 AI 威胁判断。
  static bool makesOpenFour(Uint8List cells, int index, int side) {
    if (index < 0 || index >= cellCount || cells[index] != side) return false;
    for (final (dr, dc) in kDirections) {
      final (:startRow, :startCol, :length) = runAt(cells, index, side, dr, dc);
      if (length != 4) continue;
      final endRow = startRow + dr * 3;
      final endCol = startCol + dc * 3;
      final beforeOpen =
          inBoard(startRow - dr, startCol - dc) &&
          cells[indexOf(startRow - dr, startCol - dc)] == empty;
      final afterOpen =
          inBoard(endRow + dr, endCol + dc) &&
          cells[indexOf(endRow + dr, endCol + dc)] == empty;
      if (beforeOpen && afterOpen) return true;
    }
    return false;
  }
}
