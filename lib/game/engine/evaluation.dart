import 'dart:typed_data';

import 'board_utils.dart';

/// 棋型评估：按四个方向的所有直线累计连子与空位形态。
///
/// 评估只读取棋盘，不修改；一次遍历同时累计黑白双方的分数，
/// 叶节点只扫描一遍直线，为 Alpha-Beta 搜索节省一半的评估开销。
class GomokuEvaluation {
  GomokuEvaluation._();

  /// 五连窗口权重，按窗口内己方棋子数递增。
  static const List<int> _windowWeights = [0, 2, 40, 900, 25000, 10000000];

  /// 全部长度不小于 5 的直线（横、竖、两条斜线）。
  static final List<List<int>> lines = _buildLines();

  static List<List<int>> _buildLines() {
    final result = <List<int>>[];
    for (var start = 0; start < boardSize; start++) {
      result
        ..add(_line(start, 0, 0, 1))
        ..add(_line(0, start, 1, 0))
        ..add(_line(start, 0, 1, 1))
        ..add(_line(start, boardSize - 1, 1, -1));
      if (start > 0) result.add(_line(0, start, 1, 1));
      if (start < boardSize - 1) result.add(_line(0, start, 1, -1));
    }
    return [
      for (final line in result)
        if (line.length >= 5) line,
    ];
  }

  static List<int> _line(int row, int col, int dr, int dc) {
    final cells = <int>[];
    for (; inBoard(row, col); row += dr, col += dc) {
      cells.add(indexOf(row, col));
    }
    return cells;
  }

  /// 从 [side] 视角评估局面，进攻略高于防守。
  static int evaluate(Uint8List cells, int side) {
    final scores = Int32List(2);
    for (final line in lines) {
      _lineScores(cells, line, scores);
    }
    final own = scores[side - 1];
    final other = scores[opponentOf(side) - 1];
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

  /// 累加一条直线对黑、白双方的分数，写入长度为 2 的 [scores]。
  ///
  /// 五格窗口内只可能有一方的棋子，逐个窗口同时判断双方；
  /// 连子段按颜色分段累计，黑白的分数不会互相干扰。
  static void _lineScores(Uint8List cells, List<int> line, Int32List scores) {
    final n = line.length;
    for (var start = 0; start + 4 < n; start++) {
      var blackCount = 0;
      var whiteCount = 0;
      var gapPos = -1;
      for (var offset = 0; offset < 5; offset++) {
        final value = cells[line[start + offset]];
        if (value == black) {
          blackCount++;
        } else if (value == white) {
          whiteCount++;
        } else {
          gapPos = offset;
        }
      }
      if (blackCount > 0 && whiteCount > 0) continue;
      final count = blackCount > 0 ? blackCount : whiteCount;
      final index = blackCount > 0 ? 0 : 1;
      scores[index] += _windowWeights[count];
      // 内部空隙的四连（如 XX_XX）比普通四连更接近成五。
      if (count == 4 && gapPos > 0 && gapPos < 4) scores[index] += 60000;
    }

    var index = 0;
    while (index < n) {
      final value = cells[line[index]];
      if (value == empty) {
        index++;
        continue;
      }
      var end = index + 1;
      while (end < n && cells[line[end]] == value) {
        end++;
      }
      final run = end - index;
      if (run >= 2 && run <= 4) {
        final leftOpen = index > 0 && cells[line[index - 1]] == empty;
        final rightOpen = end < n && cells[line[end]] == empty;
        final open = (leftOpen ? 1 : 0) + (rightOpen ? 1 : 0);
        if (run == 4) {
          scores[value - 1] += open == 2 ? 180000 : (open == 1 ? 18000 : 0);
        } else if (run == 3) {
          scores[value - 1] += open == 2 ? 12000 : (open == 1 ? 800 : 0);
        } else {
          scores[value - 1] += open == 2 ? 320 : (open == 1 ? 30 : 0);
        }
      }
      index = end;
    }
  }
}
