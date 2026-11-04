import '../game/board_state.dart';
import '../game/game_archive.dart';
import 'move_record.dart';

/// 保存在本地的对局回放：着法序列，写入偏好存储后可再次复盘。
class SavedGame {
  SavedGame({
    required this.id,
    required this.title,
    required this.endedAt,
    required List<MoveRecord> moves,
    this.result,
  }) : moves = List.unmodifiable(moves);

  final String id;
  final String title;
  final DateTime endedAt;
  final List<MoveRecord> moves;
  final String? result;

  int get moveCount => moves.length;

  String get resultLabel => result == null || result!.isEmpty ? '进行中' : result!;

  /// 与复盘页导出共用同一份文本格式。
  String toArchiveText() => GameArchive.encode(
    title: title,
    moves: moves,
    result: result,
    date: endedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'endedAt': endedAt.toIso8601String(),
    'result': result,
    'moves': [for (final move in moves) move.index],
  };

  /// 着法非法或缺少必要字段时返回 null。
  static SavedGame? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final rawMoves = json['moves'];
    if (id is! String || id.isEmpty || rawMoves is! List) return null;
    final indices = <int>[];
    for (final token in rawMoves) {
      if (token is! int) return null;
      indices.add(token);
    }
    if (indices.isEmpty) return null;
    final board = GomokuBoard();
    if (!board.replay(indices)) return null;
    final endedAt =
        DateTime.tryParse('${json['endedAt']}') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return SavedGame(
      id: id,
      title: json['title'] is String && (json['title'] as String).isNotEmpty
          ? json['title'] as String
          : '对局回放',
      endedAt: endedAt,
      moves: board.history,
      result: json['result'] is String && (json['result'] as String).isNotEmpty
          ? json['result'] as String
          : null,
    );
  }

  /// 把导入的棋谱转成棋谱库条目，日期缺失时用当前时间。
  factory SavedGame.fromArchive(ArchivedGame archive) {
    final now = DateTime.now();
    final board = GomokuBoard();
    board.replay(archive.moves);
    return SavedGame(
      id: 'import_${now.microsecondsSinceEpoch}',
      title: archive.title,
      endedAt: DateTime.tryParse(archive.date ?? '') ?? now,
      moves: board.history,
      result: archive.result,
    );
  }
}
