import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/game_models.dart';
import '../services/log_service.dart';
import 'ai_player.dart';
import 'board_session.dart';
import 'board_state.dart';
import 'engine/board_utils.dart';
import 'engine/forbidden.dart';
import 'engine/rules.dart';
import 'handicap.dart';
import 'match_clock.dart';
import 'notation.dart';
import 'opening_book.dart';
import 'position_insight.dart';

/// 对局控制器：落子、AI 回合、悔棋、棋钟与终局判定。
class GameController extends BoardSession {
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
    this.handicap = Handicap.none,
    this.openingBook,
    math.Random? openingRandom,
  }) : board =
           board ?? GomokuBoard(forbidBlack: forbidBlack, handicap: handicap),
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

  /// 让子方案，空盘时预置黑子并由白方先行。
  final Handicap handicap;

  final TimeControl timeControl;
  @override
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

  GameResult? result;

  /// 最近一次禁手尝试，供界面提示；合法落子后清空。
  ForbiddenReason? lastViolation;
  int violationCount = 0;

  Set<int>? _forbiddenCache;

  /// 最近一次 AI 搜索摘要，供界面展示引擎层数与用时。
  AiInsight? aiInsight;

  PositionInsight? _insight;
  int _insightMoves = -1;

  /// 当前形势判断，按手数缓存，避免棋钟每秒刷新时重复评估。
  PositionInsight get positionInsight {
    if (_insight == null || _insightMoves != board.history.length) {
      _insightMoves = board.history.length;
      _insight = PositionInsight.of(board.cells);
    }
    return _insight!;
  }

  /// 当前黑棋的禁手点，仅在人类可以落子时计算并缓存。
  @override
  Set<int> get forbiddenPoints {
    if (!forbidBlack || !canInteractive || board.sideToMove != black) {
      return const {};
    }
    return _forbiddenCache ??= GomokuForbidden.points(board.cells);
  }

  bool get isHumanTurn =>
      mode == GameMode.twoPlayers ||
      (mode == GameMode.vsAi && board.sideToMove == humanSide);

  /// 是否轮到本地 AI：人机对战的电脑方，或 AI 对演的双方。
  bool get _aiTurn =>
      mode == GameMode.aiSelf ||
      (mode == GameMode.vsAi && board.sideToMove != humanSide);

  bool get canInteractive => result == null && !thinking && isHumanTurn;

  @override
  bool get canInteract => canInteractive;

  bool get canUndo {
    if (mode == GameMode.aiSelf) return false;
    if (board.history.isEmpty) return false;
    if (mode == GameMode.twoPlayers) return true;
    return board.history.any((record) => record.side == humanSide);
  }

  /// 最后一手的行棋方，空盘时为 null。
  int? get lastSide => history.isEmpty ? null : history.last.side;

  /// 当前棋谱的交叉点序列，供开局库匹配与应手使用。
  List<int> get _moveIndices => [
    for (final record in board.history) record.index,
  ];

  /// 当前棋谱命中的开局，未使用开局库或已脱谱时为 null。
  OpeningMatch? get openingMatch {
    final book = openingBook;
    if (book == null) return null;
    return book.match(_moveIndices, preferred: _bookLine);
  }

  /// 前三手定型后的开局名，供界面展示；脱谱后自动消失。
  String? get openingName => openingMatch?.name;

  /// 开局库的下一手：先在前几手中挑选一条候选线，再取其对应着法。
  int? _bookMove() {
    final book = openingBook;
    if (book == null) return null;
    final moves = _moveIndices;
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
    if (board.cells[move] != empty || board.forbiddenAt(move) != null) {
      return null;
    }
    return move;
  }

  /// 页面挂载后调用；人类执白或 AI 对演时由 AI 先行。
  void start() {
    _syncClock();
    notifyBoard();
    if (_aiTurn) _think();
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
      notifyBoard();
      return;
    }
    _play(index);
  }

  void undo() {
    if (!canUndo) return;
    _resetRound();
    do {
      board.undoLast();
    } while (mode == GameMode.vsAi &&
        board.history.isNotEmpty &&
        board.sideToMove != humanSide);
    _tracker?.rewind(keepMoves: board.history.length, side: board.sideToMove);
    LogService.info('悔棋，当前轮到${sideName(board.sideToMove)}');
    notifyBoard();
  }

  void restart() {
    _resetRound(clearBook: true);
    board.reset();
    _tracker?.restart(board.sideToMove);
    LogService.info('重新开始对局');
    notifyBoard();
    if (_aiTurn) _think();
  }

  /// 清理悔棋与重开共用的异步与终局状态。
  void _resetRound({bool clearBook = false}) {
    clearPending();
    result = null;
    aiInsight = null;
    lastViolation = null;
    _forbiddenCache = null;
    if (clearBook) _bookLine = null;
  }

  void resign() {
    if (result != null) return;
    _finish(GameResult(winner: opponentOf(humanSide), reason: '认输'));
  }

  /// 为当前行棋方请求一条走子提示，结果在棋盘上展示 6 秒。
  Future<void> requestHint() async {
    if (!canInteractive || hintLoading) return;
    final side = board.sideToMove;
    final bookMove = _bookMove();
    if (bookMove != null) {
      hint.show(bookMove);
      LogService.info(
        '开局提示: ${openingMatch?.line.name ?? ''} '
        '${MoveNotation.describe(bookMove)}',
      );
      return;
    }
    await requestMoveHint(
      side: side,
      label: '走子提示',
      search: () => _hintMove(
        Uint8List.fromList(board.cells),
        side,
        forbidBlack: forbidBlack,
      ),
    );
  }

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
    notifyBoard();
    if (_aiTurn) _think();
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
    clearPending();
    LogService.info('对局结束: ${outcome.title}（${outcome.reason}）');
    notifyBoard();
  }

  Future<void> _think() async {
    if (thinking || result != null) return;
    final side = board.sideToMove;

    // 开局前几手优先走内置棋谱，略作停顿让落子动画衔接。
    final bookMove = _bookMove();
    if (bookMove != null) {
      final serial = beginThinking();
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!isCurrent(serial)) return;
      endThinking();
      LogService.info(
        '开局应手: ${openingMatch?.line.name ?? ''} '
        '${MoveNotation.describe(bookMove)}',
      );
      _play(bookMove);
      return;
    }

    final stopwatch = Stopwatch()..start();
    await runAiTurn(
      label: 'AI 搜索',
      search: () => _aiMove(
        Uint8List.fromList(board.cells),
        side,
        difficulty,
        forbidBlack: forbidBlack,
      ),
      onReply: (reply) {
        stopwatch.stop();
        if (reply != null) {
          aiInsight = AiInsight.of(reply, stopwatch.elapsed);
          LogService.info(
            'AI 完成: 深度 ${reply.depth}, 节点 ${reply.nodes}, '
            '评分 ${reply.score}, 用时 ${stopwatch.elapsedMilliseconds}ms',
          );
        }

        final move = GomokuRules.pickMove(
          board.cells,
          board.sideToMove,
          reply?.move,
          forbidden: forbidBlack && board.sideToMove == black
              ? GomokuForbidden.points(board.cells)
              : const {},
        );
        if (move == null) {
          _afterMove();
          return;
        }
        if (move != reply?.move) {
          LogService.warning('AI 未返回合法着法，改用兜底着法');
        }
        _play(move);
      },
    );
  }
}
