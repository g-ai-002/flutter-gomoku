import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/custom_puzzles.dart';
import 'package:gomoku/game/puzzle_share_code.dart';
import 'package:gomoku/pages/puzzle_library_page.dart';

import 'support/helpers.dart';

CustomPuzzle _puzzle() => CustomPuzzle(
  id: 'custom_share',
  title: '斜月三杀',
  moveLimit: 4,
  blackStones: const [100, 101, 102],
  whiteStones: const [90, 91],
  createdAt: DateTime(2026, 11, 5),
);

void _useDesktopView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _settleFrames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpLibrary(WidgetTester tester) async {
  _useDesktopView(tester);
  final settings = await createSettings();
  final puzzle = _puzzle();
  await CustomPuzzleService.instance.save(
    id: puzzle.id,
    title: puzzle.title,
    moveLimit: puzzle.moveLimit,
    blackStones: puzzle.blackStones,
    whiteStones: puzzle.whiteStones,
  );
  await tester.pumpWidget(wrapPage(const PuzzleLibraryPage(), settings));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('我的残局'), 300);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('分享按钮展示可复制的分享码', (tester) async {
    await _pumpLibrary(tester);

    await tester.tap(find.byTooltip('分享码'));
    await tester.pumpAndSettle();

    expect(find.text('分享「斜月三杀」'), findsOneWidget);
    final code = tester
        .widget<SelectableText>(find.byType(SelectableText).last)
        .data;
    expect(code, startsWith('${PuzzleShareCode.prefix}~'));
    expect(PuzzleShareCode.decode(code!)!.title, '斜月三杀');

    await tester.tap(find.text('复制分享码'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('分享码已复制到剪贴板'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('粘贴分享码可导入到我的残局', (tester) async {
    await _pumpLibrary(tester);
    final code = PuzzleShareCode.encode(
      CustomPuzzle(
        id: 'other',
        title: '好友残局',
        moveLimit: 2,
        blackStones: const [80, 81],
        whiteStones: const [70],
        createdAt: DateTime(2026, 11, 5),
      ),
    );

    await tester.tap(find.byTooltip('导入分享码'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('导入'));
    await _settleFrames(tester);

    expect(find.text('已导入「好友残局」'), findsOneWidget);
    expect(
      CustomPuzzleService.instance.puzzles.any(
        (puzzle) => puzzle.title == '好友残局' && puzzle.moveLimit == 2,
      ),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('非法分享码在弹窗内提示错误', (tester) async {
    await _pumpLibrary(tester);

    await tester.tap(find.byTooltip('导入分享码'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'GMK1-not-a-code');
    await tester.tap(find.text('导入'));
    await tester.pump();

    expect(find.text('分享码无效或已损坏'), findsOneWidget);
    expect(find.text('导入分享码'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
