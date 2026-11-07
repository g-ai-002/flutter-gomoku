import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/flame/gomoku_game.dart';
import 'package:gomoku/models/game_models.dart';
import 'package:gomoku/pages/game_page.dart';
import 'package:gomoku/utils/constants.dart';

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

  testWidgets('落子后棋盘浮层展示实时胜率', (tester) async {
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
    expect(find.textContaining('%'), findsNothing);

    final board = find.byType(GameWidget<GomokuGame>);
    await tester.tapAt(tester.getCenter(board));
    await _pumpGame(tester);

    expect(find.text('形势 · 黑 50% · 白 50%'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('关闭形势判断后不显示胜率浮层', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings(
      values: {AppConstants.prefKeyShowPosition: false},
    );
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

    expect(find.textContaining('%'), findsNothing);
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
