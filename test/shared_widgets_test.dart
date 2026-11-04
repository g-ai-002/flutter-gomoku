import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/pages/widgets/choice_pill.dart';
import 'package:gomoku/pages/widgets/entry_tile.dart';
import 'package:gomoku/pages/widgets/section_card.dart';
import 'package:gomoku/pages/widgets/status_chip.dart';
import 'package:gomoku/theme/app_theme.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildLightTheme(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('入口卡片展示标题、副标题并响应点击', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 360,
          child: EntryTile(
            leading: const EntryBadge(
              icon: Icons.smart_toy_outlined,
              accent: appInk,
            ),
            title: '人机对战',
            subtitle: '三档难度',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('人机对战'), findsOneWidget);
    expect(find.text('三档难度'), findsOneWidget);
    await tester.tap(find.text('人机对战'));
    expect(tapped, isTrue);
  });

  testWidgets('状态胶囊与分区卡片正常渲染', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusChip(accent: appInk, child: Text('黑方行棋')),
            SizedBox(height: 8),
            StatusChip(accent: appAccent, filled: true, child: Text('五连')),
            SizedBox(height: 8),
            SizedBox(
              width: 320,
              child: SectionCard(
                title: '对局',
                icon: Icons.tune_rounded,
                children: [Text('内容')],
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.text('黑方行棋'), findsOneWidget);
    expect(find.text('五连'), findsOneWidget);
    expect(find.text('对局'), findsOneWidget);
    expect(find.text('内容'), findsOneWidget);
  });

  testWidgets('胶囊选项点击回调', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(
        ChoicePill(
          label: '入门',
          selected: false,
          accent: appInk,
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('入门'), findsOneWidget);
    await tester.tap(find.text('入门'));
    expect(tapped, isTrue);
  });
}
