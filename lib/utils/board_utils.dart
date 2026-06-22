import '../models/game_state.dart';

/// 棋盘工具函数：五连检测、棋盘复制等
class BoardUtils {
  BoardUtils._();

  /// 四个检测方向
  static const List<(int, int)> directions = [
    (0, 1), // 水平
    (1, 0), // 垂直
    (1, 1), // 对角线
    (1, -1), // 反对角线
  ];

  /// 检查最后落子是否形成五连，返回获胜线段的起止位置
  static (Position, Position)? checkWin(
    List<List<StoneColor?>> board,
    Position last,
  ) {
    final size = board.length;
    if (last.row < 0 || last.row >= size || last.col < 0 || last.col >= size) {
      return null;
    }
    final color = board[last.row][last.col];
    if (color == null) return null;

    for (final (dr, dc) in directions) {
      int count = 1;
      int r, c;

      r = last.row + dr;
      c = last.col + dc;
      while (r >= 0 && r < size && c >= 0 && c < size && board[r][c] == color) {
        count++;
        r += dr;
        c += dc;
      }
      final endRow = r - dr;
      final endCol = c - dc;

      r = last.row - dr;
      c = last.col - dc;
      while (r >= 0 && r < size && c >= 0 && c < size && board[r][c] == color) {
        count++;
        r -= dr;
        c -= dc;
      }
      final startRow = r + dr;
      final startCol = c + dc;

      if (count >= 5) {
        return (Position(startRow, startCol), Position(endRow, endCol));
      }
    }
    return null;
  }

  /// 深拷贝棋盘
  static List<List<StoneColor?>> copyBoard(List<List<StoneColor?>> board) {
    return board.map((r) => List<StoneColor?>.from(r)).toList();
  }
}
