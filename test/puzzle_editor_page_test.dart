import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/custom_puzzles.dart';
import 'package:gomoku/pages/puzzle_editor_page.dart';
import 'package:gomoku/pages/puzzle_library_page.dart';
import 'package:gomoku/services/puzzle_progress_service.dart';

import 'support/helpers.dart';

CustomPuzzle _customPuzzle() => CustomPuzzle(
  id: 'custom_test',
  title: '双三杀',
  moveLimit: 3,
  blackStones: const [100, 101, 102],
  whiteStones: const [90, 91],
  createdAt: DateTime(2026, 11, 5),
);

Future<void> _seed(CustomPuzzle puzzle) async {
  await CustomPuzzleService.instance.save(
    id: puzzle.id,
    title: puzzle.title,
    moveLimit: puzzle.moveLimit,
    blackStones: puzzle.blackStones,
    whiteStones: puzzle.whiteStones,
  );
}

void _useDesktopView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('残局列表展示我的残局与新建入口', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await _seed(_customPuzzle());
    await tester.pumpWidget(wrapPage(const PuzzleLibraryPage(), settings));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('我的残局'), 300);
    await tester.pumpAndSettle();

    expect(find.text('我的残局'), findsOneWidget);
    expect(find.text('双三杀'), findsOneWidget);
    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('新建'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('编辑器展示摆子控制与校验提示', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const PuzzleEditorPage(), settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('新建残局'), findsOneWidget);
    expect(find.text('黑子'), findsOneWidget);
    expect(find.text('白子'), findsOneWidget);
    expect(find.text('限 3 手内成五'), findsOneWidget);
    expect(find.text('黑 0 · 白 0'), findsOneWidget);

    await tester.tap(find.byTooltip('保存并挑战'));
    await tester.pump();
    expect(find.widgetWithText(SnackBar, '请至少摆放一枚黑棋'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('编辑已有残局展示棋子与删除入口', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(
      wrapPage(PuzzleEditorPage(initial: _customPuzzle()), settings),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('编辑残局'), findsOneWidget);
    expect(find.text('黑 3 · 白 2'), findsOneWidget);
    expect(find.byTooltip('删除残局'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('手机窄屏编辑器无溢出', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const PuzzleEditorPage(), settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('新建残局'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('残局名称为空时提示且不保存', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(
      wrapPage(PuzzleEditorPage(initial: _customPuzzle()), settings),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    await tester.tap(find.byTooltip('保存并挑战'));
    await tester.pump();
    expect(find.text('残局名称'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '');
    await tester.tap(find.text('保存并挑战'));
    await tester.pump();

    expect(find.widgetWithText(SnackBar, '请输入残局名称'), findsOneWidget);
    expect(CustomPuzzleService.instance.puzzles, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  tearDown(() {
    PuzzleProgressService.instance.resetForTest();
  });
}
