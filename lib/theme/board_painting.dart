import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'board_skin.dart';

/// 中文书法字体样式：桌面端优先系统楷体，Web 端使用 soup_fonts 思源黑体。
TextStyle pieceTextStyle({
  required double fontSize,
  required Color color,
  FontWeight fontWeight = FontWeight.w700,
  double height = 1,
}) => TextStyle(
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  fontFamily: kIsWeb ? kWebFontFamily : 'KaiTi',
  fontFamilyFallback: kIsWeb ? null : kKaiFontFallback,
  height: height,
);

/// 星位：15 路棋盘的五个天元与星位。
const List<(int, int)> kStarPoints = [
  (3, 3),
  (3, 11),
  (7, 7),
  (11, 3),
  (11, 11),
];

/// 绘制棋盘网格与外框，[topLeft] 为左上角交叉点，[cell] 为格宽。
void paintBoardGrid(
  Canvas canvas, {
  required Offset topLeft,
  required double cell,
  required Paint linePaint,
  Paint? starPaint,
  Paint? borderPaint,
  bool stars = true,
}) {
  final left = topLeft.dx;
  final top = topLeft.dy;
  final right = left + cell * 14;
  final bottom = top + cell * 14;

  for (var index = 0; index < 15; index++) {
    final offset = index * cell;
    canvas.drawLine(
      Offset(left, top + offset),
      Offset(right, top + offset),
      linePaint,
    );
    canvas.drawLine(
      Offset(left + offset, top),
      Offset(left + offset, bottom),
      linePaint,
    );
  }

  if (borderPaint != null) {
    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), borderPaint);
  }

  if (!stars) return;
  final paint = starPaint ?? linePaint;
  for (final (row, col) in kStarPoints) {
    canvas.drawCircle(
      Offset(left + col * cell, top + row * cell),
      cell * 0.085,
      paint,
    );
  }
}

/// 绘制一枚棋子：投影、棋面渐变、外圈与高光。
///
/// Flame 棋盘与首页缩略图共用同一套棋子质感。
void paintStoneDisc(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required StoneFace face,
  double opacity = 1,
  bool highlight = true,
}) {
  // 用两层半透明圆代替模糊投影：Web 上逐子高斯模糊开销过高。
  canvas.drawCircle(
    center.translate(0, radius * 0.10),
    radius * 1.02,
    Paint()..color = Colors.black.withValues(alpha: 0.16 * opacity),
  );
  canvas.drawCircle(
    center.translate(0, radius * 0.05),
    radius * 1.01,
    Paint()..color = Colors.black.withValues(alpha: 0.10 * opacity),
  );
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.38, -0.45),
        radius: 0.95,
        colors: [
          face.light.withValues(alpha: opacity),
          face.dark.withValues(alpha: opacity),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius)),
  );
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..color = face.ink.withValues(alpha: 0.55 * opacity),
  );
  if (!highlight) return;
  canvas.drawCircle(
    center.translate(-radius * 0.28, -radius * 0.32),
    radius * 0.30,
    Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.34 * opacity),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: center.translate(-radius * 0.28, -radius * 0.32),
              radius: radius * 0.30,
            ),
          ),
  );
}
