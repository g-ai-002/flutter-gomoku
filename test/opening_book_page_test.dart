import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/opening_book.dart';
import 'package:gomoku/pages/game_page.dart';
import 'package:gomoku/pages/opening_book_page.dart';

import 'support/helpers.dart';

void _useDesktopView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('开局库展示六条开局与练习入口', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const OpeningBookPage(), settings));
    await tester.pump();

    expect(find.text('开局库'), findsOneWidget);
    expect(find.text('前六手参考'), findsOneWidget);
    for (final line in kOpeningLines) {
      expect(find.text(line.name), findsOneWidget);
    }
    expect(find.text('练习此开局'), findsNWidgets(kOpeningLines.length));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('练习开局进入人机对战并显示开局名', (tester) async {
    _useDesktopView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const OpeningBookPage(), settings));
    await tester.pump();

    await tester.tap(find.text('练习此开局').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.byType(GamePage), findsOneWidget);
    expect(
      find.textContaining('开局练习 · ${kOpeningLines.first.name}'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('窄屏开局库无溢出', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const OpeningBookPage(), settings));
    await tester.pump();

    expect(find.text('直指·斜连'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
