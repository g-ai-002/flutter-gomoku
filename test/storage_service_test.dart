import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/board_state.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/models/game_models.dart';
import 'package:gomoku/models/saved_game.dart';
import 'package:gomoku/services/game_history_service.dart';
import 'package:gomoku/services/storage_service.dart';
import 'package:gomoku/theme/board_skin.dart';
import 'package:shared_preferences/shared_preferences.dart';

SavedGame _savedGame(String id, {int minutes = 0}) {
  final board = GomokuBoard()..apply(centerIndex);
  return SavedGame(
    id: id,
    title: id,
    endedAt: DateTime(2026).add(Duration(minutes: minutes)),
    moves: board.history,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetForTests();
    GameHistoryService.instance.resetForTest();
  });

  group('偏好存储', () {
    test('未设置时使用默认值', () async {
      final storage = await StorageService.instance;
      expect(storage.darkMode, isFalse);
      expect(storage.showCoordinates, isTrue);
      expect(storage.difficulty, Difficulty.expert);
      expect(storage.humanSide, black);
      expect(storage.timeControl, TimeControl.none);
      expect(storage.soundEnabled, isTrue);
      expect(storage.musicEnabled, isTrue);
      expect(storage.hapticsEnabled, isTrue);
      expect(storage.boardSkinId, isNull);
    });

    test('写入后可以读回', () async {
      final storage = await StorageService.instance;
      await storage.setDarkMode(true);
      await storage.setShowCoordinates(false);
      await storage.setDifficulty(Difficulty.entry);
      await storage.setHumanSide(white);
      await storage.setTimeControl(TimeControl.rapid);
      await storage.setSoundEnabled(false);
      await storage.setMusicEnabled(false);
      await storage.setHapticsEnabled(false);
      await storage.setBoardSkinId(jadeSkin.id);

      expect(storage.darkMode, isTrue);
      expect(storage.showCoordinates, isFalse);
      expect(storage.difficulty, Difficulty.entry);
      expect(storage.humanSide, white);
      expect(storage.timeControl, TimeControl.rapid);
      expect(storage.soundEnabled, isFalse);
      expect(storage.musicEnabled, isFalse);
      expect(storage.hapticsEnabled, isFalse);
      expect(storage.boardSkinId, jadeSkin.id);
    });

    test('未知枚举值与皮肤回退到默认', () async {
      SharedPreferences.setMockInitialValues({
        'difficulty': 'unknown',
        'time_control': 'unknown',
        'human_side': 9,
        'board_skin': 'unknown',
      });
      StorageService.resetForTests();
      final storage = await StorageService.instance;
      expect(storage.difficulty, Difficulty.expert);
      expect(storage.timeControl, TimeControl.none);
      expect(storage.humanSide, 9);
      expect(boardSkinOf(storage.boardSkinId).id, kDefaultBoardSkin.id);
    });
  });

  group('棋谱库', () {
    test('写入、覆盖与上限', () async {
      final service = GameHistoryService.instance;
      for (var i = 0; i < 25; i++) {
        await service.record(_savedGame('game_$i', minutes: i));
      }
      expect(service.records.length, GameHistoryService.maxRecords);
      expect(service.records.first.id, 'game_24');

      await service.record(_savedGame('game_24', minutes: 24));
      expect(service.records.length, GameHistoryService.maxRecords);

      await service.load();
      expect(service.records.first.id, 'game_24');

      await service.remove('game_24');
      expect(service.records.any((game) => game.id == 'game_24'), isFalse);

      await service.clear();
      expect(service.isEmpty, isTrue);
    });
  });
}
