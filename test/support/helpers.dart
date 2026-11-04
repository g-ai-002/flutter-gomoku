import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/providers/settings_provider.dart';
import 'package:gomoku/services/game_history_service.dart';
import 'package:gomoku/services/puzzle_progress_service.dart';
import 'package:gomoku/services/storage_service.dart';
import 'package:gomoku/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 组件测试共用的偏好初始化：每次使用干净的 mock 存储。
Future<SettingsProvider> createSettings({
  Map<String, Object> values = const {},
}) async {
  SharedPreferences.setMockInitialValues(values);
  StorageService.resetForTests();
  GameHistoryService.instance.resetForTest();
  PuzzleProgressService.instance.resetForTest();
  final storage = await StorageService.instance;
  return SettingsProvider(storage);
}

Widget wrapPage(Widget child, SettingsProvider settings) =>
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      child: MaterialApp(theme: buildLightTheme(), home: child),
    );
