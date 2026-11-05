import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/flame/gomoku_game.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/opening_book.dart';
import 'package:gomoku/models/game_models.dart';
import 'package:gomoku/pages/game_page.dart';

import 'support/helpers.dart';

Future<void> _pumpGame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 320));
}

void _useDesktopView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('双人对弈页展示状态与操作', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(
      wrapPage(
        const GamePage(
          mode: GameMode.twoPlayers,
          difficulty: Difficulty.expert,
          humanSide: 1,
        ),
        settings,
      ),
    );
    await _pumpGame(tester);

    expect(find.text('双人对弈'), findsOneWidget);
    expect(find.text('黑方行棋'), findsOneWidget);
    expect(find.text('悔棋'), findsOneWidget);
    expect(find.text('重开'), findsOneWidget);
    expect(find.byType(GameWidget<GomokuGame>), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('点击棋盘中心落子并更新棋谱', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(
      wrapPage(
        const GamePage(
          mode: GameMode.twoPlayers,
          difficulty: Difficulty.expert,
          humanSide: 1,
        ),
        settings,
      ),
    );
    await _pumpGame(tester);

    final board = find.byType(GameWidget<GomokuGame>);
    await tester.tapAt(tester.getCenter(board));
    await _pumpGame(tester);

    expect(find.textContaining('第 1 手 H8'), findsOneWidget);
    expect(find.text('白方行棋'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('悔棋与重开按钮可用', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(
      wrapPage(
        const GamePage(
          mode: GameMode.twoPlayers,
          difficulty: Difficulty.expert,
          humanSide: 1,
        ),
        settings,
      ),
    );
    await _pumpGame(tester);

    final board = find.byType(GameWidget<GomokuGame>);
    await tester.tapAt(tester.getCenter(board));
    await _pumpGame(tester);
    expect(find.textContaining('第 1 手'), findsOneWidget);

    await tester.tap(find.text('悔棋'));
    await _pumpGame(tester);
    expect(find.textContaining('第 1 手'), findsNothing);
    expect(find.text('黑方行棋'), findsOneWidget);

    await tester.tapAt(tester.getCenter(board));
    await _pumpGame(tester);
    await tester.tap(find.text('重开'));
    await _pumpGame(tester);
    expect(find.textContaining('第 1 手'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('开启禁手规则后对局标题标注禁手', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings(values: {'forbidden_rule': true});
    await tester.pumpWidget(
      wrapPage(
        const GamePage(
          mode: GameMode.twoPlayers,
          difficulty: Difficulty.expert,
          humanSide: 1,
        ),
        settings,
      ),
    );
    await _pumpGame(tester);

    expect(settings.forbiddenRule, isTrue);
    expect(find.textContaining('同屏对弈 · 禁手'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('开局名以浮层展示且不改变棋盘尺寸', (tester) async {
    // 高度受限的窗口：状态区多出一行就会挤压棋盘，便于暴露布局移位。
    tester.view.physicalSize = const Size(1280, 620);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = await createSettings();
    final line = kOpeningLines.first;
    await tester.pumpWidget(
      wrapPage(
        GamePage(
          mode: GameMode.vsAi,
          difficulty: Difficulty.expert,
          humanSide: black,
          opening: line,
        ),
        settings,
      ),
    );
    await _pumpGame(tester);

    final board = find.byType(GameWidget<GomokuGame>);
    final before = tester.getRect(board);
    final cell = before.width / 16.4;
    Offset center(int row, int col) => before.topLeft + Offset(
      before.width / 2 + (col - 7) * cell,
      before.height / 2 + (row - 7) * cell,
    );

    // 前两手仍不足以定型开局；第三手落子后浮层出现，棋盘尺寸必须保持不变。
    await tester.tapAt(center(7, 7));
    await _pumpGame(tester);
    expect(find.textContaining('开局 · '), findsNothing);

    await tester.tapAt(center(6, 6));
    await _pumpGame(tester);
    expect(find.textContaining('开局 · ${line.name}'), findsOneWidget);
    expect(tester.getRect(board), before);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('手机窄屏对局页无溢出且显示棋谱入口', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = await createSettings();
    await tester.pumpWidget(
      wrapPage(
        const GamePage(
          mode: GameMode.twoPlayers,
          difficulty: Difficulty.expert,
          humanSide: 1,
        ),
        settings,
      ),
    );
    await _pumpGame(tester);

    expect(find.text('棋谱'), findsOneWidget);
    expect(find.text('黑方行棋'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('人机对战展示提示与执子信息', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(
      wrapPage(
        const GamePage(
          mode: GameMode.vsAi,
          difficulty: Difficulty.entry,
          humanSide: 1,
        ),
        settings,
      ),
    );
    await _pumpGame(tester);

    expect(find.text('你执黑'), findsOneWidget);
    expect(find.text('提示'), findsOneWidget);
    expect(find.text('认输'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('认输需要二次确认并弹出结果', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(
      wrapPage(
        const GamePage(
          mode: GameMode.vsAi,
          difficulty: Difficulty.entry,
          humanSide: 1,
        ),
        settings,
      ),
    );
    await _pumpGame(tester);

    await tester.tap(find.text('认输'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('确认认输并结束本局吗？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '认输'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('白方胜'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
