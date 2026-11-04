import 'dart:typed_data';

import 'board_utils.dart';

/// 棋型评估：按四个方向的所有直线累计连子与空位形态。
///
/// 评估只读取棋盘，不修改；分数对双方对称，便于 Alpha-Beta 直接做差。
class GomokuEvaluation {
  GomokuEvaluation._();

  /// 五连窗口权重，按窗口内己方棋子数递增。
  static const List<int> _windowWeights = [0, 2, 40, 900, 25000, 10000000];

  /// 全部长度不小于 5 的直线（横、竖、两条斜线）。
  static final List<List<int>> lines = _buildLines();

  static List<List<int>> _buildLines() {
    final result = <List<int>>[];
    for (var row = 0; row < boardSize; row++) {
      result.add([for (var col = 0; col < boardSize; col++) indexOf(row, col)]);
    }
    for (var col = 0; col < boardSize; col++) {
      result.add([for (var row = 0; row < boardSize; row++) indexOf(row, col)]);
    }
    for (var start = 0; start < boardSize; start++) {
      final downRight = <int>[];
      for (var step = 0; start + step < boardSize; step++) {
        downRight.add(indexOf(start + step, step));
      }
      if (downRight.length >= 5) result.add(downRight);
      if (start == 0) continue;
      final downRightTop = <int>[];
      for (var step = 0; start + step < boardSize; step++) {
        downRightTop.add(indexOf(step, start + step));
      }
      if (downRightTop.length >= 5) result.add(downRightTop);
    }
    for (var start = 0; start < boardSize; start++) {
      final downLeft = <int>[];
      for (var step = 0; start + step < boardSize; step++) {
        downLeft.add(indexOf(start + step, boardSize - 1 - step));
      }
      if (downLeft.length >= 5) result.add(downLeft);
      if (start == 0) continue;
      final downLeftTop = <int>[];
      for (var step = 0; start + step < boardSize; step++) {
        downLeftTop.add(indexOf(step, boardSize - 1 - start - step));
      }
      if (downLeftTop.length >= 5) result.add(downLeftTop);
    }
    return result;
  }

  /// [side] 在整盘上的棋型总分。
  static int scoreOf(Uint8List cells, int side) {
    var total = 0;
    for (final line in lines) {
      total += _lineScore(cells, line, side);
    }
    return total;
  }

  /// 从 [side] 视角评估局面，进攻略高于防守。
  static int evaluate(Uint8List cells, int side) {
    final own = scoreOf(cells, side);
    final other = scoreOf(cells, opponentOf(side));
    return own - (other * 1.05).round();
  }

  /// 单点在 [side] 手中的形态分，用于候选着法排序。
  ///
  /// 调用时 [index] 可以是空点，也可以已经是 [side] 的棋子。
  static int pointScore(Uint8List cells, int index, int side) {
    final row = rowOf(index);
    final col = colOf(index);
    var total = 0;
    for (final (dr, dc) in kDirections) {
      var left = 0;
      var r = row - dr;
      var c = col - dc;
      while (inBoard(r, c) && cells[indexOf(r, c)] == side) {
        left++;
        r -= dr;
        c -= dc;
      }
      final leftOpen = inBoard(r, c) && cells[indexOf(r, c)] == empty;
      var right = 0;
      r = row + dr;
      c = col + dc;
      while (inBoard(r, c) && cells[indexOf(r, c)] == side) {
        right++;
        r += dr;
        c += dc;
      }
      final rightOpen = inBoard(r, c) && cells[indexOf(r, c)] == empty;
      total += _runScore(1 + left + right, leftOpen, rightOpen);
    }
    return total;
  }

  static int _runScore(int run, bool leftOpen, bool rightOpen) {
    final open = (leftOpen ? 1 : 0) + (rightOpen ? 1 : 0);
    if (run >= 5) return 10000000;
    if (run == 4) return open == 2 ? 300000 : (open == 1 ? 25000 : 0);
    if (run == 3) return open == 2 ? 12000 : (open == 1 ? 900 : 0);
    if (run == 2) return open == 2 ? 350 : (open == 1 ? 40 : 0);
    if (run == 1) return open == 2 ? 12 : 0;
    return 0;
  }

  static int _lineScore(Uint8List cells, List<int> line, int side) {
    final n = line.length;
    var score = 0;

    for (var start = 0; start + 4 < n; start++) {
      var own = 0;
      var blocked = false;
      var gapPos = -1;
      for (var offset = 0; offset < 5; offset++) {
        final value = cells[line[start + offset]];
        if (value == side) {
          own++;
        } else if (value != empty) {
          blocked = true;
          break;
        } else {
          gapPos = offset;
        }
      }
      if (blocked) continue;
      score += _windowWeights[own];
      // 内部空隙的四连（如 XX_XX）比普通四连更接近成五。
      if (own == 4 && gapPos > 0 && gapPos < 4) score += 60000;
    }

    var index = 0;
    while (index < n) {
      if (cells[line[index]] != side) {
        index++;
        continue;
      }
      var end = index + 1;
      while (end < n && cells[line[end]] == side) {
        end++;
      }
      final run = end - index;
      if (run >= 2 && run <= 4) {
        final leftOpen = index > 0 && cells[line[index - 1]] == empty;
        final rightOpen = end < n && cells[line[end]] == empty;
        final open = (leftOpen ? 1 : 0) + (rightOpen ? 1 : 0);
        if (run == 4) {
          score += open == 2 ? 180000 : (open == 1 ? 18000 : 0);
        } else if (run == 3) {
          score += open == 2 ? 12000 : (open == 1 ? 800 : 0);
        } else if (run == 2) {
          score += open == 2 ? 320 : (open == 1 ? 30 : 0);
        }
      }
      index = end;
    }

    return score;
  }
}
