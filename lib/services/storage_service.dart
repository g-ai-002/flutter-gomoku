import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// 简单存储服务封装：SharedPreferences
class StorageService {
  static Future<StorageService>? _initFuture;

  SharedPreferences? _prefs;
  bool _initialized = false;

  StorageService._();

  static Future<StorageService> get instance {
    final cached = _initFuture;
    if (cached != null) return cached;
    final f = _bootstrap();
    _initFuture = f;
    return f;
  }

  static Future<StorageService> _bootstrap() async {
    final s = StorageService._();
    await s._init();
    return s;
  }

  Future<void> _init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('StorageService 尚未初始化');
    }
    return p;
  }

  // ---- 主题 ----
  bool get darkMode => _p.getBool(AppConstants.prefKeyDarkMode) ?? false;
  Future<void> setDarkMode(bool v) =>
      _p.setBool(AppConstants.prefKeyDarkMode, v);

  // ---- 棋盘大小 ----
  int get boardSize =>
      _p.getInt(AppConstants.prefKeyBoardSize) ?? AppConstants.defaultBoardSize;
  Future<void> setBoardSize(int v) =>
      _p.setInt(AppConstants.prefKeyBoardSize, v);

  // ---- 音效 ----
  bool get soundEnabled =>
      _p.getBool(AppConstants.prefKeySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool v) =>
      _p.setBool(AppConstants.prefKeySoundEnabled, v);
}
