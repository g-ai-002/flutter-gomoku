import 'package:flutter/foundation.dart';

import 'prefs_json.dart';

/// 基于 SharedPreferences 的有序集合：懒加载、按 id 去重与持久化。
///
/// 加载只执行一次，并在读取完成后按 id 合并内存中已有的条目，
/// 写入操作会先等待进行中的加载，避免「读完磁盘再覆盖内存」丢失新数据。
abstract class PrefsCollection<T> extends ChangeNotifier {
  PrefsCollection({
    required String key,
    required String label,
    this.maxCount = 0,
    PrefsJson? store,
  }) : _store = store ?? PrefsJson(key: key, label: label);

  final PrefsJson _store;

  /// 最大条目数，0 表示不限制。
  final int maxCount;

  final List<T> _items = [];
  Future<void>? _loading;
  int _generation = 0;

  List<T> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  bool containsId(String id) => _items.any((item) => idOf(item) == id);

  @protected
  String idOf(T item);

  @protected
  Object? encode(T item);

  @protected
  T? decode(Object? item);

  /// 排序时间；为 null 时保持写入顺序，例如残局通关记录。
  @protected
  DateTime? dateOf(T item) => null;

  /// 读取磁盘数据并与内存合并；并发调用共享同一次加载。
  Future<void> load() => _loading ??= _read();

  Future<void> _read() async {
    final generation = _generation;
    final loaded = await _store.read<T>(decode);
    if (loaded == null || generation != _generation) return;
    final known = {for (final item in _items) idOf(item)};
    for (final item in loaded) {
      if (known.add(idOf(item))) _items.add(item);
    }
    _sort(_items);
    _trim(_items);
    notifyListeners();
  }

  /// 新增或按 id 覆盖条目，写入成功后内存状态即为最新。
  @protected
  Future<void> put(T item) async {
    await load();
    _items.removeWhere((existing) => idOf(existing) == idOf(item));
    _items.insert(0, item);
    _sort(_items);
    _trim(_items);
    notifyListeners();
    await _persist();
  }

  /// 按 id 删除条目，存在并删除成功时返回 true。
  @protected
  Future<bool> removeById(String id) async {
    await load();
    final before = _items.length;
    _items.removeWhere((item) => idOf(item) == id);
    if (_items.length == before) return false;
    notifyListeners();
    await _persist();
    return true;
  }

  /// 清空内存与磁盘数据。
  @protected
  Future<void> clearAll() async {
    await load();
    _items.clear();
    notifyListeners();
    await _store.clear();
  }

  void _sort(List<T> items) {
    if (items.length < 2 || dateOf(items.first) == null) return;
    items.sort((a, b) => dateOf(b)!.compareTo(dateOf(a)!));
  }

  void _trim(List<T> items) {
    if (maxCount > 0 && items.length > maxCount) {
      items.removeRange(maxCount, items.length);
    }
  }

  Future<void> _persist() =>
      _store.write([for (final item in _items) encode(item)]);

  /// 丢弃内存与偏好缓存，测试切换 mock 数据时使用。
  @visibleForTesting
  void resetForTest() {
    _generation++;
    _items.clear();
    _store.resetCache();
    _loading = null;
  }
}
