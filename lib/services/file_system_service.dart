import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 文件系统服务：提供应用目录访问
class FileSystemService {
  static FileSystemService? _instance;

  FileSystemService._();

  static FileSystemService get instance {
    _instance ??= FileSystemService._();
    return _instance!;
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
}
