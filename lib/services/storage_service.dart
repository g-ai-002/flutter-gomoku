import 'package:shared_preferences/shared_preferences.dart';

import '../game/engine/board_utils.dart';
import '../game/handicap.dart';
import '../game/logic_rate.dart';
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

  bool _bool(String key, {bool fallback = false}) =>
      _p.getBool(key) ?? fallback;

  String? _string(String key) => _p.getString(key);

  int _int(String key, {int fallback = 0}) => _p.getInt(key) ?? fallback;

  Future<void> _write(
    Future<bool> Function(SharedPreferences prefs) action,
  ) async {
    try {
      await action(_p);
    } catch (_) {}
  }

  Future<void> _setBool(String key, bool value) =>
      _write((p) => p.setBool(key, value));

  Future<void> _setString(String key, String value) =>
      _write((p) => p.setString(key, value));

  Future<void> _setInt(String key, int value) =>
      _write((p) => p.setInt(key, value));

  bool get darkMode => _bool(AppConstants.prefKeyDarkMode);
  Future<void> setDarkMode(bool value) =>
      _setBool(AppConstants.prefKeyDarkMode, value);

  bool get showCoordinates =>
      _bool(AppConstants.prefKeyShowCoordinates, fallback: true);
  Future<void> setShowCoordinates(bool value) =>
      _setBool(AppConstants.prefKeyShowCoordinates, value);

  /// 棋盘浮层的实时形势判断，默认开启。
  bool get showPosition =>
      _bool(AppConstants.prefKeyShowPosition, fallback: true);
  Future<void> setShowPosition(bool value) =>
      _setBool(AppConstants.prefKeyShowPosition, value);

  bool get soundEnabled => _bool(AppConstants.prefKeySound, fallback: true);
  Future<void> setSoundEnabled(bool value) =>
      _setBool(AppConstants.prefKeySound, value);

  bool get musicEnabled => _bool(AppConstants.prefKeyMusic, fallback: true);
  Future<void> setMusicEnabled(bool value) =>
      _setBool(AppConstants.prefKeyMusic, value);

  bool get hapticsEnabled => _bool(AppConstants.prefKeyHaptics, fallback: true);
  Future<void> setHapticsEnabled(bool value) =>
      _setBool(AppConstants.prefKeyHaptics, value);

  /// 棋盘逻辑更新速率，未设置或未知值回退到 60Hz。
  LogicRate get logicRate =>
      LogicRate.byName(_string(AppConstants.prefKeyLogicRate));
  Future<void> setLogicRate(LogicRate value) =>
      _setString(AppConstants.prefKeyLogicRate, value.name);

  /// 棋钟方案，未设置或未知值回退到不限时。
  TimeControl get timeControl =>
      TimeControl.byName(_string(AppConstants.prefKeyTimeControl));
  Future<void> setTimeControl(TimeControl value) =>
      _setString(AppConstants.prefKeyTimeControl, value.name);

  /// 人机对战执黑时是否使用内置开局库。
  bool get openingHints =>
      _bool(AppConstants.prefKeyOpeningHints, fallback: true);
  Future<void> setOpeningHints(bool value) =>
      _setBool(AppConstants.prefKeyOpeningHints, value);

  /// 是否启用黑棋禁手（长连、四四、三三），默认关闭。
  bool get forbiddenRule => _bool(AppConstants.prefKeyForbiddenRule);
  Future<void> setForbiddenRule(bool value) =>
      _setBool(AppConstants.prefKeyForbiddenRule, value);

  /// AI 难度，未设置或未知值回退到默认难度（高手）。
  Difficulty get difficulty =>
      Difficulty.byName(_string(AppConstants.prefKeyDifficulty));
  Future<void> setDifficulty(Difficulty value) =>
      _setString(AppConstants.prefKeyDifficulty, value.name);

  /// 人类执子方：黑棋先行，白棋后行。
  int get humanSide => _int(AppConstants.prefKeyHumanSide, fallback: black);
  Future<void> setHumanSide(int value) =>
      _setInt(AppConstants.prefKeyHumanSide, value);

  /// 人机执黑时的让子方案，未设置或未知值回退到不让子。
  Handicap get handicap =>
      Handicap.byName(_string(AppConstants.prefKeyHandicap));
  Future<void> setHandicap(Handicap value) =>
      _setString(AppConstants.prefKeyHandicap, value.name);
}
