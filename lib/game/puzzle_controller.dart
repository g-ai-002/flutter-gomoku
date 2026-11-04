import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/game_models.dart';
import '../models/move_record.dart';
import '../services/log_service.dart';
import 'ai_player.dart';
import 'board_state.dart';
import 'board_view.dart';
import 'engine/board_utils.dart';
import 'engine/rules.dart';
import 'hint_session.dart';
import 'notation.dart';
import 'puzzles.dart';

/// 残局进度：进行中、通关或失败。
enum PuzzleStatus { playing, solved, failed }

/// 残局控制器：玩家执黑，白棋由本地 AI 应对，并在限定手数内判定成败。
class PuzzleController extends ChangeNotifier implements BoardView {
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

  late GomokuBoard board;

  PuzzleStatus status = PuzzleStatus.playing;
  String? failureReason;

  /// 玩家已走的手数，白棋的应手不计入。
  int playerMoves = 0;
  bool thinking = false;

  late final HintSession _hint = HintSession(_notify);

  @override
  int? get hintIndex => _hint.index;

  bool get hintLoading => _hint.loading;

  int _serial = 0;
  bool _disposed = false;

  @override
  Uint8List get cells => board.cells;

  @override
  List<MoveRecord> get history => board.history;

  @override
  int? get lastIndex => board.lastIndex;

  @override
  List<int> get winningLine => board.winningLine;

  @override
  bool get showCoordinates => true;

  @override
  int get sideToMove => board.sideToMove;

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
    _serial++;
    clearHint(notify: false);
    thinking = false;
    if (board.history.isNotEmpty && board.history.last.side == white) {
      board.undoLast();
    }
    board.undoLast();
    playerMoves = math.max(0, playerMoves - 1);
    status = PuzzleStatus.playing;
    failureReason = null;
    LogService.info('残局悔棋: ${puzzle.title}');
    _notify();
  }

  void restart() {
    _serial++;
    clearHint(notify: false);
    board = GomokuBoard.fromCells(puzzle.buildCells());
    playerMoves = 0;
    status = PuzzleStatus.playing;
    failureReason = null;
    thinking = false;
    LogService.info('残局重开: ${puzzle.title}');
    _notify();
  }

  Future<void> requestHint() async {
    if (!canInteract || hintLoading) return;
    final serial = _hint.begin();
    if (kIsWeb) await Future<void>.delayed(Duration.zero);
    if (!_hint.isCurrent(serial)) return;

    int? move;
    try {
      move = await _hintMove(Uint8List.fromList(board.cells), black);
    } catch (error, stack) {
      LogService.error('残局提示搜索失败', error, stack);
    }
    if (!_hint.isCurrent(serial)) return;

    if (move != null &&
        move >= 0 &&
        move < cellCount &&
        board.cells[move] == empty &&
        canInteract) {
      _hint.show(move);
      LogService.info('残局提示: ${MoveNotation.describe(move)}');
    } else {
      _hint.finish();
    }
  }

  void clearHint({bool notify = true}) => _hint.clear(notify: notify);

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
    _notify();
    if (board.sideToMove == white) _defend();
  }

  Future<void> _defend() async {
    if (thinking) return;
    thinking = true;
    final serial = ++_serial;
    _notify();
    if (kIsWeb) await Future<void>.delayed(Duration.zero);
    if (_disposed || serial != _serial) return;

    AiReply? reply;
    try {
      reply = await _aiMove(
        Uint8List.fromList(board.cells),
        white,
        Difficulty.normal,
      );
    } catch (error, stack) {
      LogService.error('残局 AI 应手失败', error, stack);
    }
    if (_disposed || serial != _serial) return;

    thinking = false;
    final candidate = reply?.move ?? -1;
    final move =
        candidate >= 0 &&
            candidate < cellCount &&
            board.cells[candidate] == empty
        ? candidate
        : _fallbackDefense();
    if (move == null) {
      _fail('白棋已无子可下');
      return;
    }
    _play(move);
  }

  /// 兜底应手：白棋先成五，其次封堵黑棋成五，最后取任意候选点。
  int? _fallbackDefense() {
    final tactical = GomokuRules.tacticalMove(board.cells, white);
    if (tactical != null) return tactical;
    final candidates = GomokuRules.candidateMoves(board.cells);
    return candidates.isEmpty ? null : candidates.first;
  }

  void _finish() {
    status = PuzzleStatus.solved;
    thinking = false;
    clearHint(notify: false);
    LogService.info('残局通关: ${puzzle.id} ${puzzle.title}, $playerMoves 手');
    _notify();
  }

  void _fail(String reason) {
    status = PuzzleStatus.failed;
    failureReason = reason;
    thinking = false;
    clearHint(notify: false);
    LogService.info('残局失败: ${puzzle.id} ${puzzle.title}（$reason）');
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _serial++;
    _hint.dispose();
    super.dispose();
  }
}
