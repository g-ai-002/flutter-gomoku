import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/gomoku_game.dart';
import '../game/gomoku_palette.dart';
import '../game/replay_board.dart';
import '../models/game_record.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';

/// 对局回放页面（Flame 棋盘 + Flutter 控制条）。
class ReplayPage extends StatefulWidget {
  final GameRecord record;

  const ReplayPage({super.key, required this.record});

  @override
  State<ReplayPage> createState() => _ReplayPageState();
}

class _ReplayPageState extends State<ReplayPage> {
  late final ReplayBoard _view = ReplayBoard(widget.record.boardSize);
  GomokuGame? _game;
  GomokuPalette? _palette;
  int _currentStep = 0;
  bool _autoPlaying = false;

  GameRecord get record => widget.record;

  @override
  void initState() {
    super.initState();
    _applyMovesUpTo(0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themePalette = GomokuPalette.of(Theme.of(context));
    if (_game != null && _palette != null) {
      _palette!.updateFrom(themePalette);
      return;
    }
    _palette = themePalette;
    _game = GomokuGame(
      source: _view,
      palette: themePalette,
      onAutoStep: _handleAutoStep,
    );
  }

  @override
  void dispose() {
    _autoPlaying = false;
    _game?.autoPlay = false;
    super.dispose();
  }

  void _applyMovesUpTo(int step) {
    _view.seek(step, record.moves);

    if (_view.status == GameStatus.playing &&
        step >= record.moves.length &&
        record.moves.isNotEmpty) {
      _view.status = record.result;
    }
  }

  void _stepForward() {
    if (_currentStep >= record.moves.length) {
      return;
    }
    setState(() {
      _currentStep++;
      _applyMovesUpTo(_currentStep);
    });
  }

  void _stepBackward() {
    if (_currentStep <= 0) {
      return;
    }
    setState(() {
      _currentStep--;
      _applyMovesUpTo(_currentStep);
    });
  }

  void _goToStart() {
    setState(() {
      _currentStep = 0;
      _applyMovesUpTo(0);
    });
  }

  void _goToEnd() {
    setState(() {
      _currentStep = record.moves.length;
      _applyMovesUpTo(record.moves.length);
    });
  }

  void _toggleAutoPlay() {
    if (_autoPlaying) {
      setState(() => _autoPlaying = false);
      _game?.autoPlay = false;
      return;
    }
    if (_currentStep >= record.moves.length) {
      return;
    }
    setState(() => _autoPlaying = true);
    final game = _game;
    if (game != null) {
      game.autoPlayInterval =
          AppConstants.replayAutoPlayDelayMs / 1000;
      game.autoPlay = true;
    }
  }

  void _handleAutoStep() {
    if (!_autoPlaying) {
      return;
    }
    if (_currentStep >= record.moves.length) {
      setState(() => _autoPlaying = false);
      _game?.autoPlay = false;
      return;
    }
    setState(() {
      _currentStep++;
      _applyMovesUpTo(_currentStep);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = _game;

    return Scaffold(
      appBar: AppBar(title: const Text('对局回放')),
      body: SafeArea(
        child: Column(
          children: [
            _buildInfoBar(theme),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: game == null
                        ? const SizedBox.expand()
                        : GameWidget<GomokuGame>(
                            game: game,
                            autofocus: false,
                          ),
                  ),
                ),
              ),
            ),
            _buildControlBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar(ThemeData theme) {
    String statusText;
    if (_view.status == GameStatus.playing &&
        _currentStep < record.moves.length) {
      statusText = '回放中';
    } else if (_view.status == GameStatus.playing) {
      statusText = '准备开始';
    } else {
      statusText = _view.status.label;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            statusText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '第 $_currentStep / ${record.moves.length} 手',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _currentStep.toDouble(),
              max: record.moves.length.toDouble(),
              divisions: record.moves.length,
              onChanged: (value) {
                setState(() {
                  _currentStep = value.round();
                  _applyMovesUpTo(_currentStep);
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                tooltip: '开始',
                onPressed: _currentStep > 0 ? _goToStart : null,
              ),
              IconButton(
                icon: const Icon(Icons.navigate_before),
                tooltip: '上一步',
                onPressed: _currentStep > 0 ? _stepBackward : null,
              ),
              IconButton(
                icon: Icon(_autoPlaying ? Icons.pause : Icons.play_arrow),
                tooltip: _autoPlaying ? '暂停' : '自动播放',
                onPressed: _toggleAutoPlay,
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                tooltip: '下一步',
                onPressed:
                    _currentStep < record.moves.length ? _stepForward : null,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                tooltip: '结束',
                onPressed:
                    _currentStep < record.moves.length ? _goToEnd : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
