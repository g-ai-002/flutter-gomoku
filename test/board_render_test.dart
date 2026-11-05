import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/flame/board_component.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/game_controller.dart';
import 'package:gomoku/models/game_models.dart';

const double _size = 480;

Future<ByteData> _renderComponent(BoardComponent component) async {
  final recorder = ui.PictureRecorder();
  component.render(ui.Canvas(recorder));
  final image = await recorder.endRecording().toImage(
    _size.toInt(),
    _size.toInt(),
  );
  final data = await image.toByteData();
  image.dispose();
  return data!;
}

Future<ByteData> _renderBoard(GameController controller) async {
  final component = BoardComponent(view: controller)
    ..size = Vector2(_size, _size);
  return _renderComponent(component);
}

({int r, int g, int b}) _pixel(ByteData data, double x, double y) {
  final offset = (y.round() * _size.toInt() + x.round()) * 4;
  return (
    r: data.getUint8(offset),
    g: data.getUint8(offset + 1),
    b: data.getUint8(offset + 2),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('棋盘渲染出深色黑棋与暖色棋盘', (tester) async {
    await tester.runAsync(() async {
      final controller = GameController(
        mode: GameMode.twoPlayers,
        difficulty: Difficulty.entry,
        humanSide: black,
      );
      addTearDown(controller.dispose);
      controller.start();
      controller.tapCell(centerIndex);
      final pixels = await _renderBoard(controller);

      // 坐标模式下格宽为 480 / 16.4，天元在画面中心；
      // 中心点是白棋形状的最后一手圆点，取偏右的棋面采样。
      const cell = _size / 16.4;
      final center = _pixel(pixels, _size / 2 + cell * 0.3, _size / 2);
      expect(center.r, lessThan(90));
      expect(center.g, lessThan(90));
      expect(center.b, lessThan(90));

      // 天元左侧的空交叉点应保持木色。
      final wood = _pixel(pixels, _size / 2 - cell, _size / 2);
      expect(wood.r, greaterThan(180));
      expect(wood.g, greaterThan(150));
      expect(wood.b, greaterThan(100));
    });
  });

  testWidgets('白棋棋面比黑棋明亮', (tester) async {
    await tester.runAsync(() async {
      final controller = GameController(
        mode: GameMode.twoPlayers,
        difficulty: Difficulty.entry,
        humanSide: black,
      );
      addTearDown(controller.dispose);
      controller.start();
      controller.tapCell(centerIndex);
      controller.tapCell(indexOf(7, 8));
      final pixels = await _renderBoard(controller);

      const cell = _size / 16.4;
      final blackStone = _pixel(pixels, _size / 2 + cell * 0.3, _size / 2);
      final whiteStone = _pixel(
        pixels,
        _size / 2 + cell + cell * 0.3,
        _size / 2,
      );
      expect(whiteStone.r, greaterThan(blackStone.r + 60));
      expect(whiteStone.g, greaterThan(blackStone.g + 60));
    });
  });

  testWidgets('卸载棋盘后释放图层并可重新绘制', (tester) async {
    await tester.runAsync(() async {
      final controller = GameController(
        mode: GameMode.twoPlayers,
        difficulty: Difficulty.entry,
        humanSide: black,
      );
      addTearDown(controller.dispose);
      controller.start();
      controller.tapCell(centerIndex);
      final component = BoardComponent(view: controller)
        ..size = Vector2(_size, _size);

      final first = await _renderComponent(component);
      component.disposeResources();
      component.disposeResources();
      final second = await _renderComponent(component);

      expect(second.lengthInBytes, first.lengthInBytes);
    });
  });
}
