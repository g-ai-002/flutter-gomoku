import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/board_state.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/game_archive.dart';
import 'package:gomoku/models/saved_game.dart';

GomokuBoard _playedBoard() {
  final board = GomokuBoard();
  for (final index in [
    indexOf(7, 7),
    indexOf(7, 8),
    indexOf(8, 8),
    indexOf(6, 6),
    indexOf(9, 9),
  ]) {
    board.apply(index);
  }
  return board;
}

void main() {
  group('棋谱文本', () {
    test('编码与解析可以往返', () {
      final board = _playedBoard();
      final text = GameArchive.encode(
        title: '人机对战 · 高手',
        moves: board.history,
        result: '黑方胜（五连）',
        date: DateTime(2026, 11, 4, 21, 30),
      );
      expect(text, contains('标题：人机对战 · 高手'));
      expect(text, contains('结果：黑方胜（五连）'));
      expect(text, contains('2026-11-04 21:30'));
      expect(text, contains('着法：'));

      final archived = GameArchive.decode(text);
      expect(archived, isNotNull);
      expect(archived!.title, '人机对战 · 高手');
      expect(archived.result, '黑方胜（五连）');
      expect(archived.date, '2026-11-04 21:30');
      expect(archived.moves, [for (final move in board.history) move.index]);
    });

    test('纯坐标文本也能导入', () {
      final archived = GameArchive.decode('H8 I9 J10');
      expect(archived, isNotNull);
      expect(archived!.moves.length, 3);
      expect(archived.moves.first, centerIndex);
      expect(archived.title, '导入棋谱');
    });

    test('带序号与中文冒号的棋谱可解析', () {
      final archived = GameArchive.decode('标题: 测试对局\n着法：\n1. H8 2. I9\n3. J10');
      expect(archived, isNotNull);
      expect(archived!.title, '测试对局');
      expect(archived.moves.length, 3);
    });

    test('重复落子或空文本解析失败', () {
      expect(GameArchive.decode(''), isNull);
      expect(GameArchive.decode('   '), isNull);
      expect(GameArchive.decode('H8 H8'), isNull);
      expect(GameArchive.decode('没有坐标'), isNull);
    });
  });

  group('棋谱存档', () {
    test('JSON 往返保留着法与结果', () {
      final board = _playedBoard();
      final saved = SavedGame(
        id: 'game_1',
        title: '双人对弈',
        endedAt: DateTime(2026, 11, 4, 20),
        moves: board.history,
        result: '黑方胜（五连）',
      );
      final restored = SavedGame.fromJson(saved.toJson());
      expect(restored, isNotNull);
      expect(restored!.title, '双人对弈');
      expect(restored.moveCount, 5);
      expect(restored.result, '黑方胜（五连）');
      expect(
        [for (final move in restored.moves) move.index],
        [for (final move in board.history) move.index],
      );
    });

    test('缺少字段或非法着法返回 null', () {
      expect(SavedGame.fromJson({'id': 'x'}), isNull);
      expect(
        SavedGame.fromJson({
          'id': 'x',
          'moves': [centerIndex, centerIndex],
        }),
        isNull,
      );
      expect(
        SavedGame.fromJson({
          'id': 'x',
          'moves': ['H8'],
        }),
        isNull,
      );
    });

    test('从导入棋谱生成存档', () {
      final archived = GameArchive.decode('H8 I9 J10')!;
      final saved = SavedGame.fromArchive(archived);
      expect(saved.id, startsWith('import_'));
      expect(saved.moveCount, 3);
      expect(saved.title, '导入棋谱');
      expect(saved.toArchiveText(), contains('着法：'));
    });
  });
}
