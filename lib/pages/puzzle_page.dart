import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../flame/gomoku_game.dart';
import '../game/engine/rules.dart';
import '../game/puzzle_controller.dart';
import '../game/puzzles.dart';
import '../providers/settings_provider.dart';
import '../services/log_service.dart';
import '../services/puzzle_progress_service.dart';
import '../services/sound_service.dart';
import 'widgets/action_button.dart';
import 'widgets/board_page_scaffold.dart';
import 'widgets/board_stage.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/move_list.dart';
import 'widgets/move_panel.dart';
import 'widgets/play_layout.dart';
import 'widgets/puzzle_status_bar.dart';

/// 残局挑战页：黑先杀局，白棋由本地 AI 应对，并记录通关进度。
class PuzzlePage extends StatefulWidget {
  const PuzzlePage({super.key, required this.puzzle});

  final GomokuPuzzle puzzle;

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  late final PuzzleController _controller;
  late final GomokuGame _game;
  bool _resultShown = false;
  int _seenMoves = 0;

  @override
  void initState() {
    super.initState();
    _controller = PuzzleController(puzzle: widget.puzzle);
    _game = GomokuGame(view: _controller);
    _controller.addListener(_onChanged);
    LogService.info('进入残局: ${widget.puzzle.id} ${widget.puzzle.title}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game.skin = Provider.of<SettingsProvider>(context).boardSkin;
  }

  void _onChanged() {
    if (!mounted) return;
    _syncMoveFeedback();
    final status = _controller.status;
    if (status == PuzzleStatus.playing) {
      _resultShown = false;
      return;
    }
    if (_resultShown) return;
    _resultShown = true;
    final solved = status == PuzzleStatus.solved;
    SoundService.play(solved ? MoveFeedback.win : MoveFeedback.lose);
    if (solved) {
      unawaited(PuzzleProgressService.instance.markSolved(widget.puzzle.id));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _showResult(solved));
  }

  void _syncMoveFeedback() {
    final history = _controller.history;
    if (history.length <= _seenMoves) {
      _seenMoves = history.length;
      return;
    }
    for (var i = _seenMoves; i < history.length; i++) {
      final record = history[i];
      final threat = GomokuRules.makesOpenFour(
        _controller.board.cells,
        record.index,
        record.side,
      );
      SoundService.play(threat ? MoveFeedback.threat : MoveFeedback.place);
    }
    _seenMoves = history.length;
  }

  Future<void> _showResult(bool solved) async {
    if (!mounted) return;
    final index = kGomokuPuzzles.indexOf(widget.puzzle);
    final hasNext = index >= 0 && index + 1 < kGomokuPuzzles.length;
    final action = await showPuzzleResultDialog(
      context,
      solved: solved,
      message: solved
          ? '在 ${widget.puzzle.moveLimit} 手内连成五子'
          : (_controller.failureReason ?? '未能完成残局'),
      note:
          '${widget.puzzle.tier.label} · ${widget.puzzle.title} · '
          '已用 ${_controller.playerMoves}/${widget.puzzle.moveLimit} 手',
      hasNext: hasNext,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case PuzzleResultAction.retry:
        _resultShown = false;
        _seenMoves = 0;
        _controller.restart();
      case PuzzleResultAction.next:
        final next = kGomokuPuzzles[index + 1];
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => PuzzlePage(puzzle: next)),
        );
      case PuzzleResultAction.close:
        Navigator.of(context).pop();
    }
  }

  void _showTip() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${widget.puzzle.tier.goal} · ${widget.puzzle.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '黑先，在 ${widget.puzzle.moveLimit} 手内连成五子。'
              '白棋由本地 AI 应对，未能在限定手数内取胜即挑战失败。',
            ),
            const SizedBox(height: 10),
            Text(
              widget.puzzle.tip,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
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

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BoardPageScaffold(
      title: '残局挑战',
      caption:
          '${widget.puzzle.tier.label} · ${widget.puzzle.title} · '
          '${widget.puzzle.moveLimit} 手内成五',
      actions: [
        IconButton(
          tooltip: '残局说明',
          onPressed: _showTip,
          icon: const Icon(Icons.help_outline, size: 21),
        ),
      ],
      body: PlayLayout(
        status: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => PuzzleStatusBar(controller: _controller),
        ),
        board: RepaintBoundary(
          child: BoardStage(
            game: _game,
            gameKey: const ValueKey('puzzle-board'),
          ),
        ),
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
          builder: (context, _) => MovePanel(
            history: _controller.history,
            footer:
                '${widget.puzzle.tier.goal} · '
                '白棋由本地 AI 应对，点击交叉点落子。',
          ),
        ),
      ),
    );
  }

  Widget _buildActions({required bool showMoves}) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      children: [
        BoardActionButton(
          icon: Icons.undo_rounded,
          label: '悔棋',
          onPressed: _controller.canUndo ? _controller.undo : null,
        ),
        BoardActionButton(
          icon: Icons.refresh_rounded,
          label: '重开',
          onPressed: _controller.restart,
        ),
        if (showMoves)
          BoardActionButton(
            icon: Icons.format_list_bulleted_rounded,
            label: '棋谱',
            onPressed: _showMoveSheet,
          ),
        BoardActionButton(
          icon: Icons.lightbulb_outline,
          label: _controller.hintLoading ? '思考中' : '提示',
          onPressed: _controller.canInteract && !_controller.hintLoading
              ? _controller.requestHint
              : null,
        ),
      ],
    );
  }
}
