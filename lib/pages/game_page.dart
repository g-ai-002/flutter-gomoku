import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../flame/gomoku_game.dart';
import '../game/engine/board_utils.dart';
import '../game/game_controller.dart';
import '../game/opening_book.dart';
import '../models/game_models.dart';
import '../models/saved_game.dart';
import '../providers/settings_provider.dart';
import '../services/game_history_service.dart';
import '../services/log_service.dart';
import '../services/move_feedback_tracker.dart';
import '../services/sound_service.dart';
import 'review_page.dart';
import 'widgets/app_snack.dart';
import 'widgets/board_actions.dart';
import 'widgets/board_hint_overlay.dart';
import 'widgets/board_page_scaffold.dart';
import 'widgets/board_play_layout.dart';
import 'widgets/board_stage.dart';
import 'widgets/clock_bar.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/game_status_bar.dart';
import 'widgets/move_panel.dart';
import 'widgets/move_sheet.dart';

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.mode,
    required this.difficulty,
    required this.humanSide,
    this.opening,
  });

  final GameMode mode;
  final Difficulty difficulty;
  final int humanSide;

  /// 开局练习选定的棋谱；为空时人机执黑可自动启用内置开局库。
  final OpeningLine? opening;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final GameController _controller;
  late final GomokuGame _game;
  late final MoveFeedbackTracker _feedback;
  late DateTime _startedAt;
  late String _gameId;
  DateTime? _endedAt;
  bool _resultShown = false;
  int _seenViolations = 0;

  @override
  void initState() {
    super.initState();
    _resetGameIdentity();
    final settings = context.read<SettingsProvider>();
    final opening = widget.opening;
    final useBook =
        opening != null ||
        (widget.mode == GameMode.vsAi &&
            widget.humanSide == black &&
            settings.openingHints);
    _controller = GameController(
      mode: widget.mode,
      difficulty: widget.difficulty,
      humanSide: widget.humanSide,
      showCoordinates: settings.showCoordinates,
      timeControl: settings.timeControl,
      forbidBlack: settings.forbiddenRule,
      openingBook: useBook
          ? (opening == null ? OpeningBook.standard : OpeningBook([opening]))
          : null,
    );
    _game = GomokuGame(view: _controller, skin: settings.boardSkin);
    _feedback = MoveFeedbackTracker(_controller);
    _controller.addListener(_onControllerChanged);
    final clock = _controller.timeControl;
    final clockText = clock.isTimed ? '，棋钟 ${clock.label}' : '';
    final openingText = opening == null ? '' : '，开局练习 ${opening.name}';
    LogService.info(
      '开始对局: ${widget.mode.label}, 难度 ${widget.difficulty.label}, '
      '执${widget.humanSide == black ? '黑' : '白'}$clockText$openingText',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.start();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game.skin = Provider.of<SettingsProvider>(context).boardSkin;
  }

  void _onControllerChanged() {
    if (!mounted) return;
    _feedback.sync();
    if (_controller.violationCount > _seenViolations) {
      _seenViolations = _controller.violationCount;
      final violation = _controller.lastViolation;
      if (violation != null) {
        _showViolation(violation.label, violation.description);
      }
    }
    final result = _controller.result;
    if (result == null) {
      // 悔棋或重开后回到对局中，下一次终局仍需弹出结果。
      _resultShown = false;
      return;
    }
    if (_resultShown) return;
    _resultShown = true;
    final endedAt = DateTime.now();
    _endedAt = endedAt;
    final humanWon = widget.mode == GameMode.twoPlayers
        ? !result.isDraw
        : result.winner == widget.humanSide;
    SoundService.play(humanWon ? MoveFeedback.win : MoveFeedback.lose);
    _archiveGame(result, endedAt);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGameResultDialog(
        context,
        result: result,
        moveCount: _controller.history.length,
        onRestart: _restart,
        onReview: _openReview,
      );
    });
  }

  void _restart() {
    _resultShown = false;
    _feedback.reset();
    _resetGameIdentity();
    _controller.restart();
  }

  void _resetGameIdentity() {
    _startedAt = DateTime.now();
    _gameId = 'game_${_startedAt.microsecondsSinceEpoch}';
    _endedAt = null;
  }

  /// 禁手提示：短暂浮层说明不可落子的原因，不打断对局。
  void _showViolation(String label, String description) {
    showSnack(context, '$label · $description');
  }

  String get _gameTitle => widget.mode == GameMode.twoPlayers
      ? widget.mode.label
      : '${widget.mode.label} · ${widget.difficulty.label}';

  /// 终局后写入最近对局；悔棋后重判沿用同一 id，覆盖旧结果而不是新增一条。
  void _archiveGame(GameResult result, DateTime endedAt) {
    if (_controller.history.isEmpty) return;
    unawaited(
      GameHistoryService.instance.record(
        SavedGame(
          id: _gameId,
          title: _gameTitle,
          endedAt: endedAt,
          moves: _controller.history,
          result: '${result.title}（${result.reason}）',
        ),
      ),
    );
  }

  /// 终局后进入复盘，棋谱快照一并带过去。
  void _openReview() {
    final result = _controller.result;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewPage(
          title: _gameTitle,
          result: result == null ? null : '${result.title}（${result.reason}）',
          moves: List.of(_controller.history),
          date: _endedAt ?? DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _confirmResign() async {
    if (await confirmResign(context)) _controller.resign();
  }

  void _showMoveSheet() => showMoveSheet(
    context,
    listenable: _controller,
    moves: _controller.history,
  );

  void _showRules() => showRulesDialog(context);

  String get _clockSuffix {
    final control = _controller.timeControl;
    return control.isTimed ? ' · ${control.label}' : '';
  }

  String get _ruleSuffix => _controller.forbidBlack ? ' · 禁手' : '';

  String get _subtitle {
    final opening = widget.opening;
    if (opening != null) return '开局练习 · ${opening.name}$_ruleSuffix';
    if (widget.mode == GameMode.vsAi) {
      final side = widget.humanSide == black ? '执黑' : '执白';
      return '${widget.difficulty.label} · $side$_clockSuffix$_ruleSuffix';
    }
    return '同屏对弈$_clockSuffix$_ruleSuffix';
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BoardPageScaffold(
      title: widget.mode.label,
      caption: _subtitle,
      actions: [
        IconButton(
          tooltip: '行棋规则',
          onPressed: _showRules,
          icon: const Icon(Icons.help_outline, size: 21),
        ),
      ],
      body: BoardPlayLayout(
        controller: _controller,
        status: (_) => _buildStatus(),
        board: _buildBoard(),
        actions: (_, showMoves) => _buildActions(showMoves: showMoves),
        sidePanel: (_) => _buildSidePanel(),
      ),
    );
  }

  /// 状态区只放固定高度的状态条与棋钟，开局名与禁手图例改由棋盘浮层展示。
  Widget _buildStatus() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameStatusBar(controller: _controller, humanSide: widget.humanSide),
        if (_controller.clock != null) ...[
          const SizedBox(height: 8),
          ClockBar(controller: _controller),
        ],
      ],
    );
  }

  Widget _buildBoard() => BoardStage(
    game: _game,
    gameKey: const ValueKey('gomoku-board'),
    overlays: IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => BoardHintOverlay(
          opening: _controller.openingName,
          showForbiddenLegend: _controller.forbiddenPoints.isNotEmpty,
        ),
      ),
    ),
  );

  Widget _buildActions({required bool showMoves}) {
    final isAi = widget.mode == GameMode.vsAi;
    return BoardActions(
      canUndo: _controller.canUndo,
      onUndo: _controller.undo,
      onRestart: _restart,
      onMoves: showMoves ? _showMoveSheet : null,
      onHint: isAi ? _controller.requestHint : null,
      hintEnabled: _controller.canInteractive,
      hintLoading: _controller.hintLoading,
      onResign: isAi && _controller.result == null ? _confirmResign : null,
    );
  }

  Widget _buildSidePanel() =>
      MovePanel(history: _controller.history, footer: '提示：点击交叉点直接落子，圆点标记最后一手。');
}
