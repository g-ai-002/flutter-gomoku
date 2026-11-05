import '../services/log_service.dart';
import '../services/prefs_collection.dart';
import '../utils/constants.dart';
import 'engine/board_utils.dart';
import 'puzzles.dart';

/// 自定义残局：玩家在编辑器中摆出的固定局面，黑先、限手数成五。
class CustomPuzzle {
  const CustomPuzzle({
    required this.id,
    required this.title,
    required this.moveLimit,
    required this.blackStones,
    required this.whiteStones,
    required this.createdAt,
  });

  static const int maxCount = 30;
  static const int maxMoveLimit = 9;

  final String id;
  final String title;
  final int moveLimit;
  final List<int> blackStones;
  final List<int> whiteStones;
  final DateTime createdAt;

  GomokuPuzzle toPuzzle() => GomokuPuzzle(
    id: id,
    title: title,
    tier: PuzzleTier.expert,
    isCustom: true,
    moveLimit: moveLimit,
    blackStones: blackStones,
    whiteStones: whiteStones,
    tip: '自定义残局：黑先，$moveLimit 手内连成五子。',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'moveLimit': moveLimit,
    'black': blackStones,
    'white': whiteStones,
    'createdAt': createdAt.toIso8601String(),
  };

  /// 字段缺失、坐标越界或黑白重叠时返回 null。
  static CustomPuzzle? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final limit = json['moveLimit'];
    final black = _indices(json['black']);
    final white = _indices(json['white']);
    if (id is! String || id.isEmpty) return null;
    if (title is! String || title.trim().isEmpty || title.length > 20) {
      return null;
    }
    if (limit is! int || limit < 1 || limit > maxMoveLimit) return null;
    if (black == null || white == null || black.isEmpty) return null;
    if (black.toSet().intersection(white.toSet()).isNotEmpty) return null;
    return CustomPuzzle(
      id: id,
      title: title.trim(),
      moveLimit: limit,
      blackStones: black,
      whiteStones: white,
      createdAt:
          DateTime.tryParse('${json['createdAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static List<int>? _indices(Object? value) {
    if (value is! List) return null;
    final result = <int>{};
    for (final item in value) {
      if (item is! int || item < 0 || item >= cellCount) return null;
      result.add(item);
    }
    return result.length == value.length ? result.toList() : null;
  }
}

/// 自定义残局库：内存与 SharedPreferences 双写，最多保留 30 关。
class CustomPuzzleService extends PrefsCollection<CustomPuzzle> {
  CustomPuzzleService._()
    : super(
        key: AppConstants.prefKeyCustomPuzzles,
        label: '自定义残局',
        maxCount: CustomPuzzle.maxCount,
      );

  static final CustomPuzzleService instance = CustomPuzzleService._();

  List<CustomPuzzle> get puzzles => items;

  @override
  String idOf(CustomPuzzle item) => item.id;

  @override
  Object? encode(CustomPuzzle item) => item.toJson();

  @override
  CustomPuzzle? decode(Object? item) =>
      item is Map<String, dynamic> ? CustomPuzzle.fromJson(item) : null;

  @override
  DateTime? dateOf(CustomPuzzle item) => item.createdAt;

  /// 新建或覆盖已有 id 的残局，返回落库后的条目。
  Future<CustomPuzzle> save({
    String? id,
    required String title,
    required int moveLimit,
    required List<int> blackStones,
    required List<int> whiteStones,
  }) async {
    await load();
    final existing = id == null ? null : _find(id);
    final now = DateTime.now();
    final puzzle = CustomPuzzle(
      id:
          existing?.id ??
          'custom_${now.microsecondsSinceEpoch}_${puzzles.length}',
      title: title.trim(),
      moveLimit: moveLimit,
      blackStones: List.unmodifiable(blackStones),
      whiteStones: List.unmodifiable(whiteStones),
      createdAt: existing?.createdAt ?? now,
    );
    LogService.info('自定义残局已保存: ${puzzle.title}');
    await put(puzzle);
    return puzzle;
  }

  Future<void> remove(String id) async {
    if (await removeById(id)) LogService.info('已删除自定义残局: $id');
  }

  CustomPuzzle? _find(String id) {
    for (final puzzle in puzzles) {
      if (puzzle.id == id) return puzzle;
    }
    return null;
  }
}
