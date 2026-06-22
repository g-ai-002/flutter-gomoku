import 'package:flutter/material.dart';
import '../models/game_record.dart';
import '../models/game_state.dart';
import '../widgets/board_painter.dart';

/// 对局回放页面
class ReplayPage extends StatefulWidget {
  final GameRecord record;

  const ReplayPage({super.key, required this.record});

  @override
  State<ReplayPage> createState() => _ReplayPageState();
}

class _ReplayPageState extends State<ReplayPage> {
  late int _currentStep;
  late List<List<StoneColor?>> _board;
  late GameStatus _status;
  Position? _lastMove;
  Position? _winStart;
  Position? _winEnd;
  bool _autoPlaying = false;

  GameRecord get record => widget.record;

  @override
  void initState() {
    super.initState();
    _currentStep = 0;
    _board = List.generate(
      record.boardSize,
      (_) => List.filled(record.boardSize, null),
    );
    _status = GameStatus.playing;
    _applyMovesUpTo(0);
  }

  void _applyMovesUpTo(int step) {
    _board = List.generate(
      record.boardSize,
      (_) => List.filled(record.boardSize, null),
    );
    _lastMove = null;
    _winStart = null;
    _winEnd = null;
    _status = GameStatus.playing;

    for (int i = 0; i < step && i < record.moves.length; i++) {
      final move = record.moves[i];
      _board[move.position.row][move.position.col] = move.color;
      _lastMove = move.position;

      // 检查胜负
      final color = _board[move.position.row][move.position.col];
      if (color != null) {
        final win = _checkWin(move.position);
        if (win != null) {
          _winStart = win.$1;
          _winEnd = win.$2;
          _status = color == StoneColor.black ? GameStatus.blackWin : GameStatus.whiteWin;
        }
      }
    }

    if (_status == GameStatus.playing && step >= record.moves.length && record.moves.isNotEmpty) {
      _status = record.result;
    }
  }

  (Position, Position)? _checkWin(Position last) {
    final size = record.boardSize;
    final color = _board[last.row][last.col];
    if (color == null) return null;

    const dirs = [(0, 1), (1, 0), (1, 1), (1, -1)];
    for (final (dr, dc) in dirs) {
      int count = 1;
      int r = last.row + dr, c = last.col + dc;
      while (r >= 0 && r < size && c >= 0 && c < size && _board[r][c] == color) {
        count++;
        r += dr;
        c += dc;
      }
      final endRow = r - dr;
      final endCol = c - dc;

      r = last.row - dr;
      c = last.col - dc;
      while (r >= 0 && r < size && c >= 0 && c < size && _board[r][c] == color) {
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

  void _stepForward() {
    if (_currentStep < record.moves.length) {
      setState(() {
        _currentStep++;
        _applyMovesUpTo(_currentStep);
      });
    }
  }

  void _stepBackward() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _applyMovesUpTo(_currentStep);
      });
    }
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
      _autoPlaying = false;
      return;
    }
    _autoPlaying = true;
    _autoStep();
  }

  void _autoStep() {
    if (!_autoPlaying) return;
    if (_currentStep >= record.moves.length) {
      _autoPlaying = false;
      setState(() {});
      return;
    }
    setState(() {
      _currentStep++;
      _applyMovesUpTo(_currentStep);
    });
    Future.delayed(const Duration(milliseconds: 500), _autoStep);
  }

  @override
  void dispose() {
    _autoPlaying = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOver = _status != GameStatus.playing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('对局回放'),
      ),
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxSize = constraints.maxWidth;
                        final cellSize = (maxSize - 16) / record.boardSize;
                        final boardPixelSize = cellSize * (record.boardSize - 1);
                        final padding = (maxSize - boardPixelSize) / 2;

                        return CustomPaint(
                          size: Size(maxSize, maxSize),
                          painter: BoardPainter(
                            boardSize: record.boardSize,
                            cellSize: cellSize,
                            padding: padding,
                            board: _board,
                            lastMove: _lastMove,
                            winStart: _winStart,
                            winEnd: _winEnd,
                            isDark: theme.brightness == Brightness.dark,
                          ),
                        );
                      },
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
    if (_status == GameStatus.playing && _currentStep < record.moves.length) {
      statusText = '回放中';
    } else if (_status == GameStatus.blackWin) {
      statusText = '黑棋胜';
    } else if (_status == GameStatus.whiteWin) {
      statusText = '白棋胜';
    } else if (_status == GameStatus.draw) {
      statusText = '平局';
    } else {
      statusText = '准备开始';
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
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
              min: 0,
              max: record.moves.length.toDouble(),
              divisions: record.moves.length,
              onChanged: (v) {
                setState(() {
                  _currentStep = v.round();
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
                onPressed: _currentStep < record.moves.length ? _stepForward : null,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                tooltip: '结束',
                onPressed: _currentStep < record.moves.length ? _goToEnd : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
