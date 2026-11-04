import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/board_state.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/models/saved_game.dart';
import 'package:gomoku/pages/game_history_page.dart';
import 'package:gomoku/pages/review_page.dart';
import 'package:gomoku/services/game_history_service.dart';

import 'support/helpers.dart';

SavedGame _savedGame() {
  final board = GomokuBoard();
  for (final index in [centerIndex, indexOf(7, 8), indexOf(8, 8)]) {
    board.apply(index);
  }
  return SavedGame(
    id: 'game_seed',
    title: '双人对弈',
    endedAt: DateTime(2026, 11, 4, 20, 30),
    moves: board.history,
    result: '进行中',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('棋谱库空状态可导入', (tester) async {
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const GameHistoryPage(), settings));
    await tester.pump();

    expect(find.text('还没有棋谱'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '导入棋谱'), findsOneWidget);
  });

  testWidgets('棋谱库列出最近对局并可进入复盘', (tester) async {
    final settings = await createSettings();
    await GameHistoryService.instance.record(_savedGame());
    await tester.pumpWidget(wrapPage(const GameHistoryPage(), settings));
    await tester.pump();

    expect(find.text('双人对弈'), findsOneWidget);
    expect(find.textContaining('3 手'), findsOneWidget);

    await tester.tap(find.text('双人对弈'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ReviewPage), findsOneWidget);
    expect(find.text('第 0 / 3 手'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('粘贴坐标棋谱可导入并复盘', (tester) async {
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const GameHistoryPage(), settings));
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, '导入棋谱'));
    await tester.pumpAndSettle();
    expect(find.text('导入棋谱'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'H8 I9 J10');
    await tester.tap(find.text('开始复盘'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ReviewPage), findsOneWidget);
    expect(find.text('第 0 / 3 手'), findsOneWidget);
    expect(GameHistoryService.instance.records.first.moveCount, 3);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('非法棋谱给出提示', (tester) async {
    final settings = await createSettings();
    await tester.pumpWidget(wrapPage(const GameHistoryPage(), settings));
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, '导入棋谱'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'H8 H8');
    await tester.tap(find.text('开始复盘'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('棋谱无法解析'), findsOneWidget);
  });
}
