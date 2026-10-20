import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gomoku/models/game_state.dart';
import 'package:flutter_gomoku/providers/game_provider.dart';
import 'package:flutter_gomoku/services/storage_service.dart';
import 'package:flutter_gomoku/utils/constants.dart';
import 'package:flutter_gomoku/widgets/board_widget.dart';

// 换算必须与 BoardWidget/BoardPainter 的布局一致：交叉点 i 位于 padding + i * cellSize
const double viewSize = 300;
const int testBoardSize = AppConstants.defaultBoardSize;
const int testLast = testBoardSize - 1;
const double testCellSize = (viewSize - AppConstants.boardPadding) / testBoardSize;
const double testPadding = (viewSize - testCellSize * (testBoardSize - 1)) / 2;

Offset intersection(int row, int col) =>
    Offset(testPadding + col * testCellSize, testPadding + row * testCellSize);

void main() {
  late StorageService storage;
  late GameProvider provider;
  late Widget board;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService.reset();
    storage = await StorageService.instance;
    await storage.setBoardSize(testBoardSize);
    await storage.setGameMode(GameMode.pvp);
    await storage.setSoundEnabled(false);
    provider = GameProvider(storage);
    board = ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: MaterialApp(
        home: const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: viewSize,
            height: viewSize,
            child: BoardWidget(),
          ),
        ),
      ),
    );
  });

  testWidgets('点击交叉点正中落在该交叉点', (tester) async {
    await tester.pumpWidget(board);
    await tester.tapAt(intersection(3, 3));
    await tester.pumpAndSettle();
    expect(provider.board[3][3], equals(StoneColor.black));
    expect(provider.lastMove, equals(const Position(3, 3)));
  });

  testWidgets('点击边角交叉点也能落子', (tester) async {
    await tester.pumpWidget(board);
    await tester.tapAt(intersection(testLast, testLast));
    await tester.pumpAndSettle();
    expect(provider.board[testLast][testLast], equals(StoneColor.black));
    expect(provider.lastMove, equals(const Position(testLast, testLast)));
  });

  testWidgets('点击偏离交叉点时吸附到最近交叉点', (tester) async {
    await tester.pumpWidget(board);
    final target =
        intersection(7, 7) + const Offset(0.4 * testCellSize, -0.4 * testCellSize);
    await tester.tapAt(target);
    await tester.pumpAndSettle();
    expect(provider.board[7][7], equals(StoneColor.black));
    expect(provider.board[7][8], isNull);
    expect(provider.lastMove, equals(const Position(7, 7)));
  });
}
