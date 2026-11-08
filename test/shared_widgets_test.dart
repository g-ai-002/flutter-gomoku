import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/pages/widgets/board_hint_overlay.dart';
import 'package:gomoku/pages/widgets/play_layout.dart';
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
            StatusChip(accent: appAccent, active: false, child: Text('五连')),
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

  testWidgets('状态条统一高度并排列行棋方、状态与右侧信息', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 420,
          child: BoardStatusBar(
            accent: appInk,
            leading: Text('黑方行棋'),
            status: Text('AI 思考中…'),
            trailing: Text('第 1 手 H8'),
          ),
        ),
      ),
    );

    expect(find.text('黑方行棋'), findsOneWidget);
    expect(find.text('AI 思考中…'), findsOneWidget);
    expect(find.text('第 1 手 H8'), findsOneWidget);
    expect(tester.getSize(find.byType(BoardStatusBar)).height, 30);
    expect(tester.takeException(), isNull);
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

  testWidgets('棋盘浮层展示开局名与禁手图例，空提示不占布局', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            children: [
              Positioned.fill(
                child: BoardHintOverlay(
                  opening: '直指·斜连',
                  showForbiddenLegend: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('开局 · 直指·斜连'), findsOneWidget);
    expect(find.text('红圈为黑棋禁手点'), findsOneWidget);
    // 提示悬浮在棋盘上方：左侧开局与禁手图例，右侧形势判断。
    final overlay = tester.getRect(find.byType(BoardHintOverlay));
    final opening = tester.getRect(find.text('开局 · 直指·斜连'));
    final legend = tester.getRect(find.text('红圈为黑棋禁手点'));
    expect(opening.top, lessThan(overlay.center.dy));
    expect(legend.top, lessThan(overlay.center.dy));
    expect(legend.left, lessThan(overlay.center.dx));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _host(const SizedBox(width: 240, height: 240, child: BoardHintOverlay())),
    );
    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('棋盘布局把状态放上方、操作放下方并随通知重建', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ValueNotifier(0);
    var actionBuilds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayLayout(
            controller: controller,
            status: (_) => Text('状态 ${controller.value}'),
            board: const Center(
              child: SizedBox(key: ValueKey('board'), width: 300, height: 300),
            ),
            actions: (_) {
              actionBuilds++;
              return const Text('操作区');
            },
          ),
        ),
      ),
    );

    expect(find.text('状态 0'), findsOneWidget);
    expect(find.text('操作区'), findsOneWidget);
    expect(actionBuilds, 1);
    final board = tester.getRect(find.byKey(const ValueKey('board')));
    expect(
      tester.getRect(find.text('状态 0')).bottom,
      lessThanOrEqualTo(board.top),
    );
    expect(
      tester.getRect(find.text('操作区')).top,
      greaterThanOrEqualTo(board.bottom),
    );
    expect(board.center.dx, closeTo(600, 1));

    controller.value = 1;
    await tester.pump();
    expect(find.text('状态 1'), findsOneWidget);
    expect(actionBuilds, 2);
    controller.dispose();
  });

  testWidgets('窄屏棋盘布局仍把操作按钮放在棋盘下方', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ValueNotifier(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayLayout(
            controller: controller,
            status: (_) => const Text('状态'),
            board: const Center(
              child: SizedBox(key: ValueKey('board'), width: 300, height: 300),
            ),
            actions: (_) => const Text('操作区'),
          ),
        ),
      ),
    );

    final board = tester.getRect(find.byKey(const ValueKey('board')));
    expect(
      tester.getRect(find.text('操作区')).top,
      greaterThanOrEqualTo(board.bottom),
    );
    expect(board.center.dx, closeTo(210, 1));
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
