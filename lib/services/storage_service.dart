import 'package:shared_preferences/shared_preferences.dart';

import '../game/engine/board_utils.dart';
import '../game/handicap.dart';
import '../models/game_models.dart';
import '../utils/constants.dart';

/// 轻量偏好存储：写入失败时静默忽略，不影响对局主流程。
class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> get instance async {
    if (_instance != null) return _instance!;
    final service = StorageService._();
    service._prefs = await SharedPreferences.getInstance();
    _instance = service;
    return service;
  }

  /// 仅供测试：清空单例，配合 SharedPreferences 的 mock 数据使用。
  static void resetForTests() => _instance = null;

  SharedPreferences get _p {
    final prefs = _prefs;
    if (prefs == null) throw StateError('StorageService 尚未初始化');
    return prefs;
  }

  Future<void> _write(
    Future<bool> Function(SharedPreferences prefs) action,
  ) async {
    try {
      await action(_p);
    } catch (_) {}
  }

  bool get darkMode => _p.getBool(AppConstants.prefKeyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyDarkMode, value));

  bool get showCoordinates =>
      _p.getBool(AppConstants.prefKeyShowCoordinates) ?? true;
  Future<void> setShowCoordinates(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyShowCoordinates, value));

  bool get soundEnabled => _p.getBool(AppConstants.prefKeySound) ?? true;
  Future<void> setSoundEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeySound, value));

  bool get musicEnabled => _p.getBool(AppConstants.prefKeyMusic) ?? true;
  Future<void> setMusicEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyMusic, value));

  bool get hapticsEnabled => _p.getBool(AppConstants.prefKeyHaptics) ?? true;
  Future<void> setHapticsEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyHaptics, value));

  /// 棋钟方案，未设置或未知值回退到不限时。
  TimeControl get timeControl =>
      TimeControl.byName(_p.getString(AppConstants.prefKeyTimeControl));
  Future<void> setTimeControl(TimeControl value) =>
      _write((p) => p.setString(AppConstants.prefKeyTimeControl, value.name));

  /// 人机对战执黑时是否使用内置开局库。
  bool get openingHints => _p.getBool(AppConstants.prefKeyOpeningHints) ?? true;
  Future<void> setOpeningHints(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyOpeningHints, value));

  /// 是否启用黑棋禁手（长连、四四、三三），默认关闭。
  bool get forbiddenRule =>
      _p.getBool(AppConstants.prefKeyForbiddenRule) ?? false;
  Future<void> setForbiddenRule(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyForbiddenRule, value));

  /// AI 难度，未设置或未知值回退到默认难度（高手）。
  Difficulty get difficulty =>
      Difficulty.byName(_p.getString(AppConstants.prefKeyDifficulty));

  Future<void> setDifficulty(Difficulty value) =>
      _write((p) => p.setString(AppConstants.prefKeyDifficulty, value.name));

  /// 人类执子方：黑棋先行，白棋后行。
  int get humanSide => _p.getInt(AppConstants.prefKeyHumanSide) ?? black;
  Future<void> setHumanSide(int value) =>
      _write((p) => p.setInt(AppConstants.prefKeyHumanSide, value));

  /// 人机执黑时的让子方案，未设置或未知值回退到不让子。
  Handicap get handicap =>
      Handicap.byName(_p.getString(AppConstants.prefKeyHandicap));

  Future<void> setHandicap(Handicap value) =>
      _write((p) => p.setString(AppConstants.prefKeyHandicap, value.name));
}
