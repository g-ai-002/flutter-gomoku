import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/theme/app_theme.dart';

void main() {
  group('主题与棋盘', () {
    test('默认皮肤包含黑白棋面与强调色', () {
      expect(kBlackStone.dark.computeLuminance(), lessThan(0.2));
      expect(kWhiteStone.light.computeLuminance(), greaterThan(0.7));
      expect(kBoardAccent, isNot(kBoardLight));
    });

    test('浅色与深色主题亮度正确', () {
      expect(buildLightTheme().brightness, Brightness.light);
      expect(buildDarkTheme().brightness, Brightness.dark);
      expect(
        buildLightTheme().scaffoldBackgroundColor,
        const Color(0xFFF7F1E4),
      );
      expect(buildDarkTheme().scaffoldBackgroundColor, const Color(0xFF17140F));
    });

    test('主题支持自定义字体', () {
      final theme = buildLightTheme(fontFamily: 'Microsoft YaHei UI');
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Microsoft YaHei UI');
    });
  });
}
