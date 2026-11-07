import 'package:flutter/material.dart';

/// 对局页与残局页共用的底部操作按钮：图标在上、文字在下。
class BoardActionButton extends StatelessWidget {
  const BoardActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onPressed != null;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(56, 48),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        foregroundColor: enabled ? colors.onSurface : colors.onSurfaceVariant,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 21),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: enabled ? colors.onSurface : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
