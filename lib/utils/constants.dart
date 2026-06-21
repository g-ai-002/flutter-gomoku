/// 应用全局常量
class AppConstants {
  AppConstants._();

  static const String appName = '五子棋';
  static const String version = '0.1.1';

  // SharedPreferences keys
  static const String prefKeyDarkMode = 'dark_mode';
  static const String prefKeyBoardSize = 'board_size';
  static const String prefKeySoundEnabled = 'sound_enabled';

  // 棋盘默认大小
  static const int defaultBoardSize = 15;
  // 棋盘最小/最大大小
  static const int minBoardSize = 9;
  static const int maxBoardSize = 19;
}
