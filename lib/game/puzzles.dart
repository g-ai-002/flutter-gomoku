import 'dart:typed_data';

import 'engine/board_utils.dart';
import 'notation.dart';

/// 残局难度分组：一步成五、两步杀与三步杀。
enum PuzzleTier {
  starter('入门', '一步成五'),
  advanced('进阶', '两步杀'),
  expert('挑战', '三步杀');

  const PuzzleTier(this.label, this.goal);

  final String label;
  final String goal;
}

/// 一道残局：固定局面、黑先，玩家须在 [moveLimit] 手内连成五子。
class GomokuPuzzle {
  const GomokuPuzzle({
    required this.id,
    required this.title,
    required this.tier,
    required this.moveLimit,
    required this.blackStones,
    required this.whiteStones,
    required this.tip,
  });

  final String id;
  final String title;
  final PuzzleTier tier;

  /// 玩家（黑棋）可用的手数。
  final int moveLimit;
  final List<int> blackStones;
  final List<int> whiteStones;
  final String tip;

  /// 每次对局都生成一份新的棋盘，避免改动内置局面。
  Uint8List buildCells() {
    final cells = emptyCells();
    for (final index in blackStones) {
      cells[index] = black;
    }
    for (final index in whiteStones) {
      cells[index] = white;
    }
    return cells;
  }
}

List<int> _stones(String notation) => [
  for (final token in notation.split(' ')) MoveNotation.parse(token)!,
];

/// 十道内置残局，均由引擎验证存在限定手数内的强制胜。
final List<GomokuPuzzle> kGomokuPuzzles = [
  GomokuPuzzle(
    id: 'p01',
    title: '横贯长空',
    tier: PuzzleTier.starter,
    moveLimit: 1,
    blackStones: _stones('E8 F8 G8 H8'),
    whiteStones: _stones('D8 F6 J10 G11'),
    tip: '黑棋已经连成四子，找出能立刻成五的交叉点。',
  ),
  GomokuPuzzle(
    id: 'p02',
    title: '直上青云',
    tier: PuzzleTier.starter,
    moveLimit: 1,
    blackStones: _stones('H5 H6 H7 H8'),
    whiteStones: _stones('H4 J6 J9 E7'),
    tip: '竖线四子被堵住一头，另一端就是胜点。',
  ),
  GomokuPuzzle(
    id: 'p03',
    title: '斜月穿云',
    tier: PuzzleTier.starter,
    moveLimit: 1,
    blackStones: _stones('F6 G7 I9 J10'),
    whiteStones: _stones('G6 H7 G10 H9'),
    tip: '斜线中间留有一处空点，补上即可成五。',
  ),
  GomokuPuzzle(
    id: 'p04',
    title: '雁落平沙',
    tier: PuzzleTier.starter,
    moveLimit: 1,
    blackStones: _stones('J6 I7 H8 G9'),
    whiteStones: _stones('L4 F5 K10 H3'),
    tip: '反斜线已经四子连珠，两个端点任选其一。',
  ),
  GomokuPuzzle(
    id: 'p05',
    title: '活四·横',
    tier: PuzzleTier.advanced,
    moveLimit: 2,
    blackStones: _stones('F8 G8 H8'),
    whiteStones: _stones('F6 G9 J7 J10 I5'),
    tip: '先手做出两端皆空的活四，白棋只能封住一头。',
  ),
  GomokuPuzzle(
    id: 'p06',
    title: '活四·竖',
    tier: PuzzleTier.advanced,
    moveLimit: 2,
    blackStones: _stones('H6 H7 H8'),
    whiteStones: _stones('F6 G9 E7 J10'),
    tip: '把竖线活三养成活四，下一手必然成五。',
  ),
  GomokuPuzzle(
    id: 'p07',
    title: '活四·斜',
    tier: PuzzleTier.advanced,
    moveLimit: 2,
    blackStones: _stones('F6 G7 H8'),
    whiteStones: _stones('H6 G9 J7 I10'),
    tip: '沿对角线延伸成活四，注意两端都要留空。',
  ),
  GomokuPuzzle(
    id: 'p08',
    title: '活四·反斜',
    tier: PuzzleTier.advanced,
    moveLimit: 2,
    blackStones: _stones('J6 I7 H8'),
    whiteStones: _stones('H6 I9 F7 I10'),
    tip: '反斜线的活三同样可以养成活四。',
  ),
  GomokuPuzzle(
    id: 'p09',
    title: '双三·十字',
    tier: PuzzleTier.expert,
    moveLimit: 3,
    blackStones: _stones('H6 H7 F8 G8'),
    whiteStones: _stones('F6 G9 J7 J10 E5'),
    tip: '天元附近落子可同时做出横竖两条活三，白棋无法两头兼顾。',
  ),
  GomokuPuzzle(
    id: 'p10',
    title: '双三·交叉',
    tier: PuzzleTier.expert,
    moveLimit: 3,
    blackStones: _stones('F6 G7 J6 I7'),
    whiteStones: _stones('H6 H9 E7 L10 J4'),
    tip: '两条斜线在中心交叉，一手双三即可撕开防线。',
  ),
];
