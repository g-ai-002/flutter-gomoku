import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/notation.dart';

void main() {
  group('坐标记法', () {
    test('左上、天元与右下', () {
      expect(MoveNotation.describe(indexOf(0, 0)), 'A1');
      expect(MoveNotation.describe(centerIndex), 'H8');
      expect(MoveNotation.describe(indexOf(14, 14)), 'O15');
    });

    test('解析与生成可以往返', () {
      for (var index = 0; index < cellCount; index += 7) {
        expect(MoveNotation.parse(MoveNotation.describe(index)), index);
      }
    });

    test('兼容小写与空格', () {
      expect(MoveNotation.parse(' h8 '), centerIndex);
      expect(MoveNotation.parse('O15'), indexOf(14, 14));
    });

    test('非法记法返回 null', () {
      expect(MoveNotation.parse('P1'), isNull);
      expect(MoveNotation.parse('A16'), isNull);
      expect(MoveNotation.parse('A0'), isNull);
      expect(MoveNotation.parse(''), isNull);
      expect(MoveNotation.parse('H'), isNull);
      expect(MoveNotation.parse('88'), isNull);
    });
  });
}
