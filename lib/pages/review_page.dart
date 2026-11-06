import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../flame/gomoku_game.dart';
import '../game/game_archive.dart';
import '../game/handicap.dart';
import '../game/replay_controller.dart';
import '../models/move_record.dart';
import '../services/file_system_service.dart';
import '../services/log_service.dart';
import '../utils/formatters.dart';
import 'widgets/app_snack.dart';
import 'widgets/board_page_scaffold.dart';
import 'widgets/board_stage.dart';
import 'widgets/move_list.dart';
import 'widgets/move_panel.dart';
import 'widgets/play_layout.dart';

/// 复盘页：逐手回放一局棋谱，并支持导出为文本棋谱。
class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.title,
    required this.moves,
    this.result,
    this.date,
    this.handicap = Handicap.none,
  });

  final String title;
  final List<MoveRecord> moves;
  final String? result;

  /// 棋谱结束时间，导出时写入「日期」；为空时取当前时间。
  final DateTime? date;

  /// 该局使用的让子方案，复盘与再次导出时沿用。
  final Handicap handicap;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final ReplayController _replay;
  late final GomokuGame _game;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _replay = ReplayController(moves: widget.moves, handicap: widget.handicap);
    _game = GomokuGame(view: _replay);
    LogService.info('进入复盘: ${widget.title}, 共 ${_replay.total} 手');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _replay.dispose();
    super.dispose();
  }

  bool get _playing => _timer != null;

  void _togglePlay() {
    if (_playing) {
      _stop();
      return;
    }
    if (_replay.finished) _replay.first();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted || _replay.finished) {
        _stop();
        return;
      }
      _replay.next();
    });
    setState(() {});
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
  }

  Future<void> _copyArchive() async {
    await Clipboard.setData(ClipboardData(text: _archiveText()));
    if (!mounted) return;
    LogService.info('导出棋谱: 复制到剪贴板, 共 ${widget.moves.length} 手');
    showSnack(context, '棋谱已复制到剪贴板');
  }

  Future<void> _saveArchive() async {
    final now = DateTime.now();
    final name =
        'game_${formatDateKey(now)}_${pad2(now.hour)}${pad2(now.minute)}'
        '${pad2(now.second)}.txt';
    final path = await FileSystemService.instance.saveText(
      name,
      _archiveText(),
    );
    if (!mounted) return;
    if (path == null) {
      showSnack(context, '棋谱保存失败');
      return;
    }
    LogService.info('导出棋谱: 已保存到 $path');
    showSnack(context, '棋谱已保存到 $path');
  }

  String _archiveText() => GameArchive.encode(
    title: widget.title,
    moves: widget.moves,
    result: widget.result,
    date: widget.date,
    handicap: widget.handicap,
  );

  @override
  Widget build(BuildContext context) {
    return BoardPageScaffold(
      title: '复盘',
      caption: widget.title,
      actions: [
        IconButton(
          tooltip: '复制棋谱',
          onPressed: _copyArchive,
          icon: const Icon(Icons.copy_all_outlined, size: 21),
        ),
        if (!kIsWeb)
          IconButton(
            tooltip: '保存棋谱',
            onPressed: _saveArchive,
            icon: const Icon(Icons.save_alt, size: 21),
          ),
      ],
      body: AnimatedBuilder(
        animation: _replay,
        builder: (context, _) => PlayLayout(
          board: _buildBoard(),
          actions: _buildControls(),
          compactBottom: Column(
            children: [
              _buildControls(),
              SizedBox(
                height: 132,
                child: MoveList(
                  history: widget.moves,
                  highlightIndex: _replay.cursor - 1,
                  onTapIndex: (index) => _replay.jumpTo(index + 1),
                  padding: const EdgeInsets.only(bottom: 6),
                ),
              ),
            ],
          ),
          sidePanel: _buildSidePanel(),
        ),
      ),
    );
  }

  Widget _buildSidePanel() => MovePanel(
    history: widget.moves,
    highlightIndex: _replay.cursor - 1,
    onTapIndex: (index) => _replay.jumpTo(index + 1),
    footer: _summaryText(),
  );

  String _summaryText() {
    final parts = [
      if (widget.result != null && widget.result!.isNotEmpty) widget.result!,
      '共 ${_replay.total} 手',
      '点击棋谱可跳转到对应手数',
    ];
    return parts.join(' · ');
  }

  Widget _buildBoard() =>
      BoardStage(game: _game, gameKey: const ValueKey('review-board'));

  Widget _buildControls() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final total = _replay.total;
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: '回到开局',
              onPressed: _replay.canPrevious ? _replay.first : null,
              icon: const Icon(Icons.first_page_rounded),
            ),
            IconButton(
              tooltip: '上一步',
              onPressed: _replay.canPrevious ? _replay.previous : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton.filledTonal(
              tooltip: _playing ? '暂停回放' : '自动回放',
              onPressed: total == 0 ? null : _togglePlay,
              icon: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 22,
              ),
            ),
            IconButton(
              tooltip: '下一步',
              onPressed: _replay.canNext ? _replay.next : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            IconButton(
              tooltip: '跳到终局',
              onPressed: _replay.canNext ? _replay.last : null,
              icon: const Icon(Icons.last_page_rounded),
            ),
            const SizedBox(width: 4),
            Text(
              _replay.progressText,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Slider(
          value: _replay.cursor.toDouble(),
          max: math.max(1, total).toDouble(),
          divisions: total > 0 ? total : null,
          onChanged: total == 0
              ? null
              : (value) {
                  _stop();
                  _replay.jumpTo(value.round());
                },
        ),
      ],
    );
  }
}
