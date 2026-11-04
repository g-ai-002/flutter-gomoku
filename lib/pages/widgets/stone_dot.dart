import 'package:flutter/material.dart';

import '../../game/engine/board_utils.dart';

/// 行棋方的小圆点：黑棋实心、白棋留浅色描边。
class StoneDot extends StatelessWidget {
  const StoneDot({super.key, required this.side, this.size = 9});

  final int side;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isBlack = side == black;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isBlack ? colors.onSurface : colors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isBlack ? colors.onSurface : colors.outline,
          width: 1.2,
        ),
      ),
    );
  }
}
