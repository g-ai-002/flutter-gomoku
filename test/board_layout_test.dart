import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/flame/gomoku_game.dart';
import 'package:gomoku/models/game_models.dart';
import 'package:gomoku/pages/game_page.dart';
import 'package:gomoku/pages/widgets/board_actions.dart';
import 'package:gomoku/pages/widgets/move_panel.dart';
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

  testWidgets('横屏手机改用窄竖栏，棋盘接近满高且不与竖栏重叠', (tester) async {
    await _pumpGameAt(tester, const Size(844, 390));

    final board = _board(tester);
    expect(board.height, greaterThanOrEqualTo(330));
    final panel = tester.getRect(find.byType(MovePanel));
    expect(panel.width, 200);
    expect(panel.left, greaterThan(board.right));
    expect(tester.getRect(find.text('悔棋')).left, greaterThan(board.right));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('横屏小窗口 640×360 的棋盘不再被悬浮信息压缩', (tester) async {
    await _pumpGameAt(tester, const Size(640, 360));

    final board = _board(tester);
    // 0.9.1 在此尺寸只给棋盘 216，竖栏布局应恢复到 300 以上。
    expect(board.height, greaterThanOrEqualTo(300));
    expect(tester.getRect(find.byType(MovePanel)).width, 200);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('竖屏手机状态贴棋盘上沿、操作贴下沿，富余高度常驻棋谱', (tester) async {
    await _pumpGameAt(tester, const Size(390, 844));

    final board = _board(tester);
    final status = tester.getRect(find.byType(BoardStatusBar));
    final actions = tester.getRect(find.byType(BoardActions));
    final panel = tester.getRect(find.byType(MovePanel));

    // 棋盘吃满宽度，信息不再漂到页面上下边缘。
    expect(board.width, 366);
    expect(status.bottom, lessThanOrEqualTo(board.top));
    expect(board.top - status.bottom, lessThan(20));
    expect(actions.top - board.bottom, lessThan(20));
    expect(panel.top, greaterThan(board.bottom));
    expect(panel.width, board.width);
    expect(panel.bottom, 844);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('小屏手机保留常驻棋谱且不溢出', (tester) async {
    await _pumpGameAt(tester, const Size(360, 640));

    final board = _board(tester);
    final panel = tester.getRect(find.byType(MovePanel));
    expect(board.width, 336);
    expect(panel.width, board.width);
    expect(panel.height, greaterThanOrEqualTo(108));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('竖屏平板棋盘优先，不为棋谱让出高度', (tester) async {
    await _pumpGameAt(tester, const Size(768, 1024));

    final board = _board(tester);
    expect(board.height, greaterThanOrEqualTo(730));
    expect(find.byType(MovePanel), findsNothing);
    // 棋谱改由操作区按钮弹出。
    expect(find.text('棋谱'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('近方形窗口改走竖栏，棋盘明显大于悬浮预留方案', (tester) async {
    await _pumpGameAt(tester, const Size(700, 500));

    final board = _board(tester);
    // 0.9.1 在此尺寸只给棋盘 356，竖栏布局应超过 440。
    expect(board.height, greaterThanOrEqualTo(440));
    expect(tester.getRect(find.byType(MovePanel)).left, greaterThan(board.right));
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

  testWidgets('放大字体时棋盘与状态条不溢出', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpGameAt(tester, const Size(360, 640));
    expect(_board(tester).width, 336);
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
