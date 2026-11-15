import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'services/game_history_service.dart';
import 'services/log_service.dart';
import 'services/logging_init.dart';
import 'services/music_service.dart';
import 'services/puzzle_progress_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';
import 'utils/system_ui.dart';
import 'utils/window_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LogService.error('Flutter 异常', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    LogService.error('未捕获异常', error, stack);
    return true;
  };

  // 窗口设置、日志与系统栏互不依赖，并行准备以缩短首帧前的等待。
  final storageFuture = StorageService.instance;
  await Future.wait([setupDesktopWindow(), initLogging(), enableEdgeToEdge()]);

  final storage = await storageFuture;
  LogService.info('应用启动: ${AppConstants.appName} v${AppConstants.version}');
  MusicService.enabled = storage.musicEnabled;

  runApp(GomokuApp(storage: storage));
  // 棋谱库与残局进度不参与首帧渲染，放到首帧之后再读取；
  // 音效与音乐同样延后启动，避免合成占用启动时的主线程。
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(GameHistoryService.instance.load());
    unawaited(PuzzleProgressService.instance.load());
    unawaited(SoundService.init());
    // Web 需要用户手势才能播放，首次点击页面时由 App 的监听器启动。
    if (storage.musicEnabled && !kIsWeb) unawaited(MusicService.start());
  });
}
