import 'package:flutter/material.dart';

/// 状态胶囊：淡底细边的圆角标语，对局状态条与棋钟条共用。
///
/// [filled] 为 true 时用实心底色配 [onAccent] 文字（如「将军」），
/// 否则用 [accent] 的淡底与描边，[active] 控制淡底与描边的浓度。
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.accent,
    required this.child,
    this.filled = false,
    this.active = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
  });

  final Color accent;
  final Widget child;
  final bool filled;
  final bool active;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: filled ? accent : accent.withValues(alpha: active ? 0.10 : 0.04),
        borderRadius: BorderRadius.circular(20),
        border: filled
            ? null
            : Border.all(
                color: active
                    ? accent.withValues(alpha: 0.45)
                    : colors.outline.withValues(alpha: 0.6),
              ),
      ),
      child: child,
    );
  }
}

/// 状态条里的小型进度圈，统一对局与残局的尺寸与线宽。
class StatusSpinner extends StatelessWidget {
  const StatusSpinner({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: CircularProgressIndicator(strokeWidth: 1.8, color: color),
    );
  }
}

/// 对局与残局状态条共用的骨架：行棋方胶囊、状态说明与右侧信息。
///
/// 固定 30 高，中间区域单行省略，文案变化不会推动棋盘；
/// 两页只需提供强调色、胶囊内容、状态文案与右侧补充信息。
class BoardStatusBar extends StatelessWidget {
  const BoardStatusBar({
    super.key,
    required this.accent,
    required this.leading,
    required this.status,
    this.trailing,
  });

  final Color accent;
  final Widget leading;
  final Widget status;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          StatusChip(accent: accent, child: leading),
          const SizedBox(width: 10),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: status),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}
