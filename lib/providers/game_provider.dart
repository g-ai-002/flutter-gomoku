import 'dart:async';
import 'package:flutter/foundation.dart';
import '../ai/ai_engine.dart';
import '../models/game_state.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

/// 游戏状态管理
class GameProvider extends ChangeNotifier {
  final StorageService _storage;
  GameState _state;
  GameMode _mode;
  AIDifficulty _aiDifficulty;
  GomokuAI _ai;
  bool _aiThinking = false;

  GameProvider(this._storage)
      : _state = GameState.initial(_storage.boardSize),
        _mode = _storage.gameMode,
        _aiDifficulty = _storage.aiDifficulty,
        _ai = GomokuAI(_storage.aiDifficulty);

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
  GameMode get mode => _mode;
  AIDifficulty get aiDifficulty => _aiDifficulty;
  bool get aiThinking => _aiThinking;

  /// 落子
  bool placeStone(int row, int col) {
    if (_state.status != GameStatus.playing) return false;
    if (_aiThinking) return false;
    if (row < 0 || row >= _state.boardSize || col < 0 || col >= _state.boardSize) {
      return false;
    }
    if (_state.board[row][col] != null) return false;

    _applyMove(row, col);

    // 人机模式：AI 自动落子
    if (_mode == GameMode.pve && _state.status == GameStatus.playing) {
      _scheduleAIMove();
    }

    return true;
  }

  void _applyMove(int row, int col) {
    final newBoard = _state.board.map((r) => List<StoneColor?>.from(r)).toList();
    newBoard[row][col] = _state.currentPlayer;

    final pos = Position(row, col);
    final move = Move(
      position: pos,
      color: _state.currentPlayer,
      stepNumber: _state.history.length + 1,
    );

    final newHistory = [..._state.history, move];

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
  }

  void _scheduleAIMove() {
    _aiThinking = true;
    notifyListeners();

    // 使用微延迟让 UI 先刷新
    Future.delayed(const Duration(milliseconds: 200), () {
      final move = _ai.findBestMove(_state);
      if (move != null && _state.status == GameStatus.playing) {
        _applyMove(move.row, move.col);
      }
      _aiThinking = false;
      notifyListeners();
    });
  }

  /// 悔棋
  bool undo() {
    if (!canUndo) return false;
    if (_aiThinking) return false;

    // 人机模式：悔两步（玩家 + AI）
    final steps = (_mode == GameMode.pve && _state.history.length >= 2) ? 2 : 1;

    for (int i = 0; i < steps; i++) {
      if (_state.history.isEmpty) break;
      final newHistory = List<Move>.from(_state.history)..removeLast();

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
    }

    LogService.info('悔棋, 当前步数: ${_state.history.length}');
    notifyListeners();
    return true;
  }

  /// 重新开始
  void restart() {
    _state = GameState.initial(_state.boardSize);
    _aiThinking = false;
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
    _aiThinking = false;
    LogService.info('设置棋盘大小: $size');
    notifyListeners();
  }

  /// 设置游戏模式
  void setGameMode(GameMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _storage.setGameMode(mode);
    _state = GameState.initial(_state.boardSize);
    _aiThinking = false;
    LogService.info('设置游戏模式: ${mode.label}');
    notifyListeners();
  }

  /// 设置 AI 难度
  void setAIDifficulty(AIDifficulty difficulty) {
    if (_aiDifficulty == difficulty) return;
    _aiDifficulty = difficulty;
    _ai = GomokuAI(difficulty);
    _storage.setAIDifficulty(difficulty);
    _state = GameState.initial(_state.boardSize);
    _aiThinking = false;
    LogService.info('设置 AI 难度: ${difficulty.label}');
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
