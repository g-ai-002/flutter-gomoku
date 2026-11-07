import 'dart:typed_data';

import 'board_utils.dart';
import 'rules.dart';

/// 黑棋禁手类型：长连、四四、三三。
enum ForbiddenReason {
  overline('长连', '黑棋不可连成六子及以上'),
  doubleFour('四四', '黑棋一手不可同时形成两个四'),
  doubleThree('三三', '黑棋一手不可同时形成两个活三');

  const ForbiddenReason(this.label, this.description);

  final String label;
  final String description;
}

/// 禁手规则（黑棋限制，白棋不受限）。
///
/// 判定按「落子后的五格窗口」统计四与活三：
/// 五连直接获胜，优先于四四与三三；长连一律判为禁手。
/// 活三要求补一子后能形成两端皆空的活四，因此眠三不计入。
/// 补点本身若构成四四等禁手则不计入活三，按递归规则排除该活三。
class GomokuForbidden {
  GomokuForbidden._();

  /// 黑棋在 [index] 落子是否禁手，返回禁手类型，合法时返回 null。
  static ForbiddenReason? at(Uint8List cells, int index) {
    if (index < 0 || index >= cellCount || cells[index] != empty) return null;
    final board = Uint8List.fromList(cells);
    board[index] = black;
    return _evaluate(board, index);
  }

  /// 当前局面下黑棋的全部禁手点，供棋盘标记与落子校验。
  static Set<int> points(Uint8List cells) {
    final board = Uint8List.fromList(cells);
    final result = <int>{};
    for (final index in GomokuRules.candidateMoves(board)) {
      board[index] = black;
      if (_evaluate(board, index) != null) result.add(index);
      board[index] = empty;
    }
    return result;
  }

  /// 过滤出黑棋可以落子的点，其余行棋方原样返回。
  static List<int> legalMoves(Uint8List cells, int side, Iterable<int> moves) {
    if (side != black) return List.of(moves);
    return [
      for (final move in moves)
        if (at(cells, move) == null) move,
    ];
  }

  static ForbiddenReason? _evaluate(Uint8List board, int index) {
    var overline = false;
    var fives = 0;
    final fours = <String>{};
    for (final (dr, dc) in kDirections) {
      final run = GomokuRules.runAt(board, index, black, dr, dc);
      if (run.length >= 6) overline = true;
      if (run.length == 5) fives++;
      _collectFours(board, index, dr, dc, fours);
    }
    if (overline) return ForbiddenReason.overline;
    if (fives > 0) return null;
    if (fours.length >= 2) return ForbiddenReason.doubleFour;
    if (fours.isNotEmpty) return null;

    final threes = <String>{};
    for (final (dr, dc) in kDirections) {
      _collectThrees(board, index, dr, dc, threes);
    }
    return threes.length >= 2 ? ForbiddenReason.doubleThree : null;
  }

  /// 统计包含 [index] 的四：五格窗口内恰有四枚黑子与一个空点。
  ///
  /// 以四枚黑子而非成五点去重，活四两端都能成五，仍只算一个四。
  static void _collectFours(
    Uint8List board,
    int index,
    int dr,
    int dc,
    Set<String> fours,
  ) {
    final row = rowOf(index);
    final col = colOf(index);
    for (var offset = -4; offset <= 0; offset++) {
      final startRow = row + dr * offset;
      final startCol = col + dc * offset;
      if (!inBoard(startRow, startCol) ||
          !inBoard(startRow + dr * 4, startCol + dc * 4)) {
        continue;
      }
      final stones = <int>[];
      var blocked = false;
      for (var step = 0; step < 5; step++) {
        final at = indexOf(startRow + dr * step, startCol + dc * step);
        if (board[at] == black) {
          stones.add(at);
        } else if (board[at] != empty) {
          blocked = true;
          break;
        }
      }
      if (blocked || stones.length != 4) continue;
      stones.sort();
      fours.add('$dr:$dc:${stones.join(',')}');
    }
  }

  /// 统计包含 [index] 的活三：补一子后形成两端皆空的活四。
  ///
  /// 同一条活三可能有多个补点，按「四连去掉补点后的三枚棋子」去重。
  static void _collectThrees(
    Uint8List board,
    int index,
    int dr,
    int dc,
    Set<String> threes,
  ) {
    final row = rowOf(index);
    final col = colOf(index);
    for (var offset = -4; offset <= 4; offset++) {
      if (offset == 0) continue;
      final pRow = row + dr * offset;
      final pCol = col + dc * offset;
      if (!inBoard(pRow, pCol)) continue;
      final point = indexOf(pRow, pCol);
      if (board[point] != empty) continue;

      board[point] = black;
      final run = GomokuRules.runAt(board, index, black, dr, dc);
      String? key;
      // 补成活四的一手本身可能是四四等禁手，此时该三不计入活三。
      if (run.length == 4 &&
          _openEnds(board, run, dr, dc) &&
          _evaluate(board, point) == null) {
        final stones =
            [
                for (var step = 0; step < 4; step++)
                  indexOf(run.startRow + dr * step, run.startCol + dc * step),
              ]
              ..remove(point)
              ..sort();
        if (stones.length == 3) key = '$dr:$dc:${stones.join(',')}';
      }
      board[point] = empty;
      if (key != null) threes.add(key);
    }
  }

  static bool _openEnds(
    Uint8List board,
    ({int startRow, int startCol, int length}) run,
    int dr,
    int dc,
  ) {
    final beforeRow = run.startRow - dr;
    final beforeCol = run.startCol - dc;
    final afterRow = run.startRow + dr * 4;
    final afterCol = run.startCol + dc * 4;
    return inBoard(beforeRow, beforeCol) &&
        board[indexOf(beforeRow, beforeCol)] == empty &&
        inBoard(afterRow, afterCol) &&
        board[indexOf(afterRow, afterCol)] == empty;
  }
}
