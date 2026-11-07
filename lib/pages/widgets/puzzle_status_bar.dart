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
    return BoardStatusBar(
      accent: accent,
      leading: _label(theme, accent),
      status: Text(
        controller.status == PuzzleStatus.failed
            ? (controller.failureReason ?? '挑战失败')
            : controller.puzzle.tip,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        controller.progressText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, Color accent) {
    final (icon, text) = switch (controller.status) {
      PuzzleStatus.solved => (
        Icon(Icons.emoji_events_outlined, size: 15, color: accent),
        '已通关',
      ),
      PuzzleStatus.failed => (
        Icon(Icons.close_rounded, size: 15, color: accent),
        '挑战失败',
      ),
      PuzzleStatus.playing when controller.thinking => (
        StatusSpinner(color: accent),
        '白棋应对中…',
      ),
      PuzzleStatus.playing => (const StoneDot(side: black), '轮到你落子'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
