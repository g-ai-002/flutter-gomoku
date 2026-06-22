import 'package:flutter/material.dart';

/// 应用全局常量
class AppConstants {
  AppConstants._();

  static const String appName = '五子棋';
  static const String version = '0.3.2';

  // SharedPreferences keys
  static const String prefKeyDarkMode = 'dark_mode';
  static const String prefKeyBoardSize = 'board_size';
  static const String prefKeySoundEnabled = 'sound_enabled';
  static const String prefKeyGameMode = 'game_mode';
  static const String prefKeyAIDifficulty = 'ai_difficulty';

  // 棋盘默认大小
  static const int defaultBoardSize = 15;
  // 棋盘最小/最大大小
  static const int minBoardSize = 9;
  static const int maxBoardSize = 19;

  // 棋盘大小选项
  static const List<int> boardSizeOptions = [9, 13, 15, 19];

  // 棋子颜色
  static const Color blackStoneLight = Color(0xFF555555);
  static const Color blackStoneDark = Color(0xFF111111);
  static const Color blackStoneBorder = Color(0xFF333333);
  static const Color whiteStoneLight = Color(0xFFFFFFFF);
  static const Color whiteStoneDark = Color(0xFFCCCCCC);
  static const Color whiteStoneBorder = Color(0xFFAAAAAA);

  // 棋子半径比例
  static const double stoneRadiusRatio = 0.43;

  // 棋盘内边距
  static const double boardPadding = 16;

  // AI 落子延迟
  static const int aiMoveDelayMs = 200;

  // 回放自动播放间隔
  static const int replayAutoPlayDelayMs = 500;

  // 日志
  static const int logMaxFileSize = 5 * 1024 * 1024;
  static const int logMaxRetentionDays = 7;
}
