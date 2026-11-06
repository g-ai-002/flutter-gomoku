import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/game_models.dart';
import '../services/log_service.dart';
import 'ai_player.dart';
import 'board_session.dart';
import 'board_state.dart';
import 'engine/board_utils.dart';
import 'engine/rules.dart';
import 'notation.dart';
import 'puzzles.dart';

/// 残局进度：进行中、通关或失败。
enum PuzzleStatus { playing, solved, failed }

/// 残局控制器：玩家执黑，白棋由本地 AI 应对，并在限定手数内判定成败。
class PuzzleController extends BoardSession {
  PuzzleController({
    required this.puzzle,
    AiMoveProvider? aiMove,
    HintMoveProvider? hintMove,
  }) : board = GomokuBoard.fromCells(puzzle.buildCells()),
       _aiMove = aiMove ?? AiPlayer.chooseMove,
       _hintMove = hintMove ?? AiPlayer.hintMove;

  final GomokuPuzzle puzzle;
  final AiMoveProvider _aiMove;
  final HintMoveProvider _hintMove;

  @override
  late GomokuBoard board;
  PuzzleStatus status = PuzzleStatus.playing;
  String? failureReason;

  /// 玩家已走的手数，白棋的应手不计入。
  int playerMoves = 0;

  @override
  bool get showCoordinates => true;

  @override
  Set<int> get forbiddenPoints => const {};

  @override
  bool get allowsReplace => false;

  @override
  int get revision => 0;

  @override
  bool get canInteract =>
      status == PuzzleStatus.playing && !thinking && board.sideToMove == black;

  bool get canUndo =>
      status != PuzzleStatus.solved &&
      !thinking &&
      board.history.any((record) => record.side == black);

  bool get isSolved => status == PuzzleStatus.solved;

  String get progressText => '第 $playerMoves/${puzzle.moveLimit} 手';

  @override
  void tapCell(int index) {
    if (!canInteract) return;
    if (index < 0 || index >= cellCount || board.cells[index] != empty) {
      return;
    }
    _play(index);
  }

  /// 悔棋撤回玩家最近一手与白棋的应手。
  void undo() {
    if (!canUndo) return;
    cancelPending();
    clearHint(notify: false);
    endThinking();
    if (board.history.isNotEmpty && board.history.last.side == white) {
      board.undoLast();
    }
    board.undoLast();
    playerMoves = math.max(0, playerMoves - 1);
    status = PuzzleStatus.playing;
    failureReason = null;
    LogService.info('残局悔棋: ${puzzle.title}');
    notifyBoard();
  }

  void restart() {
    cancelPending();
    clearHint(notify: false);
    board = GomokuBoard.fromCells(puzzle.buildCells());
    playerMoves = 0;
    status = PuzzleStatus.playing;
    failureReason = null;
    endThinking();
    LogService.info('残局重开: ${puzzle.title}');
    notifyBoard();
  }

  Future<void> requestHint() async {
    if (!canInteract || hintLoading) return;
    final move = await hint.request(
      () => _hintMove(Uint8List.fromList(board.cells), black),
      isValid: (move) =>
          move >= 0 &&
          move < cellCount &&
          board.cells[move] == empty &&
          canInteract,
      onError: (error, stack) => LogService.error('残局提示搜索失败', error, stack),
    );
    if (move == null) return;
    LogService.info('残局提示: ${MoveNotation.describe(move)}');
  }

  void _play(int index) {
    clearHint(notify: false);
    final record = board.apply(index);
    if (record == null) return;
    if (record.side == black) playerMoves++;
    LogService.info(
      '残局 ${puzzle.id} 落子 ${sideName(record.side)} ${record.notation}',
    );
    _afterMove();
  }

  void _afterMove() {
    final winner = board.winner;
    if (winner == black) {
      _finish();
      return;
    }
    if (winner == white) {
      _fail('白棋先连成五子');
      return;
    }
    if (board.isFull) {
      _fail('棋盘已满，未能成五');
      return;
    }
    if (playerMoves >= puzzle.moveLimit) {
      _fail('未能在 ${puzzle.moveLimit} 手内取胜');
      return;
    }
    notifyBoard();
    if (board.sideToMove == white) _defend();
  }

  Future<void> _defend() async {
    if (thinking) return;
    final serial = beginThinking();
    final reply = await searchAi(
      serial: serial,
      search: () =>
          _aiMove(Uint8List.fromList(board.cells), white, Difficulty.normal),
      label: '残局 AI 应手',
    );
    if (!isCurrent(serial)) return;

    endThinking();
    final candidate = reply?.move ?? -1;
    final move =
        candidate >= 0 &&
            candidate < cellCount &&
            board.cells[candidate] == empty
        ? candidate
        : GomokuRules.fallbackMove(board.cells, white);
    if (move == null) {
      _fail('白棋已无子可下');
      return;
    }
    _play(move);
  }

  void _finish() {
    _end(PuzzleStatus.solved);
    LogService.info('残局通关: ${puzzle.id} ${puzzle.title}, $playerMoves 手');
  }

  void _fail(String reason) {
    _end(PuzzleStatus.failed, reason);
    LogService.info('残局失败: ${puzzle.id} ${puzzle.title}（$reason）');
  }

  /// 终局统一收起思考态与提示，再通知界面刷新结果。
  void _end(PuzzleStatus outcome, [String? reason]) {
    status = outcome;
    failureReason = reason;
    endThinking();
    clearHint(notify: false);
    notifyBoard();
  }
}
