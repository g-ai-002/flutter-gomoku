import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'log_service.dart';

/// SharedPreferences 中的 JSON 数组存储。
///
/// 懒加载实例、坏数据容错与错误日志集中在这里，棋谱库、自定义残局与
/// 残局进度只需负责各自的模型编解码。单个条目损坏时跳过，不影响其余数据。
class PrefsJson {
  PrefsJson({required this.key, required this.label});

  /// 偏好键名。
  final String key;

  /// 日志中的中文对象名，例如「棋谱」。
  final String label;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _ready async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// 读取并解码数组；键缺失、内容损坏或类型不符时返回 null。
  ///
  /// [decode] 抛出的异常按条目隔离，缺少必需字段时返回 null 即可跳过。
  Future<List<T>?> read<T>(T? Function(Object? item) decode) async {
    try {
      final raw = (await _ready).getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      final items = <T>[];
      for (final item in decoded) {
        try {
          final value = decode(item);
          if (value != null) items.add(value);
        } catch (_) {
          // 单条损坏不影响其余条目。
        }
      }
      return items;
    } catch (error, stack) {
      LogService.error('读取$label失败', error, stack);
      return null;
    }
  }

  /// 覆盖写入数组；失败时记录日志，内存状态保持不变。
  Future<void> write(List<Object?> items) async {
    try {
      await (await _ready).setString(key, jsonEncode(items));
    } catch (error, stack) {
      LogService.error('保存$label失败', error, stack);
    }
  }

  /// 删除整个键，用于清空列表。
  Future<void> clear() async {
    try {
      await (await _ready).remove(key);
      LogService.info('已清空$label');
    } catch (error, stack) {
      LogService.error('清空$label失败', error, stack);
    }
  }

  /// 丢弃缓存的偏好实例，测试切换 mock 数据时使用。
  void resetCache() => _prefs = null;
}
