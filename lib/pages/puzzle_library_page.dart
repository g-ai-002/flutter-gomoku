import 'package:flutter/material.dart';

import '../game/puzzles.dart';
import '../services/puzzle_progress_service.dart';
import 'puzzle_page.dart';
import 'widgets/app_snack.dart';
import 'widgets/entry_tile.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/highlight_panel.dart';
import 'widgets/page_list.dart';

/// 残局列表：按难度分组展示十道内置杀局与通关进度。
class PuzzleLibraryPage extends StatefulWidget {
  const PuzzleLibraryPage({super.key});

  @override
  State<PuzzleLibraryPage> createState() => _PuzzleLibraryPageState();
}

class _PuzzleLibraryPageState extends State<PuzzleLibraryPage> {
  final PuzzleProgressService _progress = PuzzleProgressService.instance;

  @override
  void initState() {
    super.initState();
    _progress.load();
  }

  void _open(GomokuPuzzle puzzle) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => PuzzlePage(puzzle: puzzle)));
  }

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

  /// 按难度分组，避免在布局中反复过滤内置残局。
  List<(PuzzleTier, List<GomokuPuzzle>)> _groups() => [
    for (final tier in PuzzleTier.values)
      (
        tier,
        [
          for (final puzzle in kGomokuPuzzles)
            if (puzzle.tier == tier) puzzle,
        ],
      ),
  ];

  Widget _puzzleTile(GomokuPuzzle puzzle) {
    final colors = Theme.of(context).colorScheme;
    final solved = _progress.isSolved(puzzle.id);
    return EntryTile(
      leading: EntryBadge(
        accent: solved ? colors.tertiary : colors.primary,
        icon: solved ? Icons.check_rounded : Icons.flag_outlined,
      ),
      title: puzzle.title,
      subtitle: '${puzzle.moveLimit} 手内成五 · ${puzzle.tip}',
      trailing: solved ? _SolvedTag(color: colors.tertiary) : null,
      onTap: () => _open(puzzle),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('残局挑战'),
        actions: [
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
          listenable: _progress,
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
                for (final (tier, puzzles) in _groups()) ...[
                  _TierHeader(
                    tier: tier,
                    solved: puzzles
                        .where((puzzle) => _progress.isSolved(puzzle.id))
                        .length,
                    total: puzzles.length,
                  ),
                  const SizedBox(height: 8),
                  for (final puzzle in puzzles) ...[
                    _puzzleTile(puzzle),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                ],
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
              Expanded(
                child: Text(
                  '从一步成五到双三杀，逐关练习棋型嗅觉。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
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

class _SolvedTag extends StatelessWidget {
  const _SolvedTag({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '已通关',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
