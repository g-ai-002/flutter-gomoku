/// 坐标棋谱记法：列 A–O，行 1–15，例如 `H8` 表示中心点。
library;

import 'engine/board_utils.dart';

class MoveNotation {
  MoveNotation._();

  static const String _letters = 'ABCDEFGHIJKLMNO';

  /// 把交叉点转成坐标记法。
  static String describe(int index) =>
      '${_letters[colOf(index)]}${rowOf(index) + 1}';

  /// 解析坐标记法，非法时返回 null；兼容小写与首尾空格。
  static int? parse(String text) {
    final match = RegExp(r'^\s*([A-Oa-o])\s*(\d{1,2})\s*$').firstMatch(text);
    if (match == null) return null;
    final col = _letters.indexOf(match.group(1)!.toUpperCase());
    final row = int.parse(match.group(2)!) - 1;
    if (!inBoard(row, col)) return null;
    return indexOf(row, col);
  }
}
