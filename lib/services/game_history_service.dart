import 'package:flutter/foundation.dart';

import '../models/saved_game.dart';
import '../utils/constants.dart';
import 'log_service.dart';
import 'prefs_json.dart';

/// 棋谱服务：内存 + SharedPreferences 双写，只保留最近若干局回放。
class GameHistoryService extends ChangeNotifier {
  GameHistoryService._();

  static final GameHistoryService instance = GameHistoryService._();

  static const int maxRecords = 20;

  final List<SavedGame> _records = [];
  final PrefsJson _store = PrefsJson(
    key: AppConstants.prefKeyGameHistory,
    label: '棋谱',
  );

  List<SavedGame> get records => List.unmodifiable(_records);

  bool get isEmpty => _records.isEmpty;

  @visibleForTesting
  void resetForTest() {
    _records.clear();
    _store.resetCache();
  }

  Future<void> load() async {
    final loaded = await _store.read<SavedGame>(_decode);
    if (loaded == null) return;
    loaded.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    _records
      ..clear()
      ..addAll(loaded.take(maxRecords));
    notifyListeners();
  }

  static SavedGame? _decode(Object? item) =>
      item is Map<String, dynamic> ? SavedGame.fromJson(item) : null;

  /// 同一 id 再次写入时覆盖旧记录，避免悔棋后重判产生重复条目。
  Future<void> record(SavedGame game) async {
    _records
      ..removeWhere((item) => item.id == game.id)
      ..insert(0, game);
    if (_records.length > maxRecords) {
      _records.removeRange(maxRecords, _records.length);
    }
    notifyListeners();
    LogService.info('棋谱已保存: ${game.title}, ${game.moveCount} 手');
    await _persist();
  }

  Future<void> remove(String id) async {
    final before = _records.length;
    _records.removeWhere((item) => item.id == id);
    if (_records.length == before) return;
    notifyListeners();
    LogService.info('已删除棋谱: $id');
    await _persist();
  }

  Future<void> clear() async {
    _records.clear();
    notifyListeners();
    await _store.clear();
  }

  Future<void> _persist() =>
      _store.write([for (final item in _records) item.toJson()]);
}
