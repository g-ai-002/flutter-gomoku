import 'package:shared_preferences/shared_preferences.dart';
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
}
