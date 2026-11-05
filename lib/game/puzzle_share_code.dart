import 'dart:convert';

import 'custom_puzzles.dart';
import 'engine/board_utils.dart';
import 'engine/rules.dart';

/// 自定义残局的纯文本分享码：`GMK1~<base64url 载荷>~<校验位>`。
///
/// 只包含名称、限手数与棋子坐标，不依赖网络；解析时复用 [CustomPuzzle.fromJson]
/// 的字段校验，并额外拒绝已经成五、无法继续做杀的局面。
class PuzzleShareCode {
  PuzzleShareCode._();

  static const String prefix = 'GMK1';
  static const String _separator = '~';
  static const int _maxLength = 4096;

  /// 编码为分享码，标题与棋子由残局自身保证合法。
  static String encode(CustomPuzzle puzzle) {
    final payload = jsonEncode({
      'title': puzzle.title,
      'moveLimit': puzzle.moveLimit,
      'black': puzzle.blackStones,
      'white': puzzle.whiteStones,
    });
    final body = base64Url.encode(utf8.encode(payload));
    return '$prefix$_separator$body$_separator${_checksum(body)}';
  }

  /// 解析分享码；格式错误、校验不符或局面非法时返回 null。
  static CustomPuzzle? decode(String raw, {DateTime? now}) {
    final text = raw.trim();
    if (text.isEmpty || text.length > _maxLength) return null;
    final parts = text.split(_separator);
    if (parts.length != 3 || parts[0] != prefix) return null;
    final body = parts[1];
    if (_checksum(body) != parts[2]) return null;

    Object? payload;
    try {
      payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(body))),
      );
    } on FormatException {
      return null;
    }
    if (payload is! Map<String, dynamic>) return null;

    final time = now ?? DateTime.now();
    final puzzle = CustomPuzzle.fromJson({
      ...payload,
      'id': 'shared_${time.microsecondsSinceEpoch}',
      'createdAt': time.toIso8601String(),
    });
    if (puzzle == null || _hasFive(puzzle)) return null;
    return puzzle;
  }

  /// FNV-1a 32 位校验，用于识别复制时被截断或改动的分享码。
  static String _checksum(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static bool _hasFive(CustomPuzzle puzzle) {
    final cells = puzzle.toPuzzle().buildCells();
    for (var index = 0; index < cellCount; index++) {
      final side = cells[index];
      if (side != empty && GomokuRules.hasFive(cells, index, side)) return true;
    }
    return false;
  }
}
