import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/models/game_models.dart';
import 'package:gomoku/pages/settings_page.dart';
import 'package:gomoku/theme/board_skin.dart';

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
    expect(find.text('关于'), findsOneWidget);
    expect(find.text('原木'), findsOneWidget);
    expect(find.text('青玉'), findsOneWidget);
    expect(find.text('墨韵'), findsOneWidget);
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

    await tester.tap(find.text('10 分钟'));
    await tester.pumpAndSettle();
    expect(settings.timeControl, TimeControl.rapid);
  });

  testWidgets('皮肤选择即时生效', (tester) async {
    _useTallView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const SettingsPage(), settings));

    await tester.tap(find.text('青玉'));
    await tester.pumpAndSettle();
    expect(settings.boardSkin.id, jadeSkin.id);
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
