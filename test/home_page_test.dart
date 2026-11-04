import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/pages/home_page.dart';
import 'package:gomoku/pages/settings_page.dart';
import 'package:gomoku/utils/constants.dart';

import 'support/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('首页展示品牌与三个入口', (tester) async {
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const HomePage(), settings));

    expect(find.text('五子棋'), findsWidgets);
    expect(find.text('人机对战'), findsOneWidget);
    expect(find.text('双人对弈'), findsOneWidget);
    expect(find.text('棋谱复盘'), findsOneWidget);
    expect(find.textContaining('v${AppConstants.version}'), findsOneWidget);
  });

  testWidgets('折叠屏展开宽度下入口排成两列', (tester) async {
    tester.view.physicalSize = const Size(673, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const HomePage(), settings));

    final ai = tester.getTopLeft(find.text('人机对战'));
    final duel = tester.getTopLeft(find.text('双人对弈'));
    final archive = tester.getTopLeft(find.text('棋谱复盘'));

    expect(duel.dy, closeTo(ai.dy, 0.5));
    expect(duel.dx, greaterThan(ai.dx));
    expect(archive.dy, greaterThan(ai.dy));
  });

  testWidgets('窄屏下入口保持单列', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const HomePage(), settings));

    final ai = tester.getTopLeft(find.text('人机对战'));
    final duel = tester.getTopLeft(find.text('双人对弈'));
    expect(duel.dy, greaterThan(ai.dy));
  });

  testWidgets('手机窄屏首页无溢出', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const HomePage(), settings));
    expect(find.text('五子棋'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('深色模式按钮切换偏好', (tester) async {
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const HomePage(), settings));
    expect(settings.darkMode, isFalse);

    await tester.tap(find.byTooltip('切换深色'));
    await tester.pump();
    expect(settings.darkMode, isTrue);

    await tester.tap(find.byTooltip('切换浅色'));
    await tester.pump();
    expect(settings.darkMode, isFalse);
  });

  testWidgets('设置按钮打开设置页', (tester) async {
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const HomePage(), settings));

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('棋谱复盘入口打开棋谱库', (tester) async {
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const HomePage(), settings));

    await tester.tap(find.text('棋谱复盘'));
    await tester.pumpAndSettle();
    expect(find.text('还没有棋谱'), findsOneWidget);
  });
}
