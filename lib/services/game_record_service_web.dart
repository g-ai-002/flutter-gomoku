import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_record.dart';
import 'log_service.dart';

/// 对局记录服务（Web）：浏览器没有应用目录，记录以 JSON 字符串存进
/// SharedPreferences，公开 API 与 IO 实现保持一致。
class GameRecordService {
  static GameRecordService? _instance;

  static GameRecordService get instance {
    _instance ??= GameRecordService._();
    return _instance!;
  }

  GameRecordService._();

  /// 仅用于测试：重置单例
  static void reset() {
    _instance = null;
  }

  static const String _keyPrefix = 'game_record_';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Iterable<String> _recordKeys(SharedPreferences prefs) =>
      prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

  /// 保存对局记录
  Future<void> save(GameRecord record) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(
        '$_keyPrefix${record.id}',
        record.toJsonString(),
      );
      LogService.info('对局记录已保存: ${record.id}');
    } catch (e) {
      LogService.error('保存对局记录失败', e);
    }
  }

  /// 加载所有对局记录（按日期倒序）
  Future<List<GameRecord>> loadAll() async {
    try {
      final prefs = await _prefs;
      final records = <GameRecord>[];
      for (final key in _recordKeys(prefs)) {
        final content = prefs.getString(key);
        if (content == null) continue;
        try {
          records.add(GameRecord.fromJsonString(content));
        } catch (e) {
          LogService.warning('解析对局记录失败: $key');
        }
      }
      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (e) {
      LogService.error('加载对局记录失败', e);
      return [];
    }
  }

  /// 删除对局记录
  Future<void> delete(String id) async {
    try {
      final prefs = await _prefs;
      final removed = await prefs.remove('$_keyPrefix$id');
      if (removed) {
        LogService.info('对局记录已删除: $id');
      }
    } catch (e) {
      LogService.error('删除对局记录失败', e);
    }
  }

  /// 获取对局记录数量
  Future<int> count() async {
    try {
      final prefs = await _prefs;
      return _recordKeys(prefs).length;
    } catch (_) {
      return 0;
    }
  }
}
