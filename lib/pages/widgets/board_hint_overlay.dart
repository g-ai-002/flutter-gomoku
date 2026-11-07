import 'package:flutter/material.dart';

import '../../game/position_insight.dart';
import 'status_chip.dart';

/// 棋盘浮层提示：开局名、形势判断与禁手图例分居棋盘四角。
///
/// 浮层不参与状态区的高度计算，提示出现、消失或换行都不会改变棋盘尺寸；
/// 由调用方包在 [IgnorePointer] 里，落子手势仍直达棋盘。
class BoardHintOverlay extends StatelessWidget {
  const BoardHintOverlay({
    super.key,
    this.opening,
    this.insight,
    this.showForbiddenLegend = false,
  });

  /// 当前命中的开局名，为空时不显示。
  final String? opening;

  /// 当前形势判断，为空时不显示胜率提示。
  final PositionInsight? insight;

  /// 是否显示禁手图例，由当前禁手点集合决定。
  final bool showForbiddenLegend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget chip(Alignment alignment, IconData icon, String text, Color accent) {
      return Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: StatusChip(
            accent: accent,
            overlay: true,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: accent),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hints = [
      if (opening != null)
        chip(
          Alignment.topLeft,
          Icons.auto_stories_outlined,
          '开局 · $opening',
          colors.primary,
        ),
      if (insight != null)
        chip(
          Alignment.topRight,
          Icons.insights_outlined,
          '形势 · 黑 ${insight!.blackPercent}% · 白 ${insight!.whitePercent}%',
          colors.primary,
        ),
      if (showForbiddenLegend)
        chip(
          Alignment.bottomLeft,
          Icons.block_outlined,
          '红圈为黑棋禁手点',
          _forbiddenAccent,
        ),
    ];
    return hints.isEmpty ? const SizedBox.shrink() : Stack(children: hints);
  }
}

const Color _forbiddenAccent = Color(0xFFB23A2B);
