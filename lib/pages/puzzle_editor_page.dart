import 'package:flutter/material.dart';

import '../flame/gomoku_game.dart';
import '../game/custom_puzzles.dart';
import '../game/engine/board_utils.dart';
import '../game/puzzle_editor_controller.dart';
import '../services/log_service.dart';
import '../services/puzzle_progress_service.dart';
import '../utils/navigation.dart';
import 'puzzle_page.dart';
import 'widgets/app_snack.dart';
import 'widgets/board_page_scaffold.dart';
import 'widgets/board_stage.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/play_layout.dart';

/// 残局编辑器：摆子、设置手数并保存为自定义关卡，保存后直接开始挑战。
class PuzzleEditorPage extends StatefulWidget {
  const PuzzleEditorPage({super.key, this.initial});

  /// 编辑已有残局时传入，新建时为 null。
  final CustomPuzzle? initial;

  @override
  State<PuzzleEditorPage> createState() => _PuzzleEditorPageState();
}

class _PuzzleEditorPageState extends State<PuzzleEditorPage> {
  late final PuzzleEditorController _controller;
  late final GomokuGame _game;

  @override
  void initState() {
    super.initState();
    _controller = PuzzleEditorController(initial: widget.initial);
    _game = GomokuGame(view: _controller, repaint: _controller);
    LogService.info(widget.initial == null ? '进入残局编辑器' : '编辑自定义残局');
  }

  Future<void> _save() async {
    final reason = _controller.invalidReason;
    if (reason != null) {
      showSnack(context, reason);
      return;
    }
    var draft =
        widget.initial?.title ??
        '我的残局 ${CustomPuzzleService.instance.puzzles.length + 1}';
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('残局名称'),
        content: TextFormField(
          initialValue: draft,
          autofocus: true,
          maxLength: 20,
          textInputAction: TextInputAction.done,
          onChanged: (value) => draft = value,
          onFieldSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          decoration: const InputDecoration(
            hintText: '例如：双三杀',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(draft),
            child: const Text('保存并挑战'),
          ),
        ],
      ),
    );
    final title = result?.trim();
    if (!mounted || title == null) return;
    if (title.isEmpty) {
      showSnack(context, '请输入残局名称');
      return;
    }
    final saved = await CustomPuzzleService.instance.save(
      id: widget.initial?.id,
      title: title,
      moveLimit: _controller.moveLimit,
      blackStones: _controller.blackStones,
      whiteStones: _controller.whiteStones,
    );
    if (!mounted) return;
    replaceScreen<void>(context, PuzzlePage(puzzle: saved.toPuzzle()));
  }

  Future<void> _delete() async {
    final initial = widget.initial;
    if (initial == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: '删除这个残局？',
      message: '删除后无法恢复，已经记录的残局通关进度会一并清除。',
      confirmLabel: '删除',
    );
    if (!confirmed || !mounted) return;
    await CustomPuzzleService.instance.remove(initial.id);
    await PuzzleProgressService.instance.forget(initial.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BoardPageScaffold(
      title: widget.initial == null ? '新建残局' : '编辑残局',
      caption: '点击空点落子 · 再点棋子移除',
      actions: [
        if (widget.initial != null)
          IconButton(
            tooltip: '删除残局',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline, size: 21),
          ),
        IconButton(
          tooltip: '保存并挑战',
          onPressed: _save,
          icon: const Icon(Icons.check_rounded, size: 22),
        ),
      ],
      body: PlayLayout(
        controller: _controller,
        board: BoardStage(
          game: _game,
          gameKey: const ValueKey('puzzle-editor-board'),
        ),
        sidePanel: (_) => Text(
          '黑棋先行，在限定手数内连成五子即通关。'
          '点击已落下的棋子可将其移除，至少摆放一枚黑棋才能保存。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: (_, _) => _panel(),
      ),
    );
  }

  Widget _panel() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final reason = _controller.invalidReason;
    final stones = _controller.blackCount + _controller.whiteCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: black, label: Text('黑子')),
              ButtonSegment(value: white, label: Text('白子')),
            ],
            selected: {_controller.brush},
            showSelectedIcon: false,
            onSelectionChanged: (value) => _controller.setBrush(value.first),
          ),
          Row(
            children: [
              IconButton(
                tooltip: '减少手数',
                onPressed: _controller.moveLimit > 1
                    ? () => _controller.setMoveLimit(_controller.moveLimit - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline, size: 21),
              ),
              Expanded(
                child: Text(
                  '限 ${_controller.moveLimit} 手内成五',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                tooltip: '增加手数',
                onPressed: _controller.moveLimit < CustomPuzzle.maxMoveLimit
                    ? () => _controller.setMoveLimit(_controller.moveLimit + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline, size: 21),
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '黑 ${_controller.blackCount} · 白 ${_controller.whiteCount}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              TextButton.icon(
                onPressed: stones == 0 ? null : _controller.clear,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('清空'),
              ),
            ],
          ),
          if (reason != null)
            Text(
              reason,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
            ),
        ],
      ),
    );
  }
}
