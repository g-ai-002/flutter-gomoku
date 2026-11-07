import 'dart:async';

import 'package:flutter/material.dart';

import '../flame/gomoku_game.dart';
import '../game/puzzle_controller.dart';
import '../game/puzzles.dart';
import '../services/log_service.dart';
import '../services/move_feedback_tracker.dart';
import '../services/puzzle_progress_service.dart';
import '../services/sound_service.dart';
import '../utils/navigation.dart';
import 'widgets/board_actions.dart';
import 'widgets/board_page_scaffold.dart';
import 'widgets/board_stage.dart';
import 'widgets/play_layout.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/move_panel.dart';
import 'widgets/move_sheet.dart';
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
  late final MoveFeedbackTracker _feedback;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    _controller = PuzzleController(puzzle: widget.puzzle);
    _game = GomokuGame(view: _controller, repaint: _controller);
    _feedback = MoveFeedbackTracker(_controller);
    _controller.addListener(_onChanged);
    LogService.info('进入残局: ${widget.puzzle.id} ${widget.puzzle.title}');
  }

  void _onChanged() {
    if (!mounted) return;
    _feedback.sync();
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

  Future<void> _showResult(bool solved) async {
    if (!mounted) return;
    final index = widget.puzzle.isCustom
        ? -1
        : kGomokuPuzzles.indexOf(widget.puzzle);
    final hasNext = index >= 0 && index + 1 < kGomokuPuzzles.length;
    final action = await showPuzzleResultDialog(
      context,
      solved: solved,
      message: solved
          ? '在 ${widget.puzzle.moveLimit} 手内连成五子'
          : (_controller.failureReason ?? '未能完成残局'),
      note:
          '${widget.puzzle.label} · ${widget.puzzle.title} · '
          '已用 ${_controller.playerMoves}/${widget.puzzle.moveLimit} 手',
      hasNext: hasNext,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case PuzzleResultAction.retry:
        _resultShown = false;
        _feedback.reset();
        _controller.restart();
      case PuzzleResultAction.next:
        final next = kGomokuPuzzles[index + 1];
        replaceScreen<void>(context, PuzzlePage(puzzle: next));
      case PuzzleResultAction.close:
        Navigator.of(context).pop();
    }
  }

  void _showTip() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${widget.puzzle.goal} · ${widget.puzzle.title}'),
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

  void _showMoveSheet() => showMoveSheet(
    context,
    listenable: _controller,
    moves: _controller.history,
  );

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
          '${widget.puzzle.label} · ${widget.puzzle.title} · '
          '${widget.puzzle.moveLimit} 手内成五',
      actions: [
        IconButton(
          tooltip: '残局说明',
          onPressed: _showTip,
          icon: const Icon(Icons.help_outline, size: 21),
        ),
      ],
      body: PlayLayout(
        controller: _controller,
        status: (_) => PuzzleStatusBar(controller: _controller),
        board: BoardStage(game: _game, gameKey: const ValueKey('puzzle-board')),
        actions: (_, showMoves) => _buildActions(showMoves: showMoves),
        sidePanel: (_) => _buildSidePanel(),
        footer: (_) => _buildSidePanel(dense: true),
      ),
    );
  }

  Widget _buildSidePanel({bool dense = false}) => MovePanel(
    history: _controller.history,
    dense: dense,
    footer: '${widget.puzzle.goal} · 白棋由本地 AI 应对，点击交叉点落子。',
  );

  Widget _buildActions({required bool showMoves}) {
    return BoardActions(
      canUndo: _controller.canUndo,
      onUndo: _controller.undo,
      onRestart: _controller.restart,
      onMoves: showMoves ? _showMoveSheet : null,
      onHint: _controller.requestHint,
      hintEnabled: _controller.canInteract,
      hintLoading: _controller.hintLoading,
    );
  }
}
