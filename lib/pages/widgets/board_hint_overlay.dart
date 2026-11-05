import 'package:flutter/material.dart';

/// 棋盘浮层提示：开局名与禁手图例叠在棋盘上方。
///
/// 浮层不参与状态区的高度计算，提示出现、消失或换行都不会改变棋盘尺寸；
/// 由调用方包在 [IgnorePointer] 里，落子手势仍直达棋盘。
class BoardHintOverlay extends StatelessWidget {
  const BoardHintOverlay({
    super.key,
    this.opening,
    this.showForbiddenLegend = false,
  });

  /// 当前命中的开局名，为空时不显示。
  final String? opening;

  /// 是否显示禁手图例，由当前禁手点集合决定。
  final bool showForbiddenLegend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chips = <Widget>[
      if (opening != null)
        _HintChip(
          icon: Icons.auto_stories_outlined,
          text: '开局 · $opening',
          accent: colors.primary,
        ),
      if (showForbiddenLegend)
        _HintChip(
          icon: Icons.block_outlined,
          text: '红圈为黑棋禁手点',
          accent: _forbiddenAccent,
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// 与棋盘上的禁手标记同一色系，提示与标记能对上号。
const Color _forbiddenAccent = Color(0xFFB23A2B);

class _HintChip extends StatelessWidget {
  const _HintChip({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
    );
  }
}
