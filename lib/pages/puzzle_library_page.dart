import 'package:flutter/material.dart';

import '../game/custom_puzzles.dart';
import '../game/puzzles.dart';
import '../services/puzzle_progress_service.dart';
import '../utils/navigation.dart';
import 'puzzle_editor_page.dart';
import 'puzzle_page.dart';
import 'widgets/app_snack.dart';
import 'widgets/entry_tile.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/highlight_panel.dart';
import 'widgets/page_list.dart';
import 'widgets/status_chip.dart';

/// 残局列表：按难度分组展示十道内置杀局，并管理玩家自建的残局。
class PuzzleLibraryPage extends StatefulWidget {
  const PuzzleLibraryPage({super.key});

  @override
  State<PuzzleLibraryPage> createState() => _PuzzleLibraryPageState();
}

class _PuzzleLibraryPageState extends State<PuzzleLibraryPage> {
  final PuzzleProgressService _progress = PuzzleProgressService.instance;
  final CustomPuzzleService _custom = CustomPuzzleService.instance;
  late final Listenable _revision = Listenable.merge([_progress, _custom]);

  @override
  void initState() {
    super.initState();
    _progress.load();
    _custom.load();
  }

  void _open(GomokuPuzzle puzzle) =>
      pushScreen<void>(context, PuzzlePage(puzzle: puzzle));

  void _openEditor([CustomPuzzle? initial]) =>
      pushScreen<void>(context, PuzzleEditorPage(initial: initial));

  Future<void> _clearProgress() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '清空通关记录？',
      message: '已通关的残局会重新标记为未完成，不影响对局与棋谱。',
      confirmLabel: '清空',
    );
    if (!confirmed) return;
    await _progress.clear();
    if (!mounted) return;
    showSnack(context, '残局进度已清空');
  }

  /// 内置残局按难度分组，静态缓存，避免每次构建重复过滤。
  static final List<(PuzzleTier, List<GomokuPuzzle>)> _grouped = [
    for (final tier in PuzzleTier.values)
      (
        tier,
        [
          for (final puzzle in kGomokuPuzzles)
            if (puzzle.tier == tier) puzzle,
        ],
      ),
  ];

  /// 内置与自定义关卡共用的入口卡片。
  Widget _puzzleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required bool solved,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return EntryTile(
      leading: EntryBadge(
        accent: solved ? colors.tertiary : accent,
        icon: solved ? Icons.check_rounded : icon,
      ),
      title: title,
      subtitle: subtitle,
      trailing:
          trailing ??
          (solved
              ? StatusChip(
                  accent: colors.tertiary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  child: Text(
                    '已通关',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.tertiary,
                    ),
                  ),
                )
              : null),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _builtinTile(GomokuPuzzle puzzle) => _puzzleTile(
    title: puzzle.title,
    subtitle: '${puzzle.moveLimit} 手内成五 · ${puzzle.tip}',
    icon: Icons.flag_outlined,
    accent: Theme.of(context).colorScheme.primary,
    solved: _progress.isSolved(puzzle.id),
    onTap: () => _open(puzzle),
  );

  Widget _customTile(CustomPuzzle puzzle) => _puzzleTile(
    title: puzzle.title,
    subtitle:
        '${puzzle.moveLimit} 手内成五 · '
        '黑 ${puzzle.blackStones.length} 子 / 白 ${puzzle.whiteStones.length} 子',
    icon: Icons.extension_outlined,
    accent: Theme.of(context).colorScheme.secondary,
    solved: _progress.isSolved(puzzle.id),
    onTap: () => _open(puzzle.toPuzzle()),
    trailing: TextButton(
      onPressed: () => _openEditor(puzzle),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: const Text('编辑'),
    ),
  );

  Widget _customSection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final puzzles = _custom.puzzles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '我的残局',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${puzzles.length}/${CustomPuzzle.maxCount}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('新建'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (puzzles.isEmpty)
          HighlightPanel(
            child: Text(
              '还没有自定义残局，点击「新建」摆一个属于你的杀局。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final puzzle in puzzles) ...[
            _customTile(puzzle),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('残局挑战'),
        actions: [
          IconButton(
            tooltip: '新建残局',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_rounded, size: 22),
          ),
          ListenableBuilder(
            listenable: _progress,
            builder: (context, _) => IconButton(
              tooltip: '清空进度',
              onPressed: _progress.solvedCount == 0 ? null : _clearProgress,
              icon: const Icon(Icons.restart_alt_rounded, size: 21),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _revision,
          builder: (context, _) {
            final solved = _progress.solvedCount;
            final total = kGomokuPuzzles.length;
            return PageList(
              children: [
                _ProgressHeader(
                  solved: solved,
                  total: total,
                  onStart: () => _open(kGomokuPuzzles.first),
                ),
                const SizedBox(height: 18),
                for (final (tier, puzzles) in _grouped) ...[
                  _TierHeader(
                    tier: tier,
                    solved: puzzles
                        .where((puzzle) => _progress.isSolved(puzzle.id))
                        .length,
                    total: puzzles.length,
                  ),
                  const SizedBox(height: 8),
                  for (final puzzle in puzzles) ...[
                    _builtinTile(puzzle),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                ],
                _customSection(context),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.solved,
    required this.total,
    required this.onStart,
  });

  final int solved;
  final int total;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final subtle = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final ratio = total == 0 ? 0.0 : solved / total;
    return HighlightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text('十道杀法', style: theme.textTheme.titleSmall),
              const Spacer(),
              Text(
                '已通关 $solved/$total',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colors.primary.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('从一步成五到双三杀，逐关练习棋型嗅觉。', style: subtle)),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(solved == 0 ? '开始挑战' : '继续挑战'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierHeader extends StatelessWidget {
  const _TierHeader({
    required this.tier,
    required this.solved,
    required this.total,
  });

  final PuzzleTier tier;
  final int solved;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Text(
          tier.label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          tier.goal,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          '$solved/$total',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
