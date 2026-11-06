import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/learned_book.dart';
import 'package:gomoku/game/opening_book.dart';

LearnedLine _line(List<int> moves, {int wins = 2}) {
  final base = kOpeningLines.first;
  return (
    opening: OpeningLine(id: base.id, name: '${base.name}·精研', moves: moves),
    wins: wins,
  );
}

List<int> _extended() => [
  ...kOpeningLines.first.moves,
  indexOf(7, 9),
  indexOf(8, 7),
];

void main() {
  group('精研开局库', () {
    test('编码与解码往返保留精研线', () {
      final book = LearnedBook([_line(_extended(), wins: 3)]);
      final decoded = LearnedBook.decode(book.encode());
      expect(decoded.lines.length, 1);
      expect(decoded.lines.first.wins, 3);
      expect(decoded.lines.first.opening.name, endsWith('·精研'));
      expect(decoded.lines.first.opening.moves, _extended());
      expect(decoded.totalWins, 3);
    });

    test('空文本与损坏条目被忽略', () {
      expect(LearnedBook.decode(null).isEmpty, isTrue);
      expect(LearnedBook.decode('').isEmpty, isTrue);
      expect(LearnedBook.decode('坏数据;;a|b|c|1.2').isEmpty, isTrue);
      expect(LearnedBook.decode('id|名|x|1.2.3.4.5.6.7').isEmpty, isTrue);
      expect(LearnedBook.decode('id|名|1|1.2.3').isEmpty, isTrue);
    });

    test('精研线替换同 id 的内置开局', () {
      final merged = LearnedBook([_line(_extended())])
          .applyTo(OpeningBook.standard);
      expect(merged.lines.length, kOpeningLines.length);
      expect(
        merged.lines.where((line) => line.id == kOpeningLines.first.id).length,
        1,
      );
      expect(merged.lines.first.name, endsWith('·精研'));
      expect(merged.lines.first.moves.length, 8);
      expect(
        merged.lines.any((line) => line.id == kOpeningLines[1].id),
        isTrue,
      );
    });

    test('总胜局为各条精研线之和', () {
      final book = LearnedBook([
        _line(_extended()),
        _line(_extended(), wins: 5),
      ]);
      expect(book.totalWins, 7);
      expect(book.isEmpty, isFalse);
      expect(LearnedBook.empty.isEmpty, isTrue);
    });
  });
}
