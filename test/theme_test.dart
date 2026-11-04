import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/theme/app_theme.dart';

void main() {
  group('主题与皮肤', () {
    test('三套皮肤 id 唯一且默认回退', () {
      expect(kBoardSkins.length, 3);
      expect(kBoardSkins.map((skin) => skin.id).toSet().length, 3);
      expect(boardSkinOf(null).id, kDefaultBoardSkin.id);
      expect(boardSkinOf('missing').id, kDefaultBoardSkin.id);
      expect(boardSkinOf(jadeSkin.id).id, jadeSkin.id);
    });

    test('皮肤包含黑白棋面与强调色', () {
      for (final skin in kBoardSkins) {
        expect(skin.blackStone.dark.computeLuminance(), lessThan(0.2));
        expect(skin.whiteStone.light.computeLuminance(), greaterThan(0.7));
        expect(skin.accent, isNot(skin.boardLight));
      }
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
