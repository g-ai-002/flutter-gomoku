import '../utils/constants.dart';
import 'log_service.dart';
import 'prefs_collection.dart';

/// 残局通关记录：只保存已通关的关卡 id，读写失败不影响挑战流程。
class PuzzleProgressService extends PrefsCollection<String> {
  PuzzleProgressService._()
    : super(key: AppConstants.prefKeyPuzzleProgress, label: '残局进度');

  static final PuzzleProgressService instance = PuzzleProgressService._();

  int get solvedCount => items.length;

  bool isSolved(String id) => containsId(id);

  @override
  String idOf(String item) => item;

  @override
  Object? encode(String item) => item;

  @override
  String? decode(Object? item) => item is String ? item : null;

  Future<void> markSolved(String id) async {
    await load();
    if (containsId(id)) return;
    LogService.info('残局进度已更新: $id（共 ${items.length + 1} 关）');
    await put(id);
  }

  /// 删除自定义残局时同步移除它的通关记录。
  Future<void> forget(String id) async {
    if (await removeById(id)) LogService.info('残局进度已移除: $id');
  }

  Future<void> clear() => clearAll();
}
