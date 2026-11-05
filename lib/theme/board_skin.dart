import 'package:flutter/material.dart';

/// 棋面渐变配色：黑棋冷润、白棋暖玉，用光影差异强化辨识。
class StoneFace {
  const StoneFace({required this.light, required this.dark, required this.ink});

  final Color light;
  final Color dark;
  final Color ink;
}

/// 棋盘外观：底色、线条墨色、强调色与双方棋面配色。
///
/// 外观只影响绘制，不参与规则与对局逻辑，所有棋盘页面共用。
class BoardSkin {
  const BoardSkin({
    required this.id,
    required this.name,
    required this.boardLight,
    required this.boardDark,
    required this.line,
    required this.accent,
    required this.blackStone,
    required this.whiteStone,
  });

  final String id;
  final String name;
  final Color boardLight;
  final Color boardDark;
  final Color line;

  /// 最后一手、提示与胜利连线使用的强调色。
  final Color accent;
  final StoneFace blackStone;
  final StoneFace whiteStone;

  StoneFace faceOf(int side) => side == 1 ? blackStone : whiteStone;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [boardLight, boardDark],
  );
}

/// 原木：经典木纹配暖色棋盘。
const BoardSkin kDefaultBoardSkin = BoardSkin(
  id: 'wood',
  name: '原木',
  boardLight: Color(0xFFF4E3C1),
  boardDark: Color(0xFFE0C391),
  line: Color(0xFF8A6337),
  accent: Color(0xFFA63A2B),
  blackStone: StoneFace(
    light: Color(0xFF5E625C),
    dark: Color(0xFF151714),
    ink: Color(0xFF0A0B0A),
  ),
  whiteStone: StoneFace(
    light: Color(0xFFFFFFFF),
    dark: Color(0xFFD9D2C2),
    ink: Color(0xFF8A8274),
  ),
);
