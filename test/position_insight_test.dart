import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/engine/search.dart';
import 'package:gomoku/game/game_controller.dart';
import 'package:gomoku/game/notation.dart';
import 'package:gomoku/game/position_insight.dart';
import 'package:gomoku/models/game_models.dart';

Uint8List _board(Map<String, int> stones) {
  final cells = emptyCells();
  stones.forEach((point, side) => cells[MoveNotation.parse(point)!] = side);
  return cells;
}

PositionInsight _insight(Map<String, int> stones) =>
    PositionInsight.of(_board(stones));

void main() {
  test('空盘双方各占一半', () {
    final insight = PositionInsight.of(emptyCells());
    expect(insight.blackPercent, 50);
    expect(insight.whitePercent, 50);
    expect(insight.label, '均势');
  });

  test('五连局面直接给出满胜率', () {
    final blackWin = _insight({
      'H8': black,
      'I8': black,
      'J8': black,
      'K8': black,
      'L8': black,
    });
    expect(blackWin.blackPercent, 100);
    expect(blackWin.whitePercent, 0);

    final whiteWin = _insight({
      'H8': white,
      'I8': white,
      'J8': white,
      'K8': white,
      'L8': white,
    });
    expect(whiteWin.blackPercent, 0);
    expect(whiteWin.whitePercent, 100);
  });

  test('活三优势显著且黑白镜像互补', () {
    final blackRate = _insight({
      'H8': black,
      'I8': black,
      'J8': black,
    }).blackRate;
    final whiteRate = _insight({
      'H8': white,
      'I8': white,
      'J8': white,
    }).blackRate;

    expect(blackRate, greaterThan(0.8));
    expect(whiteRate, lessThan(0.2));
    expect(blackRate + whiteRate, closeTo(1, 1e-9));
    expect(
      _insight({'H8': black, 'I8': black, 'J8': black}).label,
      '黑优',
    );
  });

  test('未分胜负时胜率收敛在保守区间', () {
    final insight = _insight({'H8': black});
    expect(insight.blackRate, greaterThan(0.5));
    expect(insight.blackRate, lessThan(0.98));
    expect(insight.blackPercent + insight.whitePercent, 100);
  });

  test('对局控制器按手数缓存形势判断', () {
    final controller = GameController(
      mode: GameMode.twoPlayers,
      difficulty: Difficulty.normal,
      humanSide: black,
      aiMove: (cells, side, difficulty, {bool? forbidBlack}) async =>
          const SearchResult(move: 0, score: 0, depth: 1, nodes: 1),
    );
    addTearDown(controller.dispose);
    controller.start();

    final empty = controller.positionInsight;
    expect(empty.blackPercent, 50);
    expect(controller.positionInsight, same(empty));

    controller.tapCell(indexOf(7, 7));
    final afterMove = controller.positionInsight;
    expect(afterMove, isNot(same(empty)));
    expect(afterMove.blackRate, greaterThan(0.5));
    expect(controller.positionInsight, same(afterMove));
  });
}
