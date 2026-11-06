import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/handicap.dart';
import 'package:gomoku/models/game_models.dart';
import 'package:gomoku/pages/settings_page.dart';
import 'package:gomoku/utils/constants.dart';

import 'support/helpers.dart';

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('设置页展示对局、精研、外观、音效与日志分区', (tester) async {
    _useTallView(tester);
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const SettingsPage(), settings));

    expect(find.text('对局'), findsOneWidget);
    expect(find.text('AI 精研'), findsOneWidget);
    expect(find.text('开始训练'), findsOneWidget);
    expect(find.text('尚未训练，开局库使用内置棋谱'), findsOneWidget);
    expect(find.text('外观与棋盘'), findsOneWidget);
    expect(find.text('音效与反馈'), findsOneWidget);
    expect(find.text('运行日志'), findsOneWidget);
    expect(find.text('深色模式'), findsOneWidget);
    expect(find.text('显示坐标'), findsOneWidget);
  });

  testWidgets('已有精研开局时展示数量并可清除', (tester) async {
    _useTallView(tester);
    final settings = await createSettings(
      values: {
        AppConstants.prefKeyLearnedBook:
            'direct-diagonal|直指·斜连·精研|2|112.128.97.143.113.142.127.129',
      },
    );
    await tester.pumpWidget(wrapPage(const SettingsPage(), settings));

    expect(find.text('已精研 1 条开局 · 2 胜'), findsOneWidget);
    await tester.tap(find.text('清除精研开局'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清除'));
    await tester.pumpAndSettle();

    expect(find.text('尚未训练，开局库使用内置棋谱'), findsOneWidget);
    expect(settings.learnedBook.isEmpty, isTrue);
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
