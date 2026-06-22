import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gomoku/utils/constants.dart';

void main() {
  group('AppConstants', () {
    test('应用名称', () {
      expect(AppConstants.appName, equals('五子棋'));
    });

    test('版本号', () {
      expect(AppConstants.version, equals('0.3.0'));
    });

    test('默认棋盘大小', () {
      expect(AppConstants.defaultBoardSize, equals(15));
    });

    test('棋盘大小范围', () {
      expect(AppConstants.minBoardSize, equals(9));
      expect(AppConstants.maxBoardSize, equals(19));
    });
  });
}
