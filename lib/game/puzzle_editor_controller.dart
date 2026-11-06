import 'package:flutter/foundation.dart';

import '../models/move_record.dart';
import 'board_view.dart';
import 'custom_puzzles.dart';
import 'engine/board_utils.dart';
import 'engine/rules.dart';
import 'notation.dart';

/// 残局编辑器状态：点击空点落子、点击棋子移除，实时校验局面。
///
/// 棋盘复用 Flame 棋盘组件，因此这里实现 [BoardView]，
/// 并用 [revision] 通知棋盘丢弃缓存的棋子图层。
class PuzzleEditorController extends ChangeNotifier implements BoardView {
  PuzzleEditorController({this.initial, int brush = black, int moveLimit = 3})
    : brush = brush == white ? white : black,
      moveLimit = moveLimit.clamp(1, CustomPuzzle.maxMoveLimit) {
    final source = initial;
    if (source == null) return;
    this.moveLimit = source.moveLimit;
    for (final index in source.blackStones) {
      cells[index] = black;
    }
    for (final index in source.whiteStones) {
      cells[index] = white;
    }
    for (final side in cells) {
      if (side == black) {
        _blackCount++;
      } else if (side == white) {
        _whiteCount++;
      }
    }
    _rebuildHistory();
  }

  final CustomPuzzle? initial;
  @override
  final Uint8List cells = emptyCells();
  final List<MoveRecord> _history = [];

  int brush;
  int moveLimit;
  int _revision = 0;
  int _blackCount = 0;
  int _whiteCount = 0;
  bool _invalidDirty = true;
  String? _invalidReason;

  bool get isEditing => initial != null;

  int get blackCount => _blackCount;

  int get whiteCount => _whiteCount;

  List<int> get blackStones => _indices(black);

  List<int> get whiteStones => _indices(white);

  /// 至少一枚黑棋，且局面中不能已经存在五连。
  ///
  /// 结果按修改版本缓存：面板每帧读取时不会重复扫描全盘。
  String? get invalidReason {
    if (!_invalidDirty) return _invalidReason;
    _invalidDirty = false;
    if (_blackCount == 0) {
      _invalidReason = '请至少摆放一枚黑棋';
    } else {
      _invalidReason = GomokuRules.hasAnyFive(cells) ? '局面中已经有五连，请调整棋子' : null;
    }
    return _invalidReason;
  }

  @override
  List<MoveRecord> get history => _history;

  @override
  int? get lastIndex => _history.isEmpty ? null : _history.last.index;

  @override
  List<int> get winningLine => const [];

  @override
  int? get hintIndex => null;

  @override
  Set<int> get forbiddenPoints => const {};

  @override
  bool get showCoordinates => true;

  @override
  bool get canInteract => true;

  @override
  int get sideToMove => brush;

  @override
  int get revision => _revision;

  @override
  bool get allowsReplace => true;

  void setBrush(int side) {
    if ((side != black && side != white) || brush == side) return;
    brush = side;
    notifyListeners();
  }

  void setMoveLimit(int value) {
    final next = value.clamp(1, CustomPuzzle.maxMoveLimit);
    if (next == moveLimit) return;
    moveLimit = next;
    notifyListeners();
  }

  void clear() {
    cells.fillRange(0, cellCount, empty);
    _history.clear();
    _blackCount = 0;
    _whiteCount = 0;
    _revision++;
    _invalidDirty = true;
    notifyListeners();
  }

  @override
  void tapCell(int index) {
    if (index < 0 || index >= cellCount) return;
    final current = cells[index];
    if (current != empty) {
      cells[index] = empty;
      if (current == black) {
        _blackCount--;
      } else {
        _whiteCount--;
      }
      _rebuildHistory();
    } else {
      cells[index] = brush;
      if (brush == black) {
        _blackCount++;
      } else {
        _whiteCount++;
      }
      _history.add(_record(index, brush));
    }
    _revision++;
    _invalidDirty = true;
    notifyListeners();
  }

  List<int> _indices(int side) => [
    for (var index = 0; index < cellCount; index++)
      if (cells[index] == side) index,
  ];

  /// 移除棋子后重新生成着法记录，保证棋盘的悬停与计数始终一致。
  void _rebuildHistory() {
    _history.clear();
    for (var index = 0; index < cellCount; index++) {
      final side = cells[index];
      if (side != empty) _history.add(_record(index, side));
    }
  }

  MoveRecord _record(int index, int side) => MoveRecord(
    index: index,
    side: side,
    notation: MoveNotation.describe(index),
    moveNumber: _history.length + 1,
  );
}
