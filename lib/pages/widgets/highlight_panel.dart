import 'package:flutter/material.dart';

/// 主题色淡底提示卡：用于开局库说明、残局进度等需要强调的信息块。
class HighlightPanel extends StatelessWidget {
  const HighlightPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: child,
    );
  }
}
