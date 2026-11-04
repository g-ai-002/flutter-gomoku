import 'notation.dart';

/// 一条内置开局：从天元起手，黑白交替的六手参考着法。
class OpeningLine {
  const OpeningLine({
    required this.id,
    required this.name,
    required this.family,
    required this.tagline,
    required this.moves,
    required this.idea,
  });

  final String id;
  final String name;

  /// 白棋第二手与黑棋的相对关系：直指或斜指。
  final String family;

  /// 一句话概括这条开局的思路。
  final String tagline;

  /// 前六手着法（交叉点下标），黑先，黑白交替。
  final List<int> moves;

  /// 开局讲解，展示在开局库页面。
  final String idea;
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
final List<OpeningLine> kOpeningLines = [
  OpeningLine(
    id: 'direct-diagonal',
    name: '直指·斜连',
    family: '直指',
    tagline: '黑棋斜向连二，向中腹渗透',
    moves: [
      _point('H8'),
      _point('I8'),
      _point('G7'),
      _point('I9'),
      _point('I7'),
      _point('I10'),
    ],
    idea: '白棋直指贴近天元，黑棋在左下斜向连二，随后抢到上方的连接点，形成可攻可守的斜线。',
  ),
  OpeningLine(
    id: 'direct-line',
    name: '直指·同线',
    family: '直指',
    tagline: '沿直线延伸，稳固中轴',
    moves: [
      _point('H8'),
      _point('I8'),
      _point('G8'),
      _point('H9'),
      _point('G10'),
      _point('G9'),
    ],
    idea: '黑棋沿横线展开，白棋从上方压制；第六手白棋插入黑棋之间，局面转入中盘争夺。',
  ),
  OpeningLine(
    id: 'direct-press',
    name: '直指·上压',
    family: '直指',
    tagline: '贴住白棋上方，抢外势',
    moves: [
      _point('H8'),
      _point('I8'),
      _point('I7'),
      _point('G9'),
      _point('H7'),
      _point('H9'),
    ],
    idea: '黑棋不急于连子，先贴住白棋上方限制其发展，再用下方的落点换取出击空间。',
  ),
  OpeningLine(
    id: 'indirect-guard',
    name: '斜指·回防',
    family: '斜指',
    tagline: '白棋斜指，黑棋回守下翼',
    moves: [
      _point('H8'),
      _point('I9'),
      _point('G8'),
      _point('I8'),
      _point('I7'),
      _point('G9'),
    ],
    idea: '白棋斜指后，黑棋在下翼回防并顺势连二，白棋则沿右侧继续施加压力。',
  ),
  OpeningLine(
    id: 'indirect-flow',
    name: '斜指·顺势',
    family: '斜指',
    tagline: '顺白棋方向斜出，保持对称',
    moves: [
      _point('H8'),
      _point('I9'),
      _point('G9'),
      _point('I7'),
      _point('I8'),
      _point('J8'),
    ],
    idea: '黑棋顺着白棋的斜线方向落子，保持左右对称，把战斗引向棋盘右侧。',
  ),
  OpeningLine(
    id: 'indirect-counter',
    name: '斜指·反压',
    family: '斜指',
    tagline: '反向斜出，争夺另一侧',
    moves: [
      _point('H8'),
      _point('I9'),
      _point('I7'),
      _point('G9'),
      _point('H9'),
      _point('H10'),
    ],
    idea: '黑棋反向斜出，避免与白棋正面纠缠，转而争夺上翼的主动权。',
  ),
];
