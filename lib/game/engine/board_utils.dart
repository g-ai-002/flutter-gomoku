/// 五子棋棋盘的基础定义。
///
/// 坐标约定：`row` 0..14 从上到下，`col` 0..14 从左到右；
/// 交叉点线性下标为 `row * 15 + col`。黑棋先行。
library;

import 'dart:typed_data';

const int boardSize = 15;
const int cellCount = boardSize * boardSize;

const int empty = 0;
const int black = 1;
const int white = 2;

/// 四个扫描方向：横、竖、右下、左下。
const List<(int, int)> kDirections = [(0, 1), (1, 0), (1, 1), (1, -1)];

int rowOf(int index) => index ~/ boardSize;
int colOf(int index) => index % boardSize;
int indexOf(int row, int col) => row * boardSize + col;

bool inBoard(int row, int col) =>
    row >= 0 && row < boardSize && col >= 0 && col < boardSize;

int opponentOf(int side) => side == black ? white : black;

String sideName(int side) => side == black ? '黑方' : '白方';

String stoneName(int side) => side == black ? '黑棋' : '白棋';

/// 中心点，空盘时的第一手。
const int centerIndex = (boardSize ~/ 2) * boardSize + boardSize ~/ 2;

/// 空棋盘。
Uint8List emptyCells() => Uint8List(cellCount);

/// 棋盘上的落子数量。
int stoneCount(Uint8List cells) {
  var count = 0;
  for (final value in cells) {
    if (value != empty) count++;
  }
  return count;
}

bool isBoardFull(Uint8List cells) => stoneCount(cells) >= cellCount;
