import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/flame/gomoku_game.dart';
import 'package:gomoku/models/game_models.dart';
import 'package:gomoku/pages/game_page.dart';
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

  testWidgets('宽屏棋盘独占左列并吃满可用高度', (tester) async {
    await _pumpGameAt(tester, const Size(1280, 900));

    final board = _board(tester);
    expect(board.width, board.height);
    expect(board.height, greaterThanOrEqualTo(800));
    // 棋谱栏仍在右侧，状态与操作区不再挤占棋盘所在列。
    expect(find.text('棋谱'), findsOneWidget);
    expect(tester.getRect(find.text('黑方行棋').first).left, greaterThan(board.right));
    expect(tester.getRect(find.text('悔棋')).left, greaterThan(board.right));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('横屏棋盘吃满高度，操作区移到右侧竖栏', (tester) async {
    await _pumpGameAt(tester, const Size(844, 390));

    final board = _board(tester);
    expect(board.height, greaterThanOrEqualTo(330));
    final undo = tester.getRect(find.text('悔棋'));
    expect(undo.left, greaterThan(board.right));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('近方形窗口为悬浮信息预留空间，操作区不压住棋盘', (tester) async {
    await _pumpGameAt(tester, const Size(700, 500));

    final board = _board(tester);
    final undo = tester.getRect(find.text('悔棋'));
    expect(undo.top, greaterThan(board.bottom));
    expect(tester.getRect(find.text('黑方行棋').first).bottom,
        lessThan(board.top));
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

  testWidgets('窄栏内的状态条改为纵向堆叠且不溢出', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: BoardStatusBar(
                accent: Colors.black,
                leading: Text('黑方行棋'),
                status: Text('点击交叉点落子'),
                trailing: Text('第 1 手 H8'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('黑方行棋'), findsOneWidget);
    expect(tester.getSize(find.byType(BoardStatusBar)).height, greaterThan(30));
    expect(tester.takeException(), isNull);
  });
}
