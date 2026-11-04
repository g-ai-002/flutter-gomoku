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
import 'engine/forbidden.dart';
import 'engine/rules.dart';
import 'hint_session.dart';
import 'match_clock.dart';
import 'notation.dart';
import 'opening_book.dart';

/// 对局控制器：落子、AI 回合、悔棋、棋钟与终局判定。
class GameController extends ChangeNotifier implements BoardView {
  GameController({
    required this.mode,
    required this.difficulty,
    required this.humanSide,
    AiMoveProvider? aiMove,
    HintMoveProvider? hintMove,
    GomokuBoard? board,
    this.showCoordinates = true,
    this.timeControl = TimeControl.none,
    this.forbidBlack = false,
    this.openingBook,
    math.Random? openingRandom,
  }) : board = board ?? GomokuBoard(forbidBlack: forbidBlack),
       _aiMove = aiMove ?? AiPlayer.chooseMove,
       _hintMove = hintMove ?? AiPlayer.hintMove,
       _openingRandom = openingRandom ?? math.Random() {
    this.board.forbidBlack = forbidBlack;
  }

  final GameMode mode;
  final Difficulty difficulty;
  final int humanSide;
  @override
  final bool showCoordinates;

  /// 是否启用黑棋禁手（长连、四四、三三）。
  final bool forbidBlack;

  @override
  Uint8List get cells => board.cells;
  final TimeControl timeControl;
  final GomokuBoard board;
  final AiMoveProvider _aiMove;
  final HintMoveProvider _hintMove;

  /// 内置开局库，为空时全部由搜索引擎给出着法。
  final OpeningBook? openingBook;
  final math.Random _openingRandom;
  OpeningLine? _bookLine;

  late final ClockTracker? _tracker = timeControl.isTimed
      ? ClockTracker(timeControl)
      : null;

  /// 限时对局的棋钟，供界面展示双方剩余时间。
  MatchClock? get clock => _tracker?.clock;

  bool thinking = false;
  GameResult? result;

  /// 最近一次禁手尝试，供界面提示；合法落子后清空。
  ForbiddenReason? lastViolation;
  int violationCount = 0;

  Set<int>? _forbiddenCache;

  /// 最近一次 AI 搜索摘要，供界面展示引擎层数与用时。
  AiInsight? aiInsight;

  late final HintSession _hint = HintSession(_notify);

  @override
  int? get hintIndex => _hint.index;

  bool get hintLoading => _hint.loading;

  int _serial = 0;
  bool _disposed = false;

  @override
  List<MoveRecord> get history => board.history;

  @override
  int? get lastIndex => board.lastIndex;

  @override
  List<int> get winningLine => board.winningLine;

  /// 当前黑棋的禁手点，仅在人类可以落子时计算并缓存。
  @override
  Set<int> get forbiddenPoints {
    if (!forbidBlack || !canInteractive || board.sideToMove != black) {
      return const {};
    }
    return _forbiddenCache ??= GomokuForbidden.points(board.cells);
  }

  bool get isHumanTurn =>
      mode == GameMode.twoPlayers || board.sideToMove == humanSide;

  bool get canInteractive => result == null && !thinking && isHumanTurn;

  @override
  bool get canInteract => canInteractive;

  @override
  int get sideToMove => board.sideToMove;

  bool get canUndo {
    if (board.history.isEmpty) return false;
    if (mode == GameMode.twoPlayers) return true;
    return board.history.any((record) => record.side == humanSide);
  }

  /// 最后一手的行棋方，空盘时为 null。
  int? get lastSide => history.isEmpty ? null : history.last.side;

  /// 当前棋谱命中的开局，未使用开局库或已脱谱时为 null。
  OpeningMatch? get openingMatch {
    final book = openingBook;
    if (book == null) return null;
    return book.match([
      for (final record in board.history) record.index,
    ], preferred: _bookLine);
  }

  /// 前三手定型后的开局名，供界面展示；脱谱后自动消失。
  String? get openingName => openingMatch?.name;

  /// 开局库的下一手：先在前几手中挑选一条候选线，再取其对应着法。
  int? _bookMove() {
    final book = openingBook;
    if (book == null) return null;
    final moves = [for (final record in board.history) record.index];
    final candidates = book.candidates(moves);
    if (candidates.isEmpty) {
      _bookLine = null;
      return null;
    }
    final current = _bookLine;
    if (current == null || !candidates.contains(current)) {
      _bookLine = candidates[_openingRandom.nextInt(candidates.length)];
    }
    final line = _bookLine!;
    if (moves.length >= line.moves.length) return null;
    final side = moves.length.isEven ? black : white;
    if (side != board.sideToMove) return null;
    final move = line.moves[moves.length];
    return board.cells[move] == empty ? move : null;
  }

  /// 页面挂载后调用；人类执白时由 AI 先行。
  void start() {
    _syncClock();
    _notify();
    if (mode == GameMode.vsAi && board.sideToMove != humanSide) _think();
  }

  /// 界面定时调用：结算当前行棋方用时，超时即判负。
  void tickClock([Duration? elapsed]) {
    if (result != null) return;
    final expired = _tracker?.settle(elapsed);
    if (expired == null) return;
    LogService.warning('${sideName(expired)}超时判负');
    _finish(GameResult(winner: opponentOf(expired), reason: '超时'));
  }

  @override
  void tapCell(int index) {
    if (!canInteractive) return;
    if (index < 0 || index >= cellCount || board.cells[index] != empty) {
      return;
    }
    final forbidden = board.forbiddenAt(index);
    if (forbidden != null) {
      lastViolation = forbidden;
      violationCount++;
      LogService.warning(
        '禁手: ${sideName(board.sideToMove)} '
        '${MoveNotation.describe(index)} ${forbidden.label}',
      );
      _notify();
      return;
    }
    _play(index);
  }

  void undo() {
    if (!canUndo) return;
    _serial++;
    clearHint(notify: false);
    thinking = false;
    do {
      board.undoLast();
    } while (mode == GameMode.vsAi &&
        board.history.isNotEmpty &&
        board.sideToMove != humanSide);
    result = null;
    aiInsight = null;
    lastViolation = null;
    _forbiddenCache = null;
    _tracker?.rewind(keepMoves: board.history.length, side: board.sideToMove);
    LogService.info('悔棋，当前轮到${sideName(board.sideToMove)}');
    _notify();
  }

  void restart() {
    _serial++;
    clearHint(notify: false);
    board.reset();
    thinking = false;
    result = null;
    aiInsight = null;
    lastViolation = null;
    _forbiddenCache = null;
    _bookLine = null;
    _tracker?.restart(black);
    LogService.info('重新开始对局');
    _notify();
    if (mode == GameMode.vsAi && board.sideToMove != humanSide) _think();
  }

  void resign() {
    if (result != null) return;
    _serial++;
    clearHint(notify: false);
    thinking = false;
    _finish(GameResult(winner: opponentOf(humanSide), reason: '认输'));
  }

  /// 为当前行棋方请求一条走子提示，结果在棋盘上展示 6 秒。
  Future<void> requestHint() async {
    if (!canInteractive || hintLoading) return;
    final bookMove = _bookMove();
    if (bookMove != null) {
      _hint.show(bookMove);
      LogService.info(
        '开局提示: ${openingMatch?.line.name ?? ''} '
        '${MoveNotation.describe(bookMove)}',
      );
      return;
    }
    final side = board.sideToMove;
    final move = await _hint.request(
      () => _hintMove(
        Uint8List.fromList(board.cells),
        side,
        forbidBlack: forbidBlack,
      ),
      isValid: (move) =>
          move >= 0 &&
          move < cellCount &&
          board.cells[move] == empty &&
          side == board.sideToMove &&
          board.forbiddenAt(move) == null &&
          canInteractive,
      onError: (error, stack) => LogService.error('提示搜索失败', error, stack),
    );
    if (move == null) return;
    LogService.info('走子提示: ${MoveNotation.describe(move)}');
  }

  /// 清除提示并取消尚未返回的提示搜索。
  void clearHint({bool notify = true}) => _hint.clear(notify: notify);

  void _play(int index) {
    tickClock();
    if (result != null) return;
    clearHint(notify: false);
    final record = board.apply(index);
    if (record == null) {
      LogService.warning('落子被拒绝: ${MoveNotation.describe(index)}');
      return;
    }
    lastViolation = null;
    _forbiddenCache = null;
    _tracker?.mark();
    LogService.info(
      '落子 ${sideName(record.side)} ${record.notation}'
      '（第 ${record.moveNumber} 手）',
    );
    _afterMove();
  }

  void _afterMove() {
    final winner = board.winner;
    if (winner != null) {
      _finish(GameResult(winner: winner, reason: '五连'));
      return;
    }
    if (board.isFull) {
      _finish(const GameResult(winner: null, reason: '满盘和棋'));
      return;
    }
    _syncClock();
    _notify();
    if (mode == GameMode.vsAi && board.sideToMove != humanSide) _think();
  }

  void _syncClock() {
    final tracker = _tracker;
    if (tracker == null) return;
    if (result == null) {
      tracker.resume(board.sideToMove);
    } else {
      tracker.stop();
    }
  }

  void _finish(GameResult outcome) {
    result = outcome;
    _tracker?.stop();
    clearHint(notify: false);
    LogService.info('对局结束: ${outcome.title}（${outcome.reason}）');
    _notify();
  }

  Future<void> _think() async {
    if (thinking || result != null) return;
    clearHint(notify: false);
    thinking = true;
    final serial = ++_serial;
    final side = board.sideToMove;
    _notify();

    // 开局前几手优先走内置棋谱，略作停顿让落子动画衔接。
    final bookMove = _bookMove();
    if (bookMove != null) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (_disposed || serial != _serial) return;
      thinking = false;
      LogService.info(
        '开局应手: ${openingMatch?.line.name ?? ''} '
        '${MoveNotation.describe(bookMove)}',
      );
      _play(bookMove);
      return;
    }

    // Web 端搜索与界面同线程，先让「AI 思考中」完成一帧绘制。
    if (kIsWeb) await Future<void>.delayed(Duration.zero);
    if (_disposed || serial != _serial) return;

    final stopwatch = Stopwatch()..start();
    AiReply? reply;
    try {
      reply = await _aiMove(
        Uint8List.fromList(board.cells),
        side,
        difficulty,
        forbidBlack: forbidBlack,
      );
    } catch (error, stack) {
      LogService.error('AI 搜索失败', error, stack);
    }
    if (_disposed || serial != _serial) return;

    thinking = false;
    stopwatch.stop();
    if (reply != null) {
      aiInsight = AiInsight.of(reply, stopwatch.elapsed);
      LogService.info(
        'AI 完成: 深度 ${reply.depth}, 节点 ${reply.nodes}, '
        '评分 ${reply.score}, 用时 ${stopwatch.elapsedMilliseconds}ms',
      );
    }

    final move = reply?.move ?? -1;
    if (move < 0 ||
        move >= cellCount ||
        board.cells[move] != empty ||
        board.forbiddenAt(move) != null) {
      final fallback = _fallbackMove();
      if (fallback == null) {
        _afterMove();
        return;
      }
      LogService.warning('AI 未返回合法着法，改用兜底着法');
      _play(fallback);
      return;
    }
    _play(move);
  }

  /// 兜底：优先自己成五，其次封堵对手成五，最后取离中心最近的空点。
  int? _fallbackMove() {
    final forbidden = forbidBlack && board.sideToMove == black
        ? GomokuForbidden.points(board.cells)
        : const <int>{};
    final tactical = GomokuRules.tacticalMove(board.cells, board.sideToMove);
    if (tactical != null && !forbidden.contains(tactical)) return tactical;
    int? nearest;
    var nearestDistance = 1 << 30;
    for (var index = 0; index < cellCount; index++) {
      if (board.cells[index] != empty || forbidden.contains(index)) continue;
      final row = rowOf(index) - boardSize ~/ 2;
      final col = colOf(index) - boardSize ~/ 2;
      final distance = row.abs() + col.abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = index;
      }
    }
    return nearest;
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
