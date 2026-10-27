import 'platform_info.dart';

/// 操作提示文案：同一套语义按桌面 / 触屏给出不同说法。
///
/// 各页面只引用这里的 getter，避免文案散落在 UI 代码里各写一份。
class GameHints {
  GameHints._();

  /// 移动：如何把落点对准交叉点
  static String get moveHint =>
      isDesktopPlatform ? '移动鼠标到交叉点，点击落子' : '手指轻触交叉点即可落子';

  /// 落子：落子后的可用操作
  static String get placeHint => isDesktopPlatform
      ? '落子后可继续点击下一点，按 R 可重新开始'
      : '落子后可继续轻触下一点，或点「重新开始」重开';

  /// 暂停：胜负分晓后棋盘主循环暂停
  static String get pauseHint => isDesktopPlatform
      ? '对局结束棋盘自动暂停，点「再来一局」继续'
      : '对局结束棋盘自动暂停，轻触「再来一局」继续';

  /// 悔棋
  static String get undoHint =>
      isDesktopPlatform ? '按 U 或点「悔棋」撤回上一手' : '点「悔棋」撤回上一手';

  /// 首页的一句话操作说明
  static String get homeHint => isDesktopPlatform
      ? '鼠标点击交叉点落子 · R 重新开始 · U 悔棋'
      : '轻触交叉点落子 · 按钮悔棋 / 重新开始';

  /// 游戏页操作条上方的说明
  static String get gameHint => '$moveHint；$undoHint';

  /// 设置页「操作提示」条目
  static String get settingsHint => '$moveHint；$pauseHint；$undoHint';
}
