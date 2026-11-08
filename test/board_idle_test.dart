import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart' show PointerHoverEvent, TapDownDetails;
import 'package:flutter/material.dart' hide PointerMoveEvent;
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/flame/board_component.dart';
import 'package:gomoku/flame/gomoku_game.dart';
import 'package:gomoku/game/board_view.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/game_controller.dart';
import 'package:gomoku/game/logic_rate.dart';
import 'package:gomoku/models/game_models.dart';
import 'package:gomoku/models/move_record.dart';
import 'package:gomoku/services/sound_service.dart';

/// 棋盘组件的可控视图：测试直接改动棋谱、提示与禁手点。
class _FakeView implements BoardView {
  final Uint8List _cells = emptyCells();
  final List<MoveRecord> _history = [];
  int? hint;
  bool interactable = true;

  @override
  Uint8List get cells => _cells;

  @override
  List<MoveRecord> get history => _history;

  @override
  int? get lastIndex => _history.isEmpty ? null : _history.last.index;

  @override
  List<int> get winningLine => const [];

  @override
  int? get hintIndex => hint;

  @override
  bool get showCoordinates => true;

  @override
  bool get canInteract => interactable;

  @override
  int get sideToMove => black;

  @override
  Set<int> get forbiddenPoints => const {};

  @override
  int get revision => 0;

  @override
  bool get allowsReplace => false;

  @override
  void tapCell(int index) {}

  void addMove(int index) {
    _cells[index] = _history.length.isEven ? black : white;
    _history.add(
      MoveRecord(
        index: index,
        side: _cells[index],
        notation: 'H8',
        moveNumber: _history.length + 1,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('棋盘空闲暂停', () {
    test('静止半秒后触发空闲回调', () {
      final view = _FakeView();
      var idle = 0;
      final board = BoardComponent(view: view, onIdle: () => idle++);

      board.update(0.3);
      expect(idle, 0);
      board.update(0.25);
      expect(idle, 1);
    });

    test('提示点存在时持续绘制，不进入空闲', () {
      final view = _FakeView()..hint = centerIndex;
      var idle = 0;
      final board = BoardComponent(view: view, onIdle: () => idle++);

      for (var i = 0; i < 10; i++) {
        board.update(0.2);
      }
      expect(idle, 0);
    });

    test('落子动画结束后重新计时', () {
      final view = _FakeView();
      var idle = 0;
      final board = BoardComponent(view: view, onIdle: () => idle++);

      view.addMove(centerIndex);
      board.update(0.1);
      for (var i = 0; i < 4; i++) {
        board.update(0.1);
      }
      expect(idle, 0, reason: '动画播放中不应暂停');
      board.update(0.3);
      board.update(0.3);
      expect(idle, 1);
    });
  });

  group('棋盘唤醒', () {
    test('空闲暂停后局面变化会唤醒渲染', () {
      final controller = GameController(
        mode: GameMode.twoPlayers,
        difficulty: Difficulty.entry,
        humanSide: black,
      );
      addTearDown(controller.dispose);
      final game = GomokuGame(view: controller, repaint: controller);

      game.pauseForIdle();
      expect(game.paused, isTrue);

      controller.tapCell(centerIndex);
      expect(controller.history.length, 1);
      expect(game.paused, isFalse);
    });

    test('外部暂停不会被局面变化覆盖', () {
      final controller = GameController(
        mode: GameMode.twoPlayers,
        difficulty: Difficulty.entry,
        humanSide: black,
      );
      addTearDown(controller.dispose);
      final game = GomokuGame(view: controller, repaint: controller);

      game.pauseEngine();
      controller.tapCell(centerIndex);
      expect(game.paused, isTrue);
    });

    test('空闲暂停后窗口尺寸变化会唤醒重绘', () {
      final controller = GameController(
        mode: GameMode.twoPlayers,
        difficulty: Difficulty.entry,
        humanSide: black,
      );
      addTearDown(controller.dispose);
      final game = GomokuGame(view: controller, repaint: controller);

      game.pauseForIdle();
      expect(game.paused, isTrue);
      game.onGameResize(Vector2(800, 600));
      expect(game.paused, isFalse);
    });

    test('重复空闲暂停只记录一次', () {
      final controller = GameController(
        mode: GameMode.twoPlayers,
        difficulty: Difficulty.entry,
        humanSide: black,
      );
      addTearDown(controller.dispose);
      final game = GomokuGame(view: controller, repaint: controller);

      game.pauseForIdle();
      game.pauseForIdle();
      expect(game.paused, isTrue);

      controller.tapCell(centerIndex);
      expect(game.paused, isFalse);
    });
  });

  test('空闲视图不请求逐帧绘制', () {
    final board = BoardComponent(view: _FakeView());
    expect(board.needsFrames, isFalse);
  });

  test('悬停与离开会唤醒棋盘并触发重绘', () {
    final view = _FakeView();
    var wakes = 0;
    final game = GomokuGame(view: view);
    final board = BoardComponent(view: view, onWake: () => wakes++);
    board.size = Vector2(480, 480);
    board.render(Canvas(PictureRecorder()));

    // 棋盘中部的交叉点：悬停后立即重绘一次预览棋子。
    final move = PointerMoveEvent(
      1,
      game,
      const PointerHoverEvent(
        position: Offset(240, 240),
        kind: PointerDeviceKind.mouse,
      ),
    )..renderingTrace.add(Vector2(240, 240));
    board.onPointerMove(move);
    expect(wakes, 1);
    expect(board.needsFrames, isFalse, reason: '悬停预览静止，无需逐帧重绘');

    board.onPointerMoveStop(move);
    expect(wakes, 2);
    expect(board.needsFrames, isFalse);
  });

  test('悬停不阻止棋盘在静止半秒后进入空闲', () {
    final view = _FakeView();
    var idle = 0;
    final board = BoardComponent(view: view, onIdle: () => idle++);
    board.size = Vector2(480, 480);
    board.render(Canvas(PictureRecorder()));
    final game = GomokuGame(view: view);
    final move = PointerMoveEvent(
      1,
      game,
      const PointerHoverEvent(
        position: Offset(240, 240),
        kind: PointerDeviceKind.mouse,
      ),
    )..renderingTrace.add(Vector2(240, 240));

    board.onPointerMove(move);
    board.update(0.3);
    expect(idle, 0);
    board.update(0.25);
    expect(idle, 1);
  });

  test('暂停后点击棋盘仍然落子并唤醒', () {
    final controller = GameController(
      mode: GameMode.twoPlayers,
      difficulty: Difficulty.entry,
      humanSide: black,
    );
    addTearDown(controller.dispose);
    final game = GomokuGame(view: controller, repaint: controller);
    final board = BoardComponent(
      view: controller,
      onIdle: game.pauseForIdle,
      onWake: game.wake,
    );
    game.pauseForIdle();
    expect(game.paused, isTrue);
    SoundService.hapticsEnabled = false;
    addTearDown(() => SoundService.hapticsEnabled = true);

    board.size = Vector2(480, 480);
    board.render(Canvas(PictureRecorder()));
    final tap = TapDownEvent(
      1,
      game,
      TapDownDetails(
        globalPosition: const Offset(240, 240),
        localPosition: const Offset(240, 240),
      ),
    )..renderingTrace.add(Vector2(240, 240));
    board.onTapDown(tap);
    expect(controller.history.length, 1);
    expect(game.paused, isFalse);
  });

  testWidgets('暂停状态下真实悬停事件仍能唤醒棋盘', (tester) async {
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = GameController(
      mode: GameMode.twoPlayers,
      difficulty: Difficulty.entry,
      humanSide: black,
    );
    final game = GomokuGame(view: controller, repaint: controller);
    await tester.pumpWidget(
      MaterialApp(home: GameWidget<GomokuGame>(game: game)),
    );
    await tester.pump();

    final center = tester.getCenter(find.byType(GameWidget<GomokuGame>));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: center);
    addTearDown(mouse.removePointer);
    await tester.pump();

    game.pauseForIdle();
    expect(game.paused, isTrue);
    await mouse.moveTo(center);
    await tester.pump();
    expect(game.paused, isFalse, reason: '悬停应唤醒已暂停的棋盘');

    await tester.pumpWidget(const SizedBox.shrink());
    game.onDispose();
    controller.dispose();
  });

  group('逻辑刷新率', () {
    test('30Hz 下落子动画按固定步长推进并按时结束', () {
      final view = _FakeView();
      final board = BoardComponent(view: view, logicRate: LogicRate.hz30);

      view.addMove(centerIndex);
      board.update(1 / 30);
      expect(board.needsFrames, isTrue);

      for (var i = 0; i < 8; i++) {
        board.update(1 / 30);
      }
      expect(board.needsFrames, isFalse, reason: '0.26 秒动画应在 9 步内结束');
    });

    test('页面关闭后停止渲染循环并解绑局面监听', () {
      final controller = GameController(
        mode: GameMode.twoPlayers,
        difficulty: Difficulty.entry,
        humanSide: black,
      );
      final game = GomokuGame(view: controller, repaint: controller);

      game.pauseForIdle();
      expect(game.paused, isTrue);
      game.stop();
      expect(game.paused, isTrue);

      controller.tapCell(centerIndex);
      expect(controller.history.length, 1);
      expect(game.paused, isTrue, reason: '停止后不应再被局面变化唤醒');

      game.stop();
      controller.dispose();
    });
  });
}
