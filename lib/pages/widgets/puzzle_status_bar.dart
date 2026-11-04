import 'package:flutter/material.dart';

import '../../game/engine/board_utils.dart';
import '../../game/puzzle_controller.dart';
import '../../theme/app_theme.dart';
import 'status_chip.dart';
import 'stone_dot.dart';

/// 残局状态条：行棋方、白棋应对中、通关状态与已用手数。
class PuzzleStatusBar extends StatelessWidget {
  const PuzzleStatusBar({super.key, required this.controller});

  final PuzzleController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = switch (controller.status) {
      PuzzleStatus.solved => colors.tertiary,
      PuzzleStatus.failed => colors.error,
      PuzzleStatus.playing =>
        controller.thinking ? colors.primary : sideAccentOf(context, black),
    };
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          StatusChip(accent: accent, child: _label(theme, accent)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              controller.status == PuzzleStatus.failed
                  ? (controller.failureReason ?? '挑战失败')
                  : controller.puzzle.tip,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            controller.progressText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(ThemeData theme, Color accent) {
    final style = theme.textTheme.labelMedium?.copyWith(
      color: accent,
      fontWeight: FontWeight.w600,
    );
    switch (controller.status) {
      case PuzzleStatus.solved:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 15, color: accent),
            const SizedBox(width: 6),
            Text('已通关', style: style),
          ],
        );
      case PuzzleStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 15, color: accent),
            const SizedBox(width: 6),
            Text('挑战失败', style: style),
          ],
        );
      case PuzzleStatus.playing:
        if (controller.thinking) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: accent,
                ),
              ),
              const SizedBox(width: 7),
              Text('白棋应对中…', style: style),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StoneDot(side: black),
            const SizedBox(width: 7),
            Text('轮到你落子', style: style),
          ],
        );
    }
  }
}
