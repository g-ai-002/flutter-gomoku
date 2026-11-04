import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../flame/gomoku_game.dart';
import '../game/engine/board_utils.dart';
import '../game/engine/rules.dart';
import '../game/game_controller.dart';
import '../models/game_models.dart';
import '../models/saved_game.dart';
import '../providers/settings_provider.dart';
import '../services/game_history_service.dart';
import '../services/log_service.dart';
import '../services/sound_service.dart';
import 'review_page.dart';
import 'widgets/board_page_scaffold.dart';
import 'widgets/board_stage.dart';
import 'widgets/clock_bar.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/game_status_bar.dart';
import 'widgets/move_list.dart';
import 'widgets/move_panel.dart';
import 'widgets/play_layout.dart';

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.mode,
    required this.difficulty,
    required this.humanSide,
  });

  final GameMode mode;
  final Difficulty difficulty;
  final int humanSide;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final GameController _controller;
  late final GomokuGame _game;
  late DateTime _startedAt;
  late String _gameId;
  bool _resultShown = false;
  int _seenMoves = 0;

  @override
  void initState() {
    super.initState();
    _resetGameIdentity();
    final settings = context.read<SettingsProvider>();
    _controller = GameController(
      mode: widget.mode,
      difficulty: widget.difficulty,
      humanSide: widget.humanSide,
      showCoordinates: settings.showCoordinates,
      timeControl: settings.timeControl,
    );
    _game = GomokuGame(view: _controller, skin: settings.boardSkin);
    _controller.addListener(_onControllerChanged);
    final clock = _controller.timeControl;
    final clockText = clock.isTimed ? '，棋钟 ${clock.label}' : '';
    LogService.info(
      '开始对局: ${widget.mode.label}, 难度 ${widget.difficulty.label}, '
      '执${widget.humanSide == black ? '黑' : '白'}$clockText',
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
    _syncMoveFeedback();
    final result = _controller.result;
    if (result == null) {
      // 悔棋或重开后回到对局中，下一次终局仍需弹出结果。
      _resultShown = false;
      return;
    }
    if (_resultShown) return;
    _resultShown = true;
    final humanWon = widget.mode == GameMode.twoPlayers
        ? !result.isDraw
        : result.winner == widget.humanSide;
    SoundService.play(humanWon ? MoveFeedback.win : MoveFeedback.lose);
    _archiveGame(result);
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

  /// 新增着法时给出落子反馈，形成活四时补一声上行提示音。
  void _syncMoveFeedback() {
    final history = _controller.history;
    if (history.length <= _seenMoves) {
      _seenMoves = history.length;
      return;
    }
    for (var i = _seenMoves; i < history.length; i++) {
      final record = history[i];
      final openFour = GomokuRules.makesOpenFour(
        _controller.board.cells,
        record.index,
        record.side,
      );
      SoundService.play(openFour ? MoveFeedback.threat : MoveFeedback.place);
    }
    _seenMoves = history.length;
  }

  void _restart() {
    _resultShown = false;
    _seenMoves = 0;
    _resetGameIdentity();
    _controller.restart();
  }

  void _resetGameIdentity() {
    _startedAt = DateTime.now();
    _gameId = 'game_${_startedAt.microsecondsSinceEpoch}';
  }

  String get _gameTitle => widget.mode == GameMode.twoPlayers
      ? widget.mode.label
      : '${widget.mode.label} · ${widget.difficulty.label}';

  /// 终局后写入最近对局；悔棋后重判沿用同一 id，覆盖旧结果而不是新增一条。
  void _archiveGame(GameResult result) {
    if (_controller.history.isEmpty) return;
    unawaited(
      GameHistoryService.instance.record(
        SavedGame(
          id: _gameId,
          title: _gameTitle,
          endedAt: DateTime.now(),
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
          date: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _confirmResign() async {
    if (await confirmResign(context)) _controller.resign();
  }

  void _showMoveSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.55,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => MoveList(
            history: _controller.history,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          ),
        ),
      ),
    );
  }

  void _showRules() => showRulesDialog(context);

  String get _clockSuffix {
    final control = _controller.timeControl;
    return control.isTimed ? ' · ${control.label}' : '';
  }

  String get _subtitle {
    if (widget.mode == GameMode.vsAi) {
      final side = widget.humanSide == black ? '执黑' : '执白';
      return '${widget.difficulty.label} · $side$_clockSuffix';
    }
    return '同屏对弈$_clockSuffix';
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
      body: PlayLayout(
        // 只重建状态与操作区，棋盘与 Flame 画布保持稳定，避免浮层变化推动棋盘。
        status: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _buildStatus(),
        ),
        board: _buildBoard(),
        actions: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _buildActions(showMoves: false),
        ),
        compactBottom: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: _buildActions(showMoves: true),
          ),
        ),
        sidePanel: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _buildSidePanel(),
        ),
      ),
    );
  }

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

  Widget _buildBoard() => RepaintBoundary(
    child: BoardStage(game: _game, gameKey: const ValueKey('gomoku-board')),
  );

  Widget _buildActions({required bool showMoves}) {
    final isAi = widget.mode == GameMode.vsAi;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      children: [
        _ActionButton(
          icon: Icons.undo_rounded,
          label: '悔棋',
          onPressed: _controller.canUndo ? _controller.undo : null,
        ),
        _ActionButton(
          icon: Icons.refresh_rounded,
          label: '重开',
          onPressed: _restart,
        ),
        if (showMoves)
          _ActionButton(
            icon: Icons.format_list_bulleted_rounded,
            label: '棋谱',
            onPressed: _showMoveSheet,
          ),
        if (isAi)
          _ActionButton(
            icon: Icons.lightbulb_outline,
            label: _controller.hintLoading ? '思考中' : '提示',
            onPressed: _controller.canInteractive && !_controller.hintLoading
                ? _controller.requestHint
                : null,
          ),
        if (isAi)
          _ActionButton(
            icon: Icons.flag_outlined,
            label: '认输',
            onPressed: _controller.result == null ? _confirmResign : null,
          ),
      ],
    );
  }

  Widget _buildSidePanel() =>
      MovePanel(history: _controller.history, footer: '提示：点击交叉点直接落子，圆点标记最后一手。');
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onPressed != null;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        foregroundColor: enabled ? colors.onSurface : colors.onSurfaceVariant,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 21),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: enabled ? colors.onSurface : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
