import '../models/move_record.dart';
import 'board_state.dart';
import 'notation.dart';

/// 导入后的棋谱：标题、结果、日期与着法序列。
class ArchivedGame {
  const ArchivedGame({
    required this.title,
    required this.moves,
    this.result,
    this.date,
  });

  final String title;
  final List<int> moves;
  final String? result;
  final String? date;
}

/// 棋谱文本的编码与解析，复盘导出与棋谱库导入共用。
class GameArchive {
  GameArchive._();

  static const String _movesHeader = '着法：';

  /// 生成便于阅读与粘贴的棋谱文本。
  static String encode({
    required String title,
    required List<MoveRecord> moves,
    String? result,
    DateTime? date,
  }) {
    final buffer = StringBuffer()
      ..writeln('# 五子棋棋谱')
      ..writeln('标题：$title');
    if (result != null && result.isNotEmpty) {
      buffer.writeln('结果：$result');
    }
    if (date != null) {
      buffer.writeln('日期：${_formatDate(date)}');
    }
    buffer
      ..writeln('先手：黑')
      ..writeln(_movesHeader);
    for (var i = 0; i < moves.length; i += 12) {
      final end = i + 12 < moves.length ? i + 12 : moves.length;
      buffer.writeln(
        [for (var j = i; j < end; j++) moves[j].notation].join(' '),
      );
    }
    return buffer.toString();
  }

  /// 解析棋谱文本；无法还原出至少一手合法着法时返回 null。
  static ArchivedGame? decode(String text) {
    if (text.trim().isEmpty) return null;
    final lines = text.split(RegExp(r'\r?\n'));
    var title = '导入棋谱';
    String? result;
    String? date;
    final moveTokens = <String>[];
    var inMoves = false;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (!inMoves) {
        if (line.startsWith(_movesHeader)) {
          inMoves = true;
          final rest = line.substring(_movesHeader.length).trim();
          if (rest.isNotEmpty) moveTokens.addAll(rest.split(RegExp(r'\s+')));
          continue;
        }
        if (line.startsWith('#')) continue;
        final separator = line.indexOf(RegExp(r'[:：]'));
        if (separator > 0) {
          final key = line.substring(0, separator).trim();
          final value = line.substring(separator + 1).trim();
          if (key == '标题' && value.isNotEmpty) {
            title = value;
            continue;
          }
          if (key == '结果' && value.isNotEmpty) {
            result = value;
            continue;
          }
          if (key == '日期' && value.isNotEmpty) {
            date = value;
            continue;
          }
          if (key == '先手') continue;
        }
      }
      moveTokens.addAll(line.split(RegExp(r'\s+')));
    }

    final moves = <int>[];
    for (final token in moveTokens) {
      final cleaned = token.replaceAll(RegExp(r'^[0-9]+[.)、]?'), '');
      final index = MoveNotation.parse(cleaned);
      if (index == null) continue;
      moves.add(index);
    }
    if (moves.isEmpty) return null;

    final board = GomokuBoard();
    for (final move in moves) {
      if (board.apply(move) == null) return null;
    }
    return ArchivedGame(title: title, moves: moves, result: result, date: date);
  }

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
