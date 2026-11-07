import 'package:flutter/material.dart';

/// 状态胶囊：淡底细边的圆角标语，对局状态条与棋钟条共用。
///
/// [active] 控制淡底与描边的浓度，[padding] 供不同信息密度微调。
/// [overlay] 换成不透明的表面色底并加投影，用于压在棋盘交叉点上的浮层提示。
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.accent,
    required this.child,
    this.active = true,
    this.overlay = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
  });

  final Color accent;
  final Widget child;
  final bool active;
  final bool overlay;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: overlay
            ? colors.surface.withValues(alpha: 0.9)
            : accent.withValues(alpha: active ? 0.10 : 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: overlay || active ? 0.45 : 0.6),
        ),
        boxShadow: overlay
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
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
/// 宽处固定 30 高单行排布，中间区域单行省略，文案变化不会推动棋盘；
/// 窄栏（横屏竖栏、侧边棋谱栏）里改为纵向堆叠，同样保持整块高度稳定。
class BoardStatusBar extends StatelessWidget {
  const BoardStatusBar({
    super.key,
    required this.accent,
    required this.leading,
    required this.status,
    this.trailing,
  });

  /// 低于该宽度改为纵向堆叠，避免胶囊与文字互相挤压。
  static const double _compactWidth = 260;

  final Color accent;
  final Widget leading;
  final Widget status;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < _compactWidth
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusChip(accent: accent, child: leading),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: status,
                ),
                ?trailing,
              ],
            )
          : SizedBox(
              height: 30,
              child: Row(
                children: [
                  StatusChip(accent: accent, child: leading),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(alignment: Alignment.centerLeft, child: status),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 10),
                    trailing!,
                  ],
                ],
              ),
            ),
    );
  }
}
