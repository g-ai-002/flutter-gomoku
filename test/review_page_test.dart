import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/board_state.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/pages/review_page.dart';

import 'support/helpers.dart';

GomokuBoard _finishedBoard() {
  final board = GomokuBoard();
  for (final index in [
    indexOf(7, 3),
    indexOf(0, 0),
    indexOf(7, 4),
    indexOf(0, 1),
    indexOf(7, 5),
    indexOf(0, 2),
    indexOf(7, 6),
    indexOf(0, 3),
    indexOf(7, 7),
  ]) {
    board.apply(index);
  }
  return board;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('复盘页从开局起步并可逐步前进', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = await createSettings();
    final board = _finishedBoard();
    await tester.pumpWidget(
      wrapPage(
        ReviewPage(
          title: '双人对弈',
          result: '黑方胜（五连）',
          moves: board.history,
          date: DateTime(2026, 11, 4, 20),
        ),
        settings,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('第 0 / 9 手'), findsOneWidget);
    // 棋谱改由操作区的按钮弹出，不再常驻侧栏。
    expect(find.byTooltip('棋谱'), findsOneWidget);

    await tester.tap(find.byTooltip('下一步'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('第 1 / 9 手'), findsOneWidget);

    await tester.tap(find.byTooltip('跳到终局'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('第 9 / 9 手'), findsOneWidget);

    await tester.tap(find.byTooltip('回到开局'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('第 0 / 9 手'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('自动回放可以开始与暂停', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = await createSettings();
    final board = _finishedBoard();
    await tester.pumpWidget(
      wrapPage(ReviewPage(title: '复盘', moves: board.history), settings),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byTooltip('自动回放'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('第 1 / 9 手'), findsOneWidget);

    await tester.tap(find.byTooltip('暂停回放'));
    await tester.pump();
    expect(find.byTooltip('自动回放'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
