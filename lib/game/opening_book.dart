import 'notation.dart';

/// 一条内置开局：从天元起手，黑白交替的六手参考着法。
class OpeningLine {
  const OpeningLine({
    required this.id,
    required this.name,
    required this.moves,
  });

  final String id;
  final String name;

  /// 前六手着法（交叉点下标），黑先，黑白交替。
  final List<int> moves;
}

/// 一次开局匹配：命中的棋谱、已走手数与下一手参考着法。
class OpeningMatch {
  const OpeningMatch({required this.line, required this.plies});

  final OpeningLine line;

  /// 棋谱与开局线一致的手数。
  final int plies;

  int? get nextMove => plies < line.moves.length ? line.moves[plies] : null;

  /// 前两手之后才显示开局名，避免白棋尚未定型时误标。
  String? get name => plies >= 3 ? line.name : null;
}

/// 开局库：按前若干手匹配开局，并给出下一手参考着法。
class OpeningBook {
  const OpeningBook(this.lines);

  static final OpeningBook standard = OpeningBook(kOpeningLines);

  final List<OpeningLine> lines;

  /// 与 [moves] 前缀一致的全部开局，顺序即内置顺序。
  List<OpeningLine> candidates(List<int> moves) => [
    for (final line in lines)
      if (moves.length <= line.moves.length && _matches(line, moves)) line,
  ];

  /// 优先返回 [preferred]（仍在候选中时），否则取候选中的第一条。
  OpeningMatch? match(List<int> moves, {OpeningLine? preferred}) {
    final available = candidates(moves);
    if (available.isEmpty) return null;
    final line = preferred != null && available.contains(preferred)
        ? preferred
        : available.first;
    return OpeningMatch(line: line, plies: moves.length);
  }

  static bool _matches(OpeningLine line, List<int> moves) {
    for (var i = 0; i < moves.length; i++) {
      if (line.moves[i] != moves[i]) return false;
    }
    return true;
  }
}

int _point(String notation) => MoveNotation.parse(notation)!;

/// 六条参考开局，均由本地引擎从前六手对弈中筛选，覆盖直指与斜指两类。
/// 开局名以「直指 / 斜指」开头，实战浮层只展示名称。
final List<OpeningLine> kOpeningLines = [
  OpeningLine(
    id: 'direct-diagonal',
    name: '直指·斜连',
    moves: [
      _point('H8'),
      _point('I8'),
      _point('G7'),
      _point('I9'),
      _point('I7'),
      _point('I10'),
    ],
  ),
  OpeningLine(
    id: 'direct-line',
    name: '直指·同线',
    moves: [
      _point('H8'),
      _point('I8'),
      _point('G8'),
      _point('H9'),
      _point('G10'),
      _point('G9'),
    ],
  ),
  OpeningLine(
    id: 'direct-press',
    name: '直指·上压',
    moves: [
      _point('H8'),
      _point('I8'),
      _point('I7'),
      _point('G9'),
      _point('H7'),
      _point('H9'),
    ],
  ),
  OpeningLine(
    id: 'indirect-guard',
    name: '斜指·回防',
    moves: [
      _point('H8'),
      _point('I9'),
      _point('G8'),
      _point('I8'),
      _point('I7'),
      _point('G9'),
    ],
  ),
  OpeningLine(
    id: 'indirect-flow',
    name: '斜指·顺势',
    moves: [
      _point('H8'),
      _point('I9'),
      _point('G9'),
      _point('I7'),
      _point('I8'),
      _point('J8'),
    ],
  ),
  OpeningLine(
    id: 'indirect-counter',
    name: '斜指·反压',
    moves: [
      _point('H8'),
      _point('I9'),
      _point('I7'),
      _point('G9'),
      _point('H9'),
      _point('H10'),
    ],
  ),
];
