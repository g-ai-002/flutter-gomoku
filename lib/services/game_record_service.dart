import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/game_record.dart';
import 'log_service.dart';

/// 对局记录服务：保存/加载对局历史
class GameRecordService {
  static final GameRecordService instance = GameRecordService._();
  GameRecordService._();

  Directory? _recordsDir;

  Future<Directory> get _dir async {
    if (_recordsDir != null) return _recordsDir!;
    try {
      final appDir = await getApplicationSupportDirectory();
      _recordsDir = Directory('${appDir.path}${Platform.pathSeparator}records');
      if (!await _recordsDir!.exists()) {
        await _recordsDir!.create(recursive: true);
      }
    } catch (e) {
      LogService.warning('无法创建对局记录目录: $e');
      rethrow;
    }
    return _recordsDir!;
  }

  /// 保存对局记录
  Future<void> save(GameRecord record) async {
    try {
      final dir = await _dir;
      final file = File('${dir.path}${Platform.pathSeparator}${record.id}.json');
      await file.writeAsString(record.toJsonString());
      LogService.info('对局记录已保存: ${record.id}');
    } catch (e) {
      LogService.error('保存对局记录失败', e);
    }
  }

  /// 加载所有对局记录（按日期倒序）
  Future<List<GameRecord>> loadAll() async {
    try {
      final dir = await _dir;
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      final records = <GameRecord>[];
      for (final file in files) {
        try {
          final content = await file.readAsString();
          records.add(GameRecord.fromJsonString(content));
        } catch (e) {
          LogService.warning('解析对局记录失败: ${file.path}');
        }
      }

      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (e) {
      LogService.error('加载对局记录失败', e);
      return [];
    }
  }

  /// 删除对局记录
  Future<void> delete(String id) async {
    try {
      final dir = await _dir;
      final file = File('${dir.path}${Platform.pathSeparator}$id.json');
      if (await file.exists()) {
        await file.delete();
        LogService.info('对局记录已删除: $id');
      }
    } catch (e) {
      LogService.error('删除对局记录失败', e);
    }
  }

  /// 获取对局记录数量
  Future<int> count() async {
    try {
      final dir = await _dir;
      final files =
          dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
      return files.length;
    } catch (_) {
      return 0;
    }
  }
}
