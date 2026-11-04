import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/flame/gomoku_game.dart';
import 'package:gomoku/game/puzzles.dart';
import 'package:gomoku/pages/puzzle_library_page.dart';
import 'package:gomoku/pages/puzzle_page.dart';

import 'support/helpers.dart';

void _useDesktopView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('残局页展示目标、状态与操作', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    final puzzle = kGomokuPuzzles.first;
    await tester.pumpWidget(wrapPage(PuzzlePage(puzzle: puzzle), settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('残局挑战'), findsOneWidget);
    expect(find.textContaining(puzzle.title), findsWidgets);
    expect(find.text('轮到你落子'), findsOneWidget);
    expect(find.text('悔棋'), findsOneWidget);
    expect(find.text('重开'), findsOneWidget);
    expect(find.text('提示'), findsOneWidget);
    expect(find.byType(GameWidget<GomokuGame>), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('手机窄屏残局页无溢出', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = await createSettings();
    await tester.pumpWidget(
      wrapPage(PuzzlePage(puzzle: kGomokuPuzzles[4]), settings),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('棋谱'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('残局列表展示进度与分组关卡', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const PuzzleLibraryPage(), settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('十道杀法'), findsOneWidget);
    expect(find.text('已通关 0/10'), findsOneWidget);
    expect(find.text('横贯长空'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('双三·交叉'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('双三·交叉'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('残局列表点击关卡进入挑战', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const PuzzleLibraryPage(), settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('横贯长空'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byType(PuzzlePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
