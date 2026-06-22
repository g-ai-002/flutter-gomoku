import 'package:shared_preferences/shared_preferences.dart';
import '../ai/ai_engine.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';

/// 简单存储服务封装：SharedPreferences
class StorageService {
  static StorageService? _instance;

  final SharedPreferences _prefs;

  StorageService._(this._prefs);

  static Future<StorageService> get instance async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = StorageService._(prefs);
    return _instance!;
  }

  /// 仅用于测试：重置单例
  static void reset() {
    _instance = null;
  }

  // ---- 主题 ----
  bool get darkMode => _prefs.getBool(AppConstants.prefKeyDarkMode) ?? false;
  Future<void> setDarkMode(bool v) =>
      _prefs.setBool(AppConstants.prefKeyDarkMode, v);

  // ---- 棋盘大小 ----
  int get boardSize =>
      _prefs.getInt(AppConstants.prefKeyBoardSize) ?? AppConstants.defaultBoardSize;
  Future<void> setBoardSize(int v) =>
      _prefs.setInt(AppConstants.prefKeyBoardSize, v);

  // ---- 音效 ----
  bool get soundEnabled =>
      _prefs.getBool(AppConstants.prefKeySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool v) =>
      _prefs.setBool(AppConstants.prefKeySoundEnabled, v);

  // ---- 游戏模式 ----
  GameMode get gameMode {
    final v = _prefs.getString(AppConstants.prefKeyGameMode);
    if (v == GameMode.pve.name) return GameMode.pve;
    return GameMode.pvp;
  }

  Future<void> setGameMode(GameMode v) =>
      _prefs.setString(AppConstants.prefKeyGameMode, v.name);

  // ---- AI 难度 ----
  AIDifficulty get aiDifficulty {
    final v = _prefs.getString(AppConstants.prefKeyAIDifficulty);
    if (v == AIDifficulty.easy.name) return AIDifficulty.easy;
    if (v == AIDifficulty.hard.name) return AIDifficulty.hard;
    return AIDifficulty.medium;
  }

  Future<void> setAIDifficulty(AIDifficulty v) =>
      _prefs.setString(AppConstants.prefKeyAIDifficulty, v.name);
}
