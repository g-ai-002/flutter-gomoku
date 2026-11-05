import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/log_service.dart';
import '../utils/constants.dart';
import 'engine/board_utils.dart';
import 'puzzles.dart';

/// 自定义残局：玩家在编辑器中摆出的固定局面，黑先、限手数成五。
class CustomPuzzle {
  const CustomPuzzle({
    required this.id,
    required this.title,
    required this.moveLimit,
    required this.blackStones,
    required this.whiteStones,
    required this.createdAt,
  });

  static const int maxCount = 30;
  static const int maxMoveLimit = 9;

  final String id;
  final String title;
  final int moveLimit;
  final List<int> blackStones;
  final List<int> whiteStones;
  final DateTime createdAt;

  GomokuPuzzle toPuzzle() => GomokuPuzzle(
    id: id,
    title: title,
    tier: PuzzleTier.expert,
    isCustom: true,
    moveLimit: moveLimit,
    blackStones: blackStones,
    whiteStones: whiteStones,
    tip: '自定义残局：黑先，$moveLimit 手内连成五子。',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'moveLimit': moveLimit,
    'black': blackStones,
    'white': whiteStones,
    'createdAt': createdAt.toIso8601String(),
  };

  /// 字段缺失、坐标越界或黑白重叠时返回 null。
  static CustomPuzzle? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final limit = json['moveLimit'];
    final black = _indices(json['black']);
    final white = _indices(json['white']);
    if (id is! String || id.isEmpty) return null;
    if (title is! String || title.trim().isEmpty || title.length > 20) {
      return null;
    }
    if (limit is! int || limit < 1 || limit > maxMoveLimit) return null;
    if (black == null || white == null || black.isEmpty) return null;
    if (black.toSet().intersection(white.toSet()).isNotEmpty) return null;
    return CustomPuzzle(
      id: id,
      title: title.trim(),
      moveLimit: limit,
      blackStones: black,
      whiteStones: white,
      createdAt:
          DateTime.tryParse('${json['createdAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static List<int>? _indices(Object? value) {
    if (value is! List) return null;
    final result = <int>{};
    for (final item in value) {
      if (item is! int || item < 0 || item >= cellCount) return null;
      result.add(item);
    }
    return result.length == value.length ? result.toList() : null;
  }
}

/// 自定义残局库：内存与 SharedPreferences 双写，最多保留 30 关。
class CustomPuzzleService extends ChangeNotifier {
  CustomPuzzleService._();

  static final CustomPuzzleService instance = CustomPuzzleService._();

  final List<CustomPuzzle> _puzzles = [];
  SharedPreferences? _prefs;

  List<CustomPuzzle> get puzzles => List.unmodifiable(_puzzles);

  @visibleForTesting
  void resetForTest() {
    _puzzles.clear();
    _prefs = null;
  }

  Future<void> load() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs!.getString(AppConstants.prefKeyCustomPuzzles);
      final decoded = raw == null || raw.isEmpty ? null : jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = <CustomPuzzle>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final puzzle = CustomPuzzle.fromJson(item);
        if (puzzle != null) loaded.add(puzzle);
      }
      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _puzzles
        ..clear()
        ..addAll(loaded.take(CustomPuzzle.maxCount));
      notifyListeners();
    } catch (error, stack) {
      LogService.error('读取自定义残局失败', error, stack);
    }
  }

  /// 新建或覆盖已有 id 的残局，返回落库后的条目。
  Future<CustomPuzzle> save({
    String? id,
    required String title,
    required int moveLimit,
    required List<int> blackStones,
    required List<int> whiteStones,
  }) async {
    final existing = id == null ? null : _find(id);
    final now = DateTime.now();
    final puzzle = CustomPuzzle(
      id:
          existing?.id ??
          'custom_${now.microsecondsSinceEpoch}_${_puzzles.length}',
      title: title.trim(),
      moveLimit: moveLimit,
      blackStones: List.unmodifiable(blackStones),
      whiteStones: List.unmodifiable(whiteStones),
      createdAt: existing?.createdAt ?? now,
    );
    _puzzles
      ..removeWhere((item) => item.id == puzzle.id)
      ..insert(0, puzzle);
    if (_puzzles.length > CustomPuzzle.maxCount) {
      _puzzles.removeRange(CustomPuzzle.maxCount, _puzzles.length);
    }
    notifyListeners();
    LogService.info('自定义残局已保存: ${puzzle.title}');
    await _persist();
    return puzzle;
  }

  Future<void> remove(String id) async {
    final before = _puzzles.length;
    _puzzles.removeWhere((item) => item.id == id);
    if (_puzzles.length == before) return;
    notifyListeners();
    LogService.info('已删除自定义残局: $id');
    await _persist();
  }

  CustomPuzzle? _find(String id) {
    for (final puzzle in _puzzles) {
      if (puzzle.id == id) return puzzle;
    }
    return null;
  }

  Future<void> _persist() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(
        AppConstants.prefKeyCustomPuzzles,
        jsonEncode([for (final puzzle in _puzzles) puzzle.toJson()]),
      );
    } catch (error, stack) {
      LogService.error('保存自定义残局失败', error, stack);
    }
  }
}
