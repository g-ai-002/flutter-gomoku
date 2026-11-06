import 'package:flutter/material.dart';

/// 棋面配色：黑棋冷润、白棋暖玉，用光影差异强化辨识。
class StoneFace {
  const StoneFace({required this.light, required this.dark, required this.ink});

  final Color light;
  final Color dark;
  final Color ink;
}

/// 棋盘外观：原木底色、线条墨色与最后一手强调色。
const Color kBoardLight = Color(0xFFF4E3C1);
const Color kBoardDark = Color(0xFFE0C391);
const Color kBoardLine = Color(0xFF8A6337);
const Color kBoardAccent = Color(0xFFA63A2B);
const LinearGradient kBoardGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kBoardLight, kBoardDark],
);
const StoneFace kBlackStone = StoneFace(
  light: Color(0xFF5E625C),
  dark: Color(0xFF151714),
  ink: Color(0xFF0A0B0A),
);
const StoneFace kWhiteStone = StoneFace(
  light: Color(0xFFFFFFFF),
  dark: Color(0xFFD9D2C2),
  ink: Color(0xFF8A8274),
);

StoneFace faceOf(int side) => side == 1 ? kBlackStone : kWhiteStone;
