import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/pages/widgets/board_page_scaffold.dart';

void main() {
  test('正方形网格在竖屏窄屏上保持竖屏', () {
    expect(prefersLandscapeGrid(const Size(390, 844)), isFalse);
    expect(prefersLandscapeGrid(const Size(360, 640)), isFalse);
  });

  test('横屏窗口的棋盘边长更大时才进入沉浸横屏', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(shouldEnterImmersiveLandscape(const Size(844, 390)), isTrue);
    expect(shouldEnterImmersiveLandscape(const Size(390, 844)), isFalse);
    // 平板与桌面不旋转，保持系统默认方向。
    expect(shouldEnterImmersiveLandscape(const Size(1024, 768)), isFalse);
  });

  test('非 Android 平台不改变屏幕方向', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(shouldEnterImmersiveLandscape(const Size(844, 390)), isFalse);
  });

  testWidgets('显示模式包装直接透传页面内容', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BoardDisplayMode(child: Text('棋盘页'))),
    );

    expect(find.text('棋盘页'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
