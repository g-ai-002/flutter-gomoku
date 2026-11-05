import '../models/saved_game.dart';
import '../utils/constants.dart';
import 'log_service.dart';
import 'prefs_collection.dart';

/// 棋谱服务：内存 + SharedPreferences 双写，只保留最近若干局回放。
class GameHistoryService extends PrefsCollection<SavedGame> {
  GameHistoryService._()
    : super(
        key: AppConstants.prefKeyGameHistory,
        label: '棋谱',
        maxCount: maxRecords,
      );

  static final GameHistoryService instance = GameHistoryService._();

  static const int maxRecords = 20;

  List<SavedGame> get records => items;

  @override
  String idOf(SavedGame item) => item.id;

  @override
  Object? encode(SavedGame item) => item.toJson();

  @override
  SavedGame? decode(Object? item) =>
      item is Map<String, dynamic> ? SavedGame.fromJson(item) : null;

  @override
  DateTime? dateOf(SavedGame item) => item.endedAt;

  /// 同一 id 再次写入时覆盖旧记录，避免悔棋后重判产生重复条目。
  Future<void> record(SavedGame game) async {
    LogService.info('棋谱已保存: ${game.title}, ${game.moveCount} 手');
    await put(game);
  }

  Future<void> remove(String id) async {
    if (await removeById(id)) LogService.info('已删除棋谱: $id');
  }

  Future<void> clear() => clearAll();
}
