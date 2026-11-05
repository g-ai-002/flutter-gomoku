import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/custom_puzzles.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/puzzle_editor_controller.dart';
import 'package:gomoku/services/puzzle_progress_service.dart';
import 'package:gomoku/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

CustomPuzzle _puzzle({String id = 'custom_1', String title = '双三杀'}) =>
    CustomPuzzle(
      id: id,
      title: title,
      moveLimit: 3,
      blackStones: const [100, 101, 102],
      whiteStones: const [90, 91],
      createdAt: DateTime(2026, 11, 5),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CustomPuzzleService.instance.resetForTest();
    PuzzleProgressService.instance.resetForTest();
  });

  group('自定义残局数据', () {
    test('JSON 往返保留局面', () {
      final puzzle = _puzzle();
      final restored = CustomPuzzle.fromJson(puzzle.toJson());
      expect(restored, isNotNull);
      expect(restored!.title, puzzle.title);
      expect(restored.moveLimit, 3);
      expect(restored.blackStones, puzzle.blackStones);
      expect(restored.whiteStones, puzzle.whiteStones);
      expect(restored.createdAt, puzzle.createdAt);
    });

    test('非法字段或黑白重叠被拒绝', () {
      final json = _puzzle().toJson();
      expect(CustomPuzzle.fromJson({...json, 'moveLimit': 0}), isNull);
      expect(CustomPuzzle.fromJson({...json, 'title': ' '}), isNull);
      expect(CustomPuzzle.fromJson({...json, 'black': []}), isNull);
      expect(
        CustomPuzzle.fromJson({
          ...json,
          'black': [100, 100],
        }),
        isNull,
      );
      expect(
        CustomPuzzle.fromJson({
          ...json,
          'white': [100],
        }),
        isNull,
      );
      expect(
        CustomPuzzle.fromJson({
          ...json,
          'black': [cellCount],
        }),
        isNull,
      );
    });

    test('转为挑战残局后标记为自定义', () {
      final puzzle = _puzzle().toPuzzle();
      expect(puzzle.isCustom, isTrue);
      expect(puzzle.label, '自定义');
      expect(puzzle.goal, '自定残局');
      expect(puzzle.blackStones.length, 3);
    });
  });

  group('自定义残局库', () {
    test('保存、编辑与删除', () async {
      final service = CustomPuzzleService.instance;
      final saved = await service.save(
        title: '双三杀',
        moveLimit: 3,
        blackStones: const [100, 101, 102],
        whiteStones: const [90, 91],
      );
      expect(service.puzzles.length, 1);

      final edited = await service.save(
        id: saved.id,
        title: '双三杀·改',
        moveLimit: 5,
        blackStones: const [100, 101, 102],
        whiteStones: const [90, 91],
      );
      expect(edited.id, saved.id);
      expect(service.puzzles.length, 1);
      expect(service.puzzles.first.title, '双三杀·改');

      await service.remove(saved.id);
      expect(service.puzzles, isEmpty);
    });

    test('重新加载后保留，最多三十关', () async {
      final service = CustomPuzzleService.instance;
      for (var i = 0; i < 35; i++) {
        await service.save(
          title: '残局 $i',
          moveLimit: 3,
          blackStones: const [100],
          whiteStones: const [90],
        );
      }
      expect(service.puzzles.length, CustomPuzzle.maxCount);
      expect(service.puzzles.first.title, '残局 34');

      service.resetForTest();
      expect(service.puzzles, isEmpty);
      await service.load();
      expect(service.puzzles.length, CustomPuzzle.maxCount);
      expect(service.puzzles.first.title, '残局 34');
    });

    test('损坏的持久化数据被忽略', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefKeyCustomPuzzles: '[{"id":1},{"id":"x"}]',
      });
      final service = CustomPuzzleService.instance;
      await service.load();
      expect(service.puzzles, isEmpty);
    });
  });

  group('残局编辑器', () {
    test('落子、移除与画笔切换', () {
      final controller = PuzzleEditorController();
      controller.tapCell(centerIndex);
      expect(controller.blackCount, 1);
      expect(controller.history.length, 1);

      controller.setBrush(white);
      controller.tapCell(centerIndex + 1);
      expect(controller.whiteCount, 1);

      controller.tapCell(centerIndex);
      expect(controller.blackCount, 0);
      expect(controller.history.length, 1);
      expect(controller.revision, 3);

      controller.clear();
      expect(controller.blackCount + controller.whiteCount, 0);
      controller.dispose();
    });

    test('校验至少一枚黑棋且不能已有五连', () {
      final controller = PuzzleEditorController();
      expect(controller.invalidReason, '请至少摆放一枚黑棋');

      for (var col = 3; col < 8; col++) {
        controller.tapCell(indexOf(7, col));
      }
      expect(controller.invalidReason, '局面中已经有五连，请调整棋子');

      controller.tapCell(indexOf(7, 3));
      expect(controller.invalidReason, isNull);
      controller.dispose();
    });

    test('校验结果缓存随落子、移除与清空刷新', () {
      final controller = PuzzleEditorController();
      for (var col = 3; col < 8; col++) {
        controller.tapCell(indexOf(7, col));
      }
      expect(controller.invalidReason, '局面中已经有五连，请调整棋子');

      controller.tapCell(indexOf(7, 7));
      expect(controller.invalidReason, isNull);

      controller.tapCell(indexOf(7, 7));
      expect(controller.invalidReason, '局面中已经有五连，请调整棋子');

      controller.clear();
      expect(controller.blackCount, 0);
      expect(controller.whiteCount, 0);
      expect(controller.invalidReason, '请至少摆放一枚黑棋');
      controller.dispose();
    });

    test('编辑已有残局并限制手数', () {
      final controller = PuzzleEditorController(initial: _puzzle());
      expect(controller.blackCount, 3);
      expect(controller.whiteCount, 2);
      expect(controller.moveLimit, 3);

      controller.setMoveLimit(99);
      expect(controller.moveLimit, CustomPuzzle.maxMoveLimit);
      controller.setMoveLimit(0);
      expect(controller.moveLimit, 1);
      controller.dispose();
    });
  });
}
