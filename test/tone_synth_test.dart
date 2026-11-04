import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/services/sound_service.dart';
import 'package:gomoku/services/tone_synth.dart';

String _ascii(List<int> bytes, int offset, int length) =>
    String.fromCharCodes(bytes.sublist(offset, offset + length));

void main() {
  tearDown(SoundService.reset);

  group('音效合成', () {
    test('输出合法的 16 位单声道 WAV', () {
      final wav = synthesizeWav([
        const SynthNote(frequency: 880, start: 0, duration: 0.1),
      ]);
      expect(_ascii(wav, 0, 4), 'RIFF');
      expect(_ascii(wav, 8, 4), 'WAVE');
      expect(_ascii(wav, 12, 4), 'fmt ');
      expect(wav.length, greaterThan(1000));
      // 采样率 22050，单声道，16 位。
      expect(wav[24] | (wav[25] << 8), kSynthSampleRate);
      expect(wav[22], 1);
      expect(wav[34], 16);
    });

    test('四种落子反馈的音频互不相同', () {
      final clips = {
        for (final feedback in MoveFeedback.values)
          feedback: SoundService.clipOf(feedback),
      };
      for (final bytes in clips.values) {
        expect(_ascii(bytes, 0, 4), 'RIFF');
      }
      final unique = clips.values.map((bytes) => bytes.join(',')).toSet();
      expect(unique.length, MoveFeedback.values.length);
    });

    test('背景音乐为固定长度循环', () {
      final music = synthesizeMusicWav();
      expect(_ascii(music, 0, 4), 'RIFF');
      final expectedSamples = (kMusicLoopSeconds * kMusicSampleRate).round();
      expect(music.length, 44 + expectedSamples * 2);
      expect(music.length, greaterThan(400000));
    });
  });
}
