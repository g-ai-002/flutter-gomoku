import 'package:flutter/material.dart';

/// 棋面渐变配色：黑棋冷润、白棋暖玉，用光影差异强化辨识。
class StoneFace {
  const StoneFace({required this.light, required this.dark, required this.ink});

  final Color light;
  final Color dark;
  final Color ink;
}

/// 棋盘皮肤：棋盘底色、线条墨色、星位、强调色与双方棋面配色。
///
/// 皮肤只影响绘制，不参与规则与对局逻辑，对局页、复盘页与首页缩略图共用。
class BoardSkin {
  const BoardSkin({
    required this.id,
    required this.name,
    required this.description,
    required this.boardLight,
    required this.boardDark,
    required this.line,
    required this.accent,
    required this.blackStone,
    required this.whiteStone,
  });

  final String id;
  final String name;
  final String description;
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
const BoardSkin woodSkin = BoardSkin(
  id: 'wood',
  name: '原木',
  description: '经典木纹',
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

/// 青玉：淡青棋盘配冷调线条，适合白天久坐。
const BoardSkin jadeSkin = BoardSkin(
  id: 'jade',
  name: '青玉',
  description: '淡青素雅',
  boardLight: Color(0xFFE9F1E4),
  boardDark: Color(0xFFC7DBC7),
  line: Color(0xFF4C6B57),
  accent: Color(0xFF2F5D50),
  blackStone: StoneFace(
    light: Color(0xFF56645C),
    dark: Color(0xFF171E1A),
    ink: Color(0xFF0C100D),
  ),
  whiteStone: StoneFace(
    light: Color(0xFFFDFEF9),
    dark: Color(0xFFD5DCCF),
    ink: Color(0xFF7F8B7D),
  ),
);

/// 墨韵：深墨棋盘配浅色线条，夜间观感沉静。
const BoardSkin inkSkin = BoardSkin(
  id: 'ink',
  name: '墨韵',
  description: '深墨夜局',
  boardLight: Color(0xFF4C524D),
  boardDark: Color(0xFF2E3330),
  line: Color(0xFFE2DAC8),
  accent: Color(0xFFE7B25C),
  blackStone: StoneFace(
    light: Color(0xFF6A7169),
    dark: Color(0xFF171B18),
    ink: Color(0xFF070907),
  ),
  whiteStone: StoneFace(
    light: Color(0xFFFFFFFF),
    dark: Color(0xFFE2DCCD),
    ink: Color(0xFF807A6C),
  ),
);

/// 默认皮肤：偏好缺失或 id 失效时统一回退到此皮肤。
const BoardSkin kDefaultBoardSkin = woodSkin;

/// 全部可选皮肤，顺序即设置页展示顺序。
const List<BoardSkin> kBoardSkins = [woodSkin, jadeSkin, inkSkin];

/// 按 id 取皮肤，未知 id 回退默认皮肤，兼容旧版本偏好。
BoardSkin boardSkinOf(String? id) => kBoardSkins.firstWhere(
  (skin) => skin.id == id,
  orElse: () => kDefaultBoardSkin,
);
