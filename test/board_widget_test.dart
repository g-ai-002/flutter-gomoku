import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gomoku/game/gomoku_board_geometry.dart';
import 'package:flutter_gomoku/models/game_state.dart';
import 'package:flutter_gomoku/providers/game_provider.dart';
import 'package:flutter_gomoku/services/storage_service.dart';
import 'package:flutter_gomoku/utils/constants.dart';
import 'package:flutter_gomoku/widgets/board_widget.dart';

// 棋盘世界分辨率为 600×600，测试视图为 300×300，点击坐标 = 世界坐标 × 0.5；
// 换算口径与 GomokuBoardGeometry 一致：交叉点 i 位于 padding + i * cellSize。
const double viewSize = 300;
const int testBoardSize = AppConstants.defaultBoardSize;
const int testLast = testBoardSize - 1;
final GomokuBoardGeometry geometry =
    GomokuBoardGeometry.forBoard(testBoardSize);
const double viewScale = viewSize / GomokuBoardGeometry.worldSize;

Offset intersection(int row, int col) =>
    geometry.centerOf(row, col) * viewScale;

/// Flame 的 Ticker 会持续请求帧，`pumpAndSettle` 无法收敛，改用固定帧推进。
Future<void> pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

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
      child: const MaterialApp(
        home: Align(
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
    await pumpFrames(tester);
    await tester.tapAt(intersection(3, 3));
    await pumpFrames(tester);
    expect(provider.board[3][3], equals(StoneColor.black));
    expect(provider.lastMove, equals(const Position(3, 3)));
  });

  testWidgets('点击边角交叉点也能落子', (tester) async {
    await tester.pumpWidget(board);
    await pumpFrames(tester);
    await tester.tapAt(intersection(testLast, testLast));
    await pumpFrames(tester);
    expect(provider.board[testLast][testLast], equals(StoneColor.black));
    expect(provider.lastMove, equals(const Position(testLast, testLast)));
  });

  testWidgets('点击偏离交叉点时吸附到最近交叉点', (tester) async {
    await tester.pumpWidget(board);
    await pumpFrames(tester);
    final target = intersection(7, 7) +
        Offset(0.4 * geometry.cellSize * viewScale,
            -0.4 * geometry.cellSize * viewScale);
    await tester.tapAt(target);
    await pumpFrames(tester);
    expect(provider.board[7][7], equals(StoneColor.black));
    expect(provider.board[7][8], isNull);
    expect(provider.lastMove, equals(const Position(7, 7)));
  });
}
