import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/handicap.dart';
import 'package:gomoku/game/logic_rate.dart';
import 'package:gomoku/models/game_models.dart';
import 'package:gomoku/pages/settings_page.dart';

import 'support/helpers.dart';

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('设置页展示对局、外观、音效与日志分区', (tester) async {
    _useTallView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const SettingsPage(), settings));

    expect(find.text('对局'), findsOneWidget);
    expect(find.text('外观与棋盘'), findsOneWidget);
    expect(find.text('音效与反馈'), findsOneWidget);
    expect(find.text('运行日志'), findsOneWidget);
    expect(find.text('深色模式'), findsOneWidget);
    expect(find.text('显示坐标'), findsOneWidget);
  });

  testWidgets('难度、先后手与棋钟选择写入偏好', (tester) async {
    _useTallView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const SettingsPage(), settings));

    await tester.tap(find.text('入门'));
    await tester.pumpAndSettle();
    expect(settings.difficulty, Difficulty.entry);

    await tester.tap(find.text('执白后行'));
    await tester.pumpAndSettle();
    expect(settings.humanSide, white);

    await tester.tap(find.text('让二子'));
    await tester.pumpAndSettle();
    expect(settings.handicap, Handicap.two);

    await tester.tap(find.text('10 分钟'));
    await tester.pumpAndSettle();
    expect(settings.timeControl, TimeControl.rapid);
  });

  testWidgets('逻辑更新速率可切换并写入偏好，默认 60Hz', (tester) async {
    _useTallView(tester);
    final settings = await createSettings();
    expect(settings.logicRate, LogicRate.hz60);
    await tester.pumpWidget(wrapPage(const SettingsPage(), settings));

    await tester.scrollUntilVisible(
      find.text('120 Hz 顺滑'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('120 Hz 顺滑'));
    await tester.pumpAndSettle();
    expect(settings.logicRate, LogicRate.hz120);

    await tester.tap(find.text('30 Hz 省电'));
    await tester.pumpAndSettle();
    expect(settings.logicRate, LogicRate.hz30);
  });

  testWidgets('开关写入偏好', (tester) async {
    _useTallView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const SettingsPage(), settings));

    await tester.tap(find.byKey(const ValueKey('switch-dark')));
    await tester.pumpAndSettle();
    expect(settings.darkMode, isTrue);

    await tester.tap(find.byKey(const ValueKey('switch-coords')));
    await tester.pumpAndSettle();
    expect(settings.showCoordinates, isFalse);

    await tester.tap(find.byKey(const ValueKey('switch-sound')));
    await tester.pumpAndSettle();
    expect(settings.soundEnabled, isFalse);

    await tester.tap(find.byKey(const ValueKey('switch-opening')));
    await tester.pumpAndSettle();
    expect(settings.openingHints, isFalse);

    await tester.tap(find.byKey(const ValueKey('switch-forbidden')));
    await tester.pumpAndSettle();
    expect(settings.forbiddenRule, isTrue);

    await tester.tap(find.byKey(const ValueKey('switch-position')));
    await tester.pumpAndSettle();
    expect(settings.showPosition, isFalse);
  });

  testWidgets('查看日志弹窗可打开', (tester) async {
    _useTallView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const SettingsPage(), settings));

    await tester.tap(find.text('查看日志'));
    await tester.pumpAndSettle();
    expect(find.text('最近日志'), findsOneWidget);
  });
}
