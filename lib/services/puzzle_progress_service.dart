import 'package:flutter/foundation.dart';

import '../utils/constants.dart';
import 'log_service.dart';
import 'prefs_json.dart';

/// 残局通关记录：只保存已通关的关卡 id，读写失败不影响挑战流程。
class PuzzleProgressService extends ChangeNotifier {
  PuzzleProgressService._();

  static final PuzzleProgressService instance = PuzzleProgressService._();

  final Set<String> _solved = {};
  final PrefsJson _store = PrefsJson(
    key: AppConstants.prefKeyPuzzleProgress,
    label: '残局进度',
  );
  bool _loaded = false;

  Set<String> get solved => Set.unmodifiable(_solved);

  int get solvedCount => _solved.length;

  bool isSolved(String id) => _solved.contains(id);

  @visibleForTesting
  void resetForTest() {
    _solved.clear();
    _store.resetCache();
    _loaded = false;
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final loaded = await _store.read<String>(
      (item) => item is String ? item : null,
    );
    if (loaded == null) return;
    _solved
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  Future<void> markSolved(String id) async {
    await load();
    if (!_solved.add(id)) return;
    notifyListeners();
    LogService.info('残局进度已更新: $id（共 ${_solved.length} 关）');
    await _persist();
  }

  /// 删除自定义残局时同步移除它的通关记录。
  Future<void> forget(String id) async {
    if (!_solved.remove(id)) return;
    notifyListeners();
    LogService.info('残局进度已移除: $id');
    await _persist();
  }

  Future<void> clear() async {
    _solved.clear();
    notifyListeners();
    await _store.clear();
  }

  Future<void> _persist() => _store.write(_solved.toList()..sort());
}
