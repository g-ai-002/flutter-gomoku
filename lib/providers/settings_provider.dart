import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/game_models.dart';
import '../services/music_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';

/// 用户偏好：主题、难度、先后手、坐标与音效。
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage) {
    _syncFeedback();
  }

  final StorageService _storage;

  bool get darkMode => _storage.darkMode;
  Future<void> setDarkMode(bool value) =>
      _update(() => _storage.setDarkMode(value));

  Difficulty get difficulty => _storage.difficulty;
  Future<void> setDifficulty(Difficulty value) =>
      _update(() => _storage.setDifficulty(value));

  int get humanSide => _storage.humanSide;
  Future<void> setHumanSide(int value) =>
      _update(() => _storage.setHumanSide(value));

  bool get soundEnabled => _storage.soundEnabled;
  Future<void> setSoundEnabled(bool value) => _update(() async {
    await _storage.setSoundEnabled(value);
    _syncFeedback();
  });

  bool get musicEnabled => _storage.musicEnabled;
  Future<void> setMusicEnabled(bool value) => _update(() async {
    await _storage.setMusicEnabled(value);
    // 音频启停不阻塞开关反馈，加载失败时 MusicService 自行记录日志。
    unawaited(MusicService.setEnabled(value));
  });

  bool get hapticsEnabled => _storage.hapticsEnabled;
  Future<void> setHapticsEnabled(bool value) => _update(() async {
    await _storage.setHapticsEnabled(value);
    _syncFeedback();
  });

  bool get showCoordinates => _storage.showCoordinates;
  Future<void> setShowCoordinates(bool value) =>
      _update(() => _storage.setShowCoordinates(value));

  TimeControl get timeControl => _storage.timeControl;
  Future<void> setTimeControl(TimeControl value) =>
      _update(() => _storage.setTimeControl(value));

  /// 开局提示开关：人机对战执黑时是否参考内置开局库。
  bool get openingHints => _storage.openingHints;
  Future<void> setOpeningHints(bool value) =>
      _update(() => _storage.setOpeningHints(value));

  /// 禁手规则开关：开启后黑棋不可长连、四四与三三。
  bool get forbiddenRule => _storage.forbiddenRule;
  Future<void> setForbiddenRule(bool value) =>
      _update(() => _storage.setForbiddenRule(value));

  void _syncFeedback() =>
      SoundService.configure(sound: soundEnabled, haptics: hapticsEnabled);

  /// 写入偏好后统一通知界面，避免每个 setter 重复一遍。
  Future<void> _update(Future<void> Function() write) async {
    await write();
    notifyListeners();
  }
}
