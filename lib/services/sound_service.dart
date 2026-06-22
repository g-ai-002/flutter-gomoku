import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';

/// 音效服务：程序化生成音效，无需外部音频资源
class SoundService {
  static const int _sampleRate = 22050;

  SoundService._();

  /// 生成 WAV 字节数据
  static Uint8List _generateWav(List<double> samples) {
    final data = Int16List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      data[i] = (samples[i] * 32767).clamp(-32767, 32767).toInt();
    }

    final byteData = ByteData(44 + data.length * 2);
    int offset = 0;

    void writeStr(String s) {
      for (int i = 0; i < s.length; i++) {
        byteData.setUint8(offset++, s.codeUnitAt(i));
      }
    }

    writeStr('RIFF');
    byteData.setUint32(offset, 36 + data.length * 2, Endian.little);
    offset += 4;
    writeStr('WAVE');
    writeStr('fmt ');
    byteData.setUint32(offset, 16, Endian.little);
    offset += 4;
    byteData.setUint16(offset, 1, Endian.little);
    offset += 2;
    byteData.setUint16(offset, 1, Endian.little);
    offset += 2;
    byteData.setUint32(offset, _sampleRate, Endian.little);
    offset += 4;
    byteData.setUint32(offset, _sampleRate * 2, Endian.little);
    offset += 4;
    byteData.setUint16(offset, 2, Endian.little);
    offset += 2;
    byteData.setUint16(offset, 16, Endian.little);
    offset += 2;
    writeStr('data');
    byteData.setUint32(offset, data.length * 2, Endian.little);
    offset += 4;

    for (int i = 0; i < data.length; i++) {
      byteData.setInt16(offset, data[i], Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  /// 生成正弦波采样
  static List<double> _tone(double freq, double durationMs, {double volume = 0.3}) {
    final count = (_sampleRate * durationMs / 1000).round();
    final samples = <double>[];
    for (int i = 0; i < count; i++) {
      final t = i / _sampleRate;
      final envelope = 1.0 - (i / count);
      samples.add(sin(2 * pi * freq * t) * volume * envelope);
    }
    return samples;
  }

  /// 落子音效
  static Future<void> playPlaceStone() async {
    final samples = _tone(880, 40, volume: 0.25);
    final wav = _generateWav(samples);
    await SystemChannels.platform.invokeMethod('SystemSound.play', wav);
  }

  /// 获胜音效
  static Future<void> playWin() async {
    final notes = [523.0, 659.0, 784.0, 1047.0]; // C5 E5 G5 C6
    final allSamples = <double>[];
    for (final freq in notes) {
      allSamples.addAll(_tone(freq, 120, volume: 0.3));
      allSamples.addAll(List.filled((_sampleRate * 0.03).round(), 0.0));
    }
    final wav = _generateWav(allSamples);
    await SystemChannels.platform.invokeMethod('SystemSound.play', wav);
  }
}
