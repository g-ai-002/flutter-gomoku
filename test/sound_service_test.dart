import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gomoku/services/sound_service.dart';

void main() {
  group('SoundService', () {
    test('落子音效不抛异常', () async {
      // 音效通过 SystemChannels 播放，在测试环境静默失败
      await SoundService.playPlaceStone();
    });

    test('获胜音效不抛异常', () async {
      await SoundService.playWin();
    });
  });
}
