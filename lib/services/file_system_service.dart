import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'log_service.dart';

/// 文件系统服务：提供应用目录访问
class FileSystemService {
  static FileSystemService? _instance;

  static FileSystemService get instance {
    _instance ??= FileSystemService._();
    return _instance!;
  }

  FileSystemService._();

  /// 仅用于测试：重置单例
  static void reset() {
    _instance = null;
  }

  /// 获取日志根目录
  Future<Directory> getLogRoot() async {
    final home = await getApplicationSupportDirectory();
    final logDir = Directory('${home.path}${Platform.pathSeparator}logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    return logDir;
  }

  /// 打开系统文件管理器定位到目录（桌面端），失败返回 false
  Future<bool> openDirectory(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [path]);
        return true;
      }
      if (Platform.isMacOS) {
        await Process.run('open', [path]);
        return true;
      }
      if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
        return true;
      }
    } catch (e) {
      LogService.error('打开目录失败: $path', e);
    }
    return false;
  }
}
