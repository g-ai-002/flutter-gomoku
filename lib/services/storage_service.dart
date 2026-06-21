import 'package:shared_preferences/shared_preferences.dart';
import '../ai/ai_engine.dart';
import '../utils/constants.dart';

/// 游戏模式
enum GameMode {
  pvp,
  pve;

  String get label {
    switch (this) {
      case GameMode.pvp:
        return '双人对弈';
      case GameMode.pve:
        return '人机对弈';
    }
  }
}

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
    return v == 'pve' ? GameMode.pve : GameMode.pvp;
  }

  Future<void> setGameMode(GameMode v) =>
      _prefs.setString(AppConstants.prefKeyGameMode, v == GameMode.pve ? 'pve' : 'pvp');

  // ---- AI 难度 ----
  AIDifficulty get aiDifficulty {
    final v = _prefs.getString(AppConstants.prefKeyAIDifficulty);
    switch (v) {
      case 'easy':
        return AIDifficulty.easy;
      case 'hard':
        return AIDifficulty.hard;
      default:
        return AIDifficulty.medium;
    }
  }

  Future<void> setAIDifficulty(AIDifficulty v) async {
    String key;
    switch (v) {
      case AIDifficulty.easy:
        key = 'easy';
        break;
      case AIDifficulty.hard:
        key = 'hard';
        break;
      default:
        key = 'medium';
    }
    await _prefs.setString(AppConstants.prefKeyAIDifficulty, key);
  }
}
