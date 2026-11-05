import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/custom_puzzles.dart';
import 'package:gomoku/game/puzzle_share_code.dart';

CustomPuzzle _puzzle({
  String title = '双三杀',
  int moveLimit = 3,
  List<int> black = const [100, 101, 102],
  List<int> white = const [90, 91],
}) => CustomPuzzle(
  id: 'custom_test',
  title: title,
  moveLimit: moveLimit,
  blackStones: black,
  whiteStones: white,
  createdAt: DateTime(2026, 11, 5),
);

void main() {
  test('分享码往返保留名称、限手数与棋子', () {
    final code = PuzzleShareCode.encode(_puzzle());
    expect(code.startsWith('${PuzzleShareCode.prefix}~'), isTrue);

    final decoded = PuzzleShareCode.decode(code, now: DateTime(2026, 11, 6, 9));
    expect(decoded, isNotNull);
    expect(decoded!.title, '双三杀');
    expect(decoded.moveLimit, 3);
    expect(decoded.blackStones.toSet(), {100, 101, 102});
    expect(decoded.whiteStones.toSet(), {90, 91});
    expect(decoded.createdAt, DateTime(2026, 11, 6, 9));
    expect(decoded.id, startsWith('shared_'));
  });

  test('首尾空白不影响解析', () {
    final code = PuzzleShareCode.encode(_puzzle());
    expect(PuzzleShareCode.decode('  $code\n'), isNotNull);
  });

  test('拒绝被改动或截断的分享码', () {
    final code = PuzzleShareCode.encode(_puzzle());
    final parts = code.split('~');
    final flipped = parts[1].replaceRange(0, 1, parts[1][0] == 'A' ? 'B' : 'A');
    expect(PuzzleShareCode.decode('${parts[0]}~$flipped~${parts[2]}'), isNull);
    expect(PuzzleShareCode.decode(code.substring(0, code.length - 3)), isNull);
  });

  test('拒绝前缀、结构与编码错误的文本', () {
    final code = PuzzleShareCode.encode(_puzzle());
    final body = code.split('~')[1];
    expect(PuzzleShareCode.decode(''), isNull);
    expect(PuzzleShareCode.decode('GMK2~$body~00000000'), isNull);
    expect(PuzzleShareCode.decode('GMK1~$body'), isNull);
    expect(PuzzleShareCode.decode('GMK1~***~00000000'), isNull);
    expect(PuzzleShareCode.decode('随便一段文字'), isNull);
  });

  test('拒绝黑白重叠、坐标越界与空黑棋的局面', () {
    expect(
      PuzzleShareCode.decode(
        PuzzleShareCode.encode(_puzzle(black: const [50], white: const [50])),
      ),
      isNull,
    );
    expect(
      PuzzleShareCode.decode(
        PuzzleShareCode.encode(_puzzle(black: const [225])),
      ),
      isNull,
    );
    expect(
      PuzzleShareCode.decode(PuzzleShareCode.encode(_puzzle(black: const []))),
      isNull,
    );
  });

  test('拒绝名称超长或限手数越界的残局', () {
    expect(
      PuzzleShareCode.decode(
        PuzzleShareCode.encode(_puzzle(title: '这是一个超过二十个字符的残局名称用来测试校验')),
      ),
      isNull,
    );
    expect(
      PuzzleShareCode.decode(PuzzleShareCode.encode(_puzzle(moveLimit: 20))),
      isNull,
    );
  });

  test('拒绝已经成五的局面', () {
    expect(
      PuzzleShareCode.decode(
        PuzzleShareCode.encode(_puzzle(black: const [105, 106, 107, 108, 109])),
      ),
      isNull,
    );
  });
}
