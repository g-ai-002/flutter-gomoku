import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/game_history_service.dart';
import 'services/log_service.dart';
import 'services/logging_init.dart';
import 'services/music_service.dart';
import 'services/puzzle_progress_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';
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

  // 窗口设置、日志与偏好互不依赖，并行准备以缩短首帧前的等待。
  final storageFuture = StorageService.instance;
  await Future.wait([setupDesktopWindow(), initLogging()]);

  final storage = await storageFuture;
  await Future.wait([
    GameHistoryService.instance.load(),
    PuzzleProgressService.instance.load(),
  ]);
  LogService.info('应用启动: ${AppConstants.appName} v${AppConstants.version}');
  MusicService.enabled = storage.musicEnabled;

  runApp(GomokuApp(storage: storage));
  // 音效与音乐由纯 Dart 在运行时合成，放到首帧之后再启动，
  // 让首页先完成绘制，避免合成占用启动时的主线程。
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(SoundService.init());
    // Web 需要用户手势才能播放，首次点击页面时由 App 的监听器启动。
    if (storage.musicEnabled && !kIsWeb) unawaited(MusicService.start());
  });
}
