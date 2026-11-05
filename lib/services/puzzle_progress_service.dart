import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import 'log_service.dart';

/// 残局通关记录：只保存已通关的关卡 id，读写失败不影响挑战流程。
class PuzzleProgressService extends ChangeNotifier {
  PuzzleProgressService._();

  static final PuzzleProgressService instance = PuzzleProgressService._();

  final Set<String> _solved = {};
  SharedPreferences? _prefs;
  bool _loaded = false;

  Set<String> get solved => Set.unmodifiable(_solved);

  int get solvedCount => _solved.length;

  bool isSolved(String id) => _solved.contains(id);

  @visibleForTesting
  void resetForTest() {
    _solved.clear();
    _prefs = null;
    _loaded = false;
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs!.getString(AppConstants.prefKeyPuzzleProgress);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _solved
        ..clear()
        ..addAll(decoded.whereType<String>());
      notifyListeners();
    } catch (error, stack) {
      LogService.error('读取残局进度失败', error, stack);
    }
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
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.remove(AppConstants.prefKeyPuzzleProgress);
      LogService.info('已清空残局进度');
    } catch (error, stack) {
      LogService.error('清空残局进度失败', error, stack);
    }
  }

  Future<void> _persist() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(
        AppConstants.prefKeyPuzzleProgress,
        jsonEncode(_solved.toList()..sort()),
      );
    } catch (error, stack) {
      LogService.error('保存残局进度失败', error, stack);
    }
  }
}
