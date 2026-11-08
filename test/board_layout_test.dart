import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/flame/gomoku_game.dart';
import 'package:gomoku/models/game_models.dart';
import 'package:gomoku/pages/game_page.dart';
import 'package:gomoku/pages/widgets/board_actions.dart';
import 'package:gomoku/pages/widgets/move_list.dart';
import 'package:gomoku/pages/widgets/status_chip.dart';

import 'support/helpers.dart';

Future<void> _pumpGame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 320));
}

Future<void> _pumpGameAt(
  WidgetTester tester,
  Size size, {
  Map<String, Object> values = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final settings = await createSettings(values: values);
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
}

Rect _board(WidgetTester tester) =>
    tester.getRect(find.byType(GameWidget<GomokuGame>));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('宽屏棋盘居中，状态在上方、操作在下方', (tester) async {
    await _pumpGameAt(tester, const Size(1280, 900));

    final board = _board(tester);
    final status = tester.getRect(find.byType(BoardStatusBar));
    final actions = tester.getRect(find.byType(BoardActions));

    expect(board.width, board.height);
    expect(board.center.dx, closeTo(640, 1));
    expect(status.bottom, lessThanOrEqualTo(board.top));
    expect(actions.top, greaterThanOrEqualTo(board.bottom));
    // 棋谱不再常驻侧栏，改由底部操作区的按钮弹出。
    expect(find.byType(MoveList), findsNothing);
    expect(find.text('棋谱'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('竖屏手机棋盘吃满宽度并保持居中', (tester) async {
    await _pumpGameAt(tester, const Size(390, 844));

    final board = _board(tester);
    final status = tester.getRect(find.byType(BoardStatusBar));
    final actions = tester.getRect(find.byType(BoardActions));

    expect(board.width, 366);
    expect(board.center.dx, closeTo(195, 1));
    // 棋盘居中，状态在上方、操作在下方，彼此不重叠。
    expect(status.bottom, lessThanOrEqualTo(board.top));
    expect(actions.top, greaterThanOrEqualTo(board.bottom));
    expect(
      board.center.dy,
      closeTo(status.bottom + (actions.top - status.bottom) / 2, 1),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('横屏手机棋盘按高度取满且不溢出', (tester) async {
    await _pumpGameAt(tester, const Size(844, 390));

    final board = _board(tester);
    expect(board.width, board.height);
    expect(board.height, greaterThanOrEqualTo(200));
    expect(board.center.dx, closeTo(422, 1));
    expect(
      tester.getRect(find.byType(BoardActions)).top,
      greaterThanOrEqualTo(board.bottom),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('小屏手机无溢出且操作按钮完整可见', (tester) async {
    await _pumpGameAt(tester, const Size(360, 640));

    final board = _board(tester);
    expect(board.width, 336);
    expect(find.text('悔棋'), findsOneWidget);
    expect(find.text('重开'), findsOneWidget);
    expect(find.text('棋谱'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('提示浮层出现后棋盘尺寸与状态条位置不变', (tester) async {
    await _pumpGameAt(tester, const Size(390, 844));

    final before = _board(tester);
    final statusBefore = tester.getRect(find.byType(BoardStatusBar));
    await tester.tapAt(before.center);
    await _pumpGame(tester);

    expect(find.text('形势 · 黑 50% · 白 50%'), findsOneWidget);
    expect(_board(tester), before);
    expect(tester.getRect(find.byType(BoardStatusBar)), statusBefore);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('胜率提示悬浮在棋盘右上角', (tester) async {
    await _pumpGameAt(tester, const Size(390, 844));

    final board = _board(tester);
    await tester.tapAt(board.center);
    await _pumpGame(tester);

    final insight = tester.getRect(find.textContaining('形势 · 黑'));
    expect(insight.center.dx, greaterThan(board.center.dx));
    expect(insight.top, lessThan(board.center.dy));
    expect(board.contains(insight.center), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('棋谱按钮弹出底部棋谱面板', (tester) async {
    await _pumpGameAt(tester, const Size(390, 844));
    await tester.tapAt(_board(tester).center);
    await _pumpGame(tester);

    await tester.tap(find.text('棋谱'));
    await tester.pumpAndSettle();
    expect(find.byType(MoveList), findsOneWidget);
    expect(find.text('尚未落子'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('放大字体时棋盘与状态条不溢出', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpGameAt(tester, const Size(360, 640));
    expect(_board(tester).width, 336);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
