import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'log_service.dart';
import 'tone_synth.dart';

/// 落子反馈类型，决定提示音与震动的强弱。
enum MoveFeedback { place, threat, win, lose }

/// 落子音效与触感反馈。
///
/// 音效由 [synthesizeWav] 在运行时合成，不随包携带音频文件；合成好的
/// WAV 交给 flutter_soloud 的内存音源播放，Android、Windows 与 Web 共用
/// 同一套实现，Web 的自动播放限制会在用户首次操作页面后解除。
class SoundService {
  SoundService._();

  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  /// 测试注入的音频出口，非空时不再触碰平台播放器。
  @visibleForTesting
  static void Function(MoveFeedback feedback)? sink;

  static final Map<MoveFeedback, AudioSource> _sources = {};
  static final Map<MoveFeedback, Uint8List> _clips = {};
  static Future<void>? _loading;
  static bool _loadFailed = false;

  /// 四级音效的乐音配方：落子轻脆、威胁上行、胜利明亮、失利下沉。
  static const Map<MoveFeedback, List<SynthNote>> _presets = {
    MoveFeedback.place: [
      SynthNote(1180, 0, 0.055, 0.55, 0.14),
      SynthNote(720, 0.004, 0.09, 0.34, 0.06),
    ],
    MoveFeedback.threat: [
      SynthNote(760, 0, 0.09),
      SynthNote(1015, 0.075, 0.13),
    ],
    MoveFeedback.win: [
      SynthNote(523.25, 0, 0.14),
      SynthNote(659.25, 0.11, 0.14),
      SynthNote(783.99, 0.22, 0.18),
      SynthNote(1046.5, 0.34, 0.34),
    ],
    MoveFeedback.lose: [
      SynthNote(659.25, 0, 0.16),
      SynthNote(523.25, 0.13, 0.18),
      SynthNote(349.23, 0.27, 0.34, 0.55),
    ],
  };

  static void configure({required bool sound, required bool haptics}) {
    soundEnabled = sound;
    hapticsEnabled = haptics;
  }

  /// 预合成音效并载入 SoLoud 音源；失败时保持静默，不影响对局。
  static Future<void> init() => _ensureLoaded();

  /// 退出应用前释放 SoLoud 引擎（音效与背景音乐共用同一个引擎）。
  ///
  /// 引擎必须 deinit 之后再让进程退出：带着音频设备直接退时，Windows 上窗口
  /// 销毁后引擎的拆除会卡住，宿主进程留在任务管理器里不退出。
  static Future<void> shutdown() async {
    _sources.clear();
    _loading = null;
    _loadFailed = true;
    if (!SoLoud.instance.isInitialized) return;
    try {
      await SoLoud.instance.deinitAsync();
    } catch (error) {
      debugPrint('[SoundService] 音频引擎释放失败: $error');
    }
  }

  static Future<void> _ensureLoaded() {
    if (_loadFailed || _sources.isNotEmpty) return Future.value();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) await soloud.init();
      for (final feedback in MoveFeedback.values) {
        _sources[feedback] = await soloud.loadMem(
          'gomoku-${feedback.name}.wav',
          clipOf(feedback),
        );
      }
    } catch (error) {
      _loadFailed = true;
      _disposeAll();
      debugPrint('[SoundService] 音效初始化失败，已静音: $error');
      LogService.warning('音效初始化失败，已静音: $error');
    }
  }

  /// 某个反馈对应的合成音频，供测试校验音效配方。
  @visibleForTesting
  static Uint8List clipOf(MoveFeedback feedback) =>
      _clips.putIfAbsent(feedback, () => synthesizeWav(_presets[feedback]!));

  /// 轻触棋盘的触感：只走触感，不播放提示音。
  static void tap() {
    if (hapticsEnabled) HapticFeedback.selectionClick();
  }

  static void play(MoveFeedback feedback) {
    if (soundEnabled) {
      final target = sink;
      if (target != null) {
        target(feedback);
      } else {
        unawaited(_play(feedback));
      }
    }
    if (!hapticsEnabled) return;
    final haptic = switch (feedback) {
      MoveFeedback.place => HapticFeedback.selectionClick,
      MoveFeedback.threat => HapticFeedback.lightImpact,
      MoveFeedback.win => HapticFeedback.mediumImpact,
      MoveFeedback.lose => HapticFeedback.vibrate,
    };
    haptic();
  }

  static Future<void> _play(MoveFeedback feedback) async {
    try {
      await _ensureLoaded();
      final source = _sources[feedback];
      if (source == null) return;
      final soloud = SoLoud.instance;
      soloud.stopAudioSource(source);
      soloud.play(source);
    } catch (error) {
      debugPrint('[SoundService] 播放失败: $error');
    }
  }

  static void _disposeAll() {
    final sources = _sources.values.toList();
    _sources.clear();
    for (final source in sources) {
      unawaited(_dispose(source));
    }
  }

  static Future<void> _dispose(AudioSource source) async {
    try {
      await SoLoud.instance.disposeSource(source);
    } catch (_) {
      // 音源已失效时无需再处理。
    }
  }

  @visibleForTesting
  static void reset() {
    sink = null;
    _disposeAll();
    _clips.clear();
    _loading = null;
    _loadFailed = false;
    soundEnabled = true;
    hapticsEnabled = true;
  }
}
