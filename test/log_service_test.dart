import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/services/log_service.dart';

void main() {
  setUp(LogService.reset);
  tearDown(LogService.reset);

  test('日志按天写入用户目录并保留在内存缓冲', () async {
    final dir = await Directory.systemTemp.createTemp('gomoku_log_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    await LogService.init(logRoot: () async => dir);
    LogService.info('对局开始');
    LogService.warning('窗口较小');
    LogService.error('测试异常', StateError('boom'));

    final path = LogService.logFilePath;
    expect(path, contains('app_'));
    final file = File(path);
    expect(await file.exists(), isTrue);
    final content = await file.readAsString();
    expect(content, contains('[INFO] 对局开始'));
    expect(content, contains('[WARN] 窗口较小'));
    expect(content, contains('[ERROR] 测试异常 | Bad state: boom'));

    final recent = LogService.getRecentLogs(20);
    expect(recent.any((line) => line.contains('对局开始')), isTrue);
  });

  test('初始化前的日志会补写进文件', () async {
    final dir = await Directory.systemTemp.createTemp('gomoku_log_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    LogService.info('启动前日志');
    await LogService.init(logRoot: () async => dir);
    await Future<void>.delayed(Duration.zero);
    final content = await File(LogService.logFilePath).readAsString();
    expect(content, contains('启动前日志'));
  });

  test('日志目录不可用时降级为内存模式', () async {
    await LogService.init(
      logRoot: () async => throw const FileSystemException('不可写'),
    );
    LogService.info('内存日志');
    expect(LogService.logFilePath, isEmpty);
    expect(
      LogService.getRecentLogs().any((line) => line.contains('内存日志')),
      isTrue,
    );
  });

  test('最近日志按行数截取', () async {
    final dir = await Directory.systemTemp.createTemp('gomoku_log_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    await LogService.init(logRoot: () async => dir);
    for (var i = 0; i < 30; i++) {
      LogService.info('第 $i 行');
    }
    final lines = LogService.getRecentLogs(10);
    expect(lines.length, lessThanOrEqualTo(10));
    expect(lines.last, contains('第 29 行'));
  });

  test('连续写入超过节流间隔仍完整落盘', () async {
    final dir = await Directory.systemTemp.createTemp('gomoku_log_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    await LogService.init(logRoot: () async => dir);
    for (var i = 0; i < 40; i++) {
      LogService.info('节流第 $i 行');
    }
    final content = await File(LogService.logFilePath).readAsString();
    for (var i = 0; i < 40; i++) {
      expect(content, contains('[INFO] 节流第 $i 行'));
    }
  });
}
