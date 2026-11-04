import '../game/engine/board_utils.dart';

/// 难度档位：搜索深度、原着随机度与思考时限。
enum Difficulty {
  entry('入门', 2, 8000, 600),
  normal('普通', 3, 1500, 2000),
  expert('高手', 4, 0, 5000);

  const Difficulty(
    this.label,
    this.depth,
    this.randomness,
    this.timeLimitMillis,
  );

  final String label;

  /// 搜索层数。
  final int depth;

  /// 评分容差：与最优着法分差在此范围内的着法都可能被选中，越大越随性。
  final int randomness;

  /// 单步思考时限（毫秒），与深度先到先停。
  final int timeLimitMillis;

  /// 未设置或未知值时回退到默认难度（高手）。
  static Difficulty byName(String? name) => values.firstWhere(
    (item) => item.name == name,
    orElse: () => Difficulty.expert,
  );
}

/// 对弈模式。
enum GameMode {
  vsAi('人机对战'),
  twoPlayers('双人对弈');

  const GameMode(this.label);

  final String label;
}

/// 限时方案：每方总时长，[none] 表示不限时。
enum TimeControl {
  none('不限时', 0),
  blitz('5 分钟', 300),
  rapid('10 分钟', 600),
  classical('20 分钟', 1200);

  const TimeControl(this.label, this.seconds);

  final String label;
  final int seconds;

  bool get isTimed => seconds > 0;

  int get millis => seconds * 1000;

  static TimeControl byName(String? name) => values.firstWhere(
    (item) => item.name == name,
    orElse: () => TimeControl.none,
  );
}

/// 对局结果。
class GameResult {
  const GameResult({required this.winner, required this.reason});

  /// 胜方（[black]/[white]），和棋时为 null。
  final int? winner;
  final String reason;

  bool get isDraw => winner == null;

  String get title {
    if (winner == null) return '和棋';
    return winner == black ? '黑方胜' : '白方胜';
  }
}
