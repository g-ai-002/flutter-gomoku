import 'package:flutter/material.dart';

import '../../game/engine/board_utils.dart';
import '../../game/game_controller.dart';
import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import 'status_chip.dart';
import 'stone_dot.dart';

/// 对局状态条：行棋方、AI 思考中、最后一手与执子信息。
class GameStatusBar extends StatelessWidget {
  const GameStatusBar({
    super.key,
    required this.controller,
    required this.humanSide,
  });

  final GameController controller;
  final int humanSide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final side = controller.board.sideToMove;
    final accent = sideAccentOf(context, side);
    final last = controller.history.isEmpty ? null : controller.history.last;

    return SizedBox(
      height: 30,
      child: Row(
        children: [
          StatusChip(
            accent: accent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StoneDot(side: side),
                const SizedBox(width: 7),
                Text(
                  '${sideName(side)}行棋',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(flex: 4, child: _status(theme)),
          const Spacer(),
          if (last != null)
            StatusChip(
              accent: colors.outline,
              active: false,
              child: Text(
                '第 ${last.moveNumber} 手 ${last.notation}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            )
          else
            Text(
              switch (controller.mode) {
                GameMode.vsAi => humanSide == black ? '你执黑' : '你执白',
                GameMode.aiSelf => '双方 AI',
                GameMode.twoPlayers => '同屏对弈',
              },
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _status(ThemeData theme) {
    if (controller.thinking) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'AI 思考中…',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      );
    }
    final insight = controller.aiInsight;
    if (insight != null && controller.mode != GameMode.twoPlayers) {
      return Tooltip(
        message: insight.detail,
        child: Text(
          insight.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    if (controller.hintLoading) {
      return Text(
        '正在寻找提示…',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      );
    }
    final idle = controller.mode == GameMode.aiSelf ? 'AI 自动落子' : '点击交叉点落子';
    return Text(
      controller.result == null ? idle : '本局已结束',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
