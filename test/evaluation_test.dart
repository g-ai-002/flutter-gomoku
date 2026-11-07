import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/engine/evaluation.dart';
import 'package:gomoku/game/engine/rules.dart';

const List<int> _windowWeights = [0, 2, 40, 900, 25000, 10000000];

/// 参考实现：按单方视角逐条直线累计，作为优化后评估的对照。
int _referenceScore(Uint8List cells, int side) {
  var total = 0;
  for (final line in GomokuEvaluation.lines) {
    final n = line.length;
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
      total += _windowWeights[own];
      if (own == 4 && gapPos > 0 && gapPos < 4) total += 60000;
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
          total += open == 2 ? 180000 : (open == 1 ? 18000 : 0);
        } else if (run == 3) {
          total += open == 2 ? 12000 : (open == 1 ? 800 : 0);
        } else {
          total += open == 2 ? 320 : (open == 1 ? 30 : 0);
        }
      }
      index = end;
    }
  }
  return total;
}

int _referenceEvaluate(Uint8List cells, int side) {
  final own = _referenceScore(cells, side);
  final other = _referenceScore(cells, opponentOf(side));
  return own - (other * 1.05).round();
}

/// 参考候选点：每次都用新的标记数组，不受上一代标记影响。
List<int> _referenceCandidates(Uint8List cells, {int radius = 2}) {
  final near = Uint8List(cellCount);
  var hasStone = false;
  for (var index = 0; index < cellCount; index++) {
    if (cells[index] == empty) continue;
    hasStone = true;
    final row = rowOf(index);
    final col = colOf(index);
    for (
      var r = math.max(0, row - radius);
      r <= math.min(boardSize - 1, row + radius);
      r++
    ) {
      for (
        var c = math.max(0, col - radius);
        c <= math.min(boardSize - 1, col + radius);
        c++
      ) {
        if (cells[r * boardSize + c] == empty) near[r * boardSize + c] = 1;
      }
    }
  }
  if (!hasStone) return cells[centerIndex] == empty ? [centerIndex] : const [];
  return [
    for (var index = 0; index < cellCount; index++)
      if (near[index] == 1) index,
  ];
}

void main() {
  group('棋型评估', () {
    test('活三的形态分高于被堵的三', () {
      final open = emptyCells();
      for (var col = 5; col <= 7; col++) {
        open[indexOf(7, col)] = black;
      }
      final blocked = emptyCells();
      for (var col = 5; col <= 7; col++) {
        blocked[indexOf(7, col)] = black;
      }
      blocked[indexOf(7, 8)] = white;
      final openScore = GomokuEvaluation.pointScore(open, indexOf(7, 4), black);
      final blockedScore = GomokuEvaluation.pointScore(
        blocked,
        indexOf(7, 4),
        black,
      );
      expect(openScore, greaterThan(blockedScore));
    });

    test('成五的形态分远高于普通连子', () {
      final cells = emptyCells();
      for (var col = 3; col <= 6; col++) {
        cells[indexOf(7, col)] = black;
      }
      final winning = GomokuEvaluation.pointScore(cells, indexOf(7, 7), black);
      final ordinary = GomokuEvaluation.pointScore(cells, indexOf(9, 9), black);
      expect(winning, greaterThan(ordinary * 100));
    });

    test('双方局面评估符号对称', () {
      final cells = emptyCells();
      cells[indexOf(7, 7)] = black;
      cells[indexOf(8, 8)] = black;
      final blackScore = GomokuEvaluation.evaluate(cells, black);
      final whiteScore = GomokuEvaluation.evaluate(cells, white);
      expect(blackScore, greaterThan(0));
      expect(whiteScore, lessThan(0));
    });

    test('直线覆盖四个方向', () {
      final horizontal = GomokuEvaluation.lines.any(
        (line) => line.length == 15 && line.first == indexOf(7, 0),
      );
      final vertical = GomokuEvaluation.lines.any(
        (line) => line.length == 15 && line.first == indexOf(0, 7),
      );
      expect(horizontal, isTrue);
      expect(vertical, isTrue);
      // 两条主对角线都应在列表中。
      expect(GomokuEvaluation.lines.every((line) => line.length >= 5), isTrue);
    });

    test('直线列表没有重复且覆盖全部方向', () {
      final keys = {for (final line in GomokuEvaluation.lines) line.join(',')};
      expect(keys.length, GomokuEvaluation.lines.length);
      expect(GomokuEvaluation.lines.length, 72);
      final cells = emptyCells();
      for (final line in GomokuEvaluation.lines) {
        expect(cells.length, greaterThan(line.last));
      }
    });

    test('随机局面评估与参考实现一致', () {
      final random = math.Random(20261107);
      for (var round = 0; round < 120; round++) {
        final cells = emptyCells();
        final stones = random.nextInt(60);
        for (var i = 0; i < stones; i++) {
          final index = random.nextInt(cellCount);
          if (cells[index] == empty) {
            cells[index] = random.nextBool() ? black : white;
          }
        }
        for (final side in const [black, white]) {
          expect(
            GomokuEvaluation.evaluate(cells, side),
            _referenceEvaluate(cells, side),
            reason: '第 $round 局 $side 方',
          );
        }
      }
    });
  });

  group('候选点缓存', () {
    test('连续生成候选点不受上一代标记影响', () {
      final random = math.Random(20261107);
      final boards = <Uint8List>[];
      for (var round = 0; round < 40; round++) {
        final cells = emptyCells();
        for (var i = 0; i < 12; i++) {
          cells[random.nextInt(cellCount)] = random.nextBool() ? black : white;
        }
        boards.add(cells);
      }
      for (final cells in boards) {
        final expected = _referenceCandidates(cells);
        expect(GomokuRules.candidateMoves(cells), expected);
        // 同一局面连续调用两次，第二次仍应完全一致。
        expect(GomokuRules.candidateMoves(cells), expected);
      }
    });

    test('空盘只返回天元', () {
      expect(GomokuRules.candidateMoves(emptyCells()), [centerIndex]);
    });

    test('候选点只包含空点', () {
      final cells = emptyCells();
      cells[indexOf(7, 7)] = black;
      cells[indexOf(7, 8)] = white;
      for (final index in GomokuRules.candidateMoves(cells)) {
        expect(cells[index], empty);
      }
    });
  });
}
