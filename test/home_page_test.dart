import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/pages/home_page.dart';
import 'package:gomoku/pages/settings_page.dart';
import 'package:gomoku/utils/constants.dart';

import 'support/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('首页展示品牌与五个入口', (tester) async {
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const HomePage(), settings));

    expect(find.text('五子棋'), findsWidgets);
    expect(find.text('人机对战'), findsOneWidget);
    expect(find.text('双人对弈'), findsOneWidget);
    expect(find.text('AI 对演'), findsOneWidget);
    expect(find.text('双方 AI 自动对弈 · 观战学习'), findsOneWidget);
    expect(find.text('残局挑战'), findsOneWidget);
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

  testWidgets('横屏手机沿用居中滚动布局，入口不分栏', (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const HomePage(), settings));

    final hero = tester.getTopLeft(find.text('黑白之间，方寸之上见胜负'));
    final ai = tester.getTopLeft(find.text('人机对战'));
    final duel = tester.getTopLeft(find.text('双人对弈'));
    // 品牌区在上、入口在下，两列排布，与竖屏保持同一套布局。
    expect(ai.dy, greaterThan(hero.dy));
    expect(duel.dy, closeTo(ai.dy, 0.5));
    expect(ai.dx, lessThan(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面宽屏同样居中排布，不切换分栏列表', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const HomePage(), settings));

    final ai = tester.getTopLeft(find.text('人机对战'));
    final duel = tester.getTopLeft(find.text('双人对弈'));
    expect(duel.dy, closeTo(ai.dy, 0.5));
    expect(find.byType(ListView), findsNothing);
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

  testWidgets('开启让子后人机入口展示让子与白方先行', (tester) async {
    final settings = await createSettings(values: {'handicap': 'two'});
    await tester.pumpWidget(wrapPage(const HomePage(), settings));

    expect(find.text('让二子 · 白方先行'), findsOneWidget);
  });

  testWidgets('棋谱复盘入口打开棋谱库', (tester) async {
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const HomePage(), settings));

    await tester.ensureVisible(find.text('棋谱复盘'));
    await tester.tap(find.text('棋谱复盘'));
    await tester.pumpAndSettle();
    expect(find.text('还没有棋谱'), findsOneWidget);
  });

  testWidgets('残局挑战入口可打开', (tester) async {
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const HomePage(), settings));

    await tester.tap(find.text('残局挑战'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('十道杀法'), findsOneWidget);
  });
}
