/// 界面共用的中文书法字体回退链：优先楷体，其次各平台常见的中文字体。
const List<String> kKaiFontFallback = [
  'STKaiti',
  'Microsoft YaHei UI',
  'SimSun',
  'Noto Serif CJK SC',
  'Noto Sans CJK SC',
];

/// Web 端字体：CanvasKit 没有系统中文字体回退，使用 soup_fonts 的思源黑体。
const String kWebFontFamily = 'SourceHanSansCN';

class AppConstants {
  AppConstants._();

  static const String appName = '五子棋';
  static const String version = '0.3.1';

  static const String prefKeyDarkMode = 'dark_mode';
  static const String prefKeyDifficulty = 'difficulty';
  static const String prefKeyHumanSide = 'human_side';
  static const String prefKeyShowCoordinates = 'show_coordinates';
  static const String prefKeyBoardSkin = 'board_skin';
  static const String prefKeySound = 'sound_enabled';
  static const String prefKeyMusic = 'music_enabled';
  static const String prefKeyHaptics = 'haptics_enabled';
  static const String prefKeyTimeControl = 'time_control';
  static const String prefKeyGameHistory = 'game_history';
  static const String prefKeyOpeningHints = 'opening_hints';
  static const String prefKeyPuzzleProgress = 'puzzle_progress';
  static const String prefKeyForbiddenRule = 'forbidden_rule';
}
