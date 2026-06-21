import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

/// 游戏状态管理
class GameProvider extends ChangeNotifier {
  final StorageService _storage;
  GameState _state;

  GameProvider(this._storage)
      : _state = GameState.initial(_storage.boardSize);

  GameState get state => _state;
  int get boardSize => _state.boardSize;
  List<List<StoneColor?>> get board => _state.board;
  StoneColor get currentPlayer => _state.currentPlayer;
  GameStatus get status => _state.status;
  List<Move> get history => _state.history;
  Position? get lastMove => _state.lastMove;
  Position? get winStart => _state.winStart;
  Position? get winEnd => _state.winEnd;
  bool get canUndo => _state.history.isNotEmpty;
  bool get isGameOver => _state.status != GameStatus.playing;

  /// 落子
  bool placeStone(int row, int col) {
    if (_state.status != GameStatus.playing) return false;
    if (row < 0 || row >= _state.boardSize || col < 0 || col >= _state.boardSize) {
      return false;
    }
    if (_state.board[row][col] != null) return false;

    final newBoard = _state.board.map((r) => List<StoneColor?>.from(r)).toList();
    newBoard[row][col] = _state.currentPlayer;

    final pos = Position(row, col);
    final move = Move(
      position: pos,
      color: _state.currentPlayer,
      stepNumber: _state.history.length + 1,
    );

    final newHistory = [..._state.history, move];

    // 检查胜负
    final winResult = _checkWin(newBoard, pos, _state.currentPlayer);

    GameStatus newStatus;
    Position? ws, we;
    if (winResult != null) {
      newStatus = _state.currentPlayer == StoneColor.black
          ? GameStatus.blackWin
          : GameStatus.whiteWin;
      ws = winResult.$1;
      we = winResult.$2;
      LogService.info('${_state.currentPlayer.label} 获胜! 位置: $ws -> $we');
    } else if (newHistory.length >= _state.boardSize * _state.boardSize) {
      newStatus = GameStatus.draw;
      LogService.info('平局!');
    } else {
      newStatus = GameStatus.playing;
    }

    _state = _state.copyWith(
      board: newBoard,
      currentPlayer: _state.currentPlayer.opponent,
      status: newStatus,
      history: newHistory,
      lastMove: pos,
      winStart: ws,
      winEnd: we,
    );

    LogService.info(
        '落子: ${_state.currentPlayer.opponent.label} @ (${row + 1}, ${col + 1}), 步数: ${move.stepNumber}');
    notifyListeners();
    return true;
  }

  /// 悔棋
  bool undo() {
    if (!canUndo) return false;

    final newHistory = List<Move>.from(_state.history)..removeLast();

    // 重建棋盘
    final newBoard = List.generate(
      _state.boardSize,
      (_) => List<StoneColor?>.filled(_state.boardSize, null),
    );
    for (final m in newHistory) {
      newBoard[m.position.row][m.position.col] = m.color;
    }

    final lastM = newHistory.isNotEmpty ? newHistory.last : null;

    _state = _state.copyWith(
      board: newBoard,
      currentPlayer: _state.currentPlayer.opponent,
      status: GameStatus.playing,
      history: newHistory,
      lastMove: lastM?.position,
      winStart: null,
      winEnd: null,
    );

    LogService.info('悔棋, 当前步数: ${newHistory.length}');
    notifyListeners();
    return true;
  }

  /// 重新开始
  void restart() {
    _state = GameState.initial(_state.boardSize);
    LogService.info('重新开始游戏');
    notifyListeners();
  }

  /// 设置棋盘大小并重新开始
  void setBoardSize(int size) {
    if (size < AppConstants.minBoardSize || size > AppConstants.maxBoardSize) {
      return;
    }
    _storage.setBoardSize(size);
    _state = GameState.initial(size);
    LogService.info('设置棋盘大小: $size');
    notifyListeners();
  }

  /// 检查五子连珠
  (Position, Position)? _checkWin(
    List<List<StoneColor?>> board,
    Position last,
    StoneColor color,
  ) {
    final size = board.length;
    const directions = [
      (0, 1), // 水平
      (1, 0), // 垂直
      (1, 1), // 对角线
      (1, -1), // 反对角线
    ];

    for (final (dr, dc) in directions) {
      int count = 1;
      int r, c;

      // 正方向
      r = last.row + dr;
      c = last.col + dc;
      while (r >= 0 && r < size && c >= 0 && c < size && board[r][c] == color) {
        count++;
        r += dr;
        c += dc;
      }
      final endRow = r - dr;
      final endCol = c - dc;

      // 反方向
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
}
