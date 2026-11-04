import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/pages/widgets/board_play_layout.dart';
import 'package:gomoku/pages/widgets/choice_pill.dart';
import 'package:gomoku/pages/widgets/entry_tile.dart';
import 'package:gomoku/pages/widgets/highlight_panel.dart';
import 'package:gomoku/pages/widgets/page_list.dart';
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

  testWidgets('限宽列表居中且不超过最大宽度', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PageList(maxWidth: 600, children: [Text('列表内容')])),
      ),
    );

    expect(find.text('列表内容'), findsOneWidget);
    expect(tester.getSize(find.byType(ListView)).width, 600);
  });

  testWidgets('提示卡展示内容并使用统一圆角', (tester) async {
    await tester.pumpWidget(_host(const HighlightPanel(child: Text('提示内容'))));

    expect(find.text('提示内容'), findsOneWidget);
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(HighlightPanel),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(14));
  });

  testWidgets('宽屏棋盘布局只构建宽屏操作区并随通知重建', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ValueNotifier(0);
    var wideBuilds = 0;
    var compactBuilds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardPlayLayout(
            controller: controller,
            status: (_) => Text('状态 ${controller.value}'),
            board: const SizedBox.expand(),
            actions: (_, showMoves) {
              if (showMoves) {
                compactBuilds++;
              } else {
                wideBuilds++;
              }
              return Text(showMoves ? '窄屏操作' : '宽屏操作');
            },
            sidePanel: (_) => const Text('棋谱栏'),
          ),
        ),
      ),
    );

    expect(find.text('状态 0'), findsOneWidget);
    expect(find.text('宽屏操作'), findsOneWidget);
    expect(find.text('窄屏操作'), findsNothing);
    expect(find.text('棋谱栏'), findsOneWidget);
    expect(wideBuilds, 1);
    expect(compactBuilds, 0);

    controller.value = 1;
    await tester.pump();
    expect(find.text('状态 1'), findsOneWidget);
    expect(wideBuilds, 2);
    controller.dispose();
  });

  testWidgets('窄屏棋盘布局使用紧凑操作区', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ValueNotifier(0);
    var wideBuilds = 0;
    var compactBuilds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardPlayLayout(
            controller: controller,
            status: (_) => const Text('状态'),
            board: const SizedBox.expand(),
            actions: (_, showMoves) {
              if (showMoves) {
                compactBuilds++;
              } else {
                wideBuilds++;
              }
              return Text(showMoves ? '窄屏操作' : '宽屏操作');
            },
            sidePanel: (_) => const Text('棋谱栏'),
          ),
        ),
      ),
    );

    expect(find.text('窄屏操作'), findsOneWidget);
    expect(find.text('宽屏操作'), findsNothing);
    expect(wideBuilds, 0);
    expect(compactBuilds, 1);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
