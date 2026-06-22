import 'dart:io';
import 'file_system_service.dart';

/// 日志服务：按日期生成日志文件，写入用户目录 logs/ 子目录
class LogService {
  static LogService? _instance;
  File? _logFile;
  bool _initialized = false;

  /// 单个日志文件最大大小（5MB）
  static const int _maxFileSize = 5 * 1024 * 1024;

  /// 日志文件最大保留天数
  static const int _maxRetentionDays = 7;

  LogService._();

  static Future<void> init() async {
    _instance ??= LogService._();
    await _instance!._init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    final dir = await FileSystemService.instance.getLogRoot();
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final file = File('${dir.path}${Platform.pathSeparator}app_$dateStr.log');
    if (!await file.exists()) await file.create();
    _logFile = file;
    _initialized = true;
    _cleanOldLogs(dir);
    _write('INFO', '==== LogService 已初始化, 日志文件: ${file.path} ====');
  }

  /// 清理过期日志文件
  void _cleanOldLogs(Directory dir) {
    try {
      final now = DateTime.now();
      final cutoff = now.subtract(Duration(days: _maxRetentionDays));
      final files = dir.listSync().whereType<File>();
      for (final f in files) {
        final name = f.uri.pathSegments.last;
        if (!name.startsWith('app_') || !name.endsWith('.log')) continue;
        try {
          final stat = f.statSync();
          if (stat.modified.isBefore(cutoff)) {
            f.deleteSync();
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  static void info(String message) => _instance?._write('INFO', message);

  static void warning(String message) => _instance?._write('WARN', message);

  static void error(String message, [Object? error, StackTrace? stack]) {
    final msg = error != null ? '$message | $error' : message;
    _instance?._write('ERROR', msg);
    if (stack != null) _instance?._write('ERROR', stack.toString());
  }

  void _write(String level, String message) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    final line = '[$ts][$level] $message';
    try {
      _rotateIfNeeded();
      _logFile?.writeAsStringSync('$line\n', mode: FileMode.append);
    } catch (_) {
      // 日志写入失败不阻塞应用
    }
  }

  /// 检查是否需要轮转日志文件
  void _rotateIfNeeded() {
    try {
      if (_logFile == null) return;
      if (!_logFile!.existsSync()) return;
      final size = _logFile!.lengthSync();
      if (size < _maxFileSize) return;

      // 文件过大，重命名为带序号的备份
      final parent = _logFile!.parent;
      final baseName = _logFile!.uri.pathSegments.last.replaceAll('.log', '');
      int index = 1;
      File backup;
      do {
        backup = File('${parent.path}${Platform.pathSeparator}${baseName}_$index.log');
        index++;
      } while (backup.existsSync());

      _logFile!.renameSync(backup.path);
      _logFile!.createSync();
    } catch (_) {}
  }

  static Future<String> getLogFilePath() async {
    return _instance?._logFile?.path ?? '';
  }
}
