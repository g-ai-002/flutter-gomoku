import 'package:flutter/material.dart';

/// 棋盘配色（可变，主题切换时原地更新，避免重建 FlameGame）。
class GomokuPalette {
  GomokuPalette({
    required this.surfaceColor,
    required this.boardColor,
    required this.lineColor,
    required this.borderColor,
  });

  factory GomokuPalette.of(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return GomokuPalette(
      surfaceColor: theme.colorScheme.surface,
      boardColor: isDark ? const Color(0xFF2A2724) : const Color(0xFFE8C99B),
      lineColor: isDark ? const Color(0xFF5A5A5A) : const Color(0xFF8D6E63),
      borderColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFC9A97A),
    );
  }

  Color surfaceColor;
  Color boardColor;
  Color lineColor;
  Color borderColor;

  void updateFrom(GomokuPalette other) {
    surfaceColor = other.surfaceColor;
    boardColor = other.boardColor;
    lineColor = other.lineColor;
    borderColor = other.borderColor;
  }
}
