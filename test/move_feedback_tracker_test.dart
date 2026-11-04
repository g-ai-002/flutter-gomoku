import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/board_view.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/models/move_record.dart';
import 'package:gomoku/services/move_feedback_tracker.dart';
import 'package:gomoku/services/sound_service.dart';

class _FakeView implements BoardView {
  _FakeView(this.cells, this.history);

  @override
  Uint8List cells;

  @override
  List<MoveRecord> history;

  @override
  int? get hintIndex => null;

  @override
  int? get lastIndex => history.isEmpty ? null : history.last.index;

  @override
  List<int> get winningLine => const [];

  @override
  bool get showCoordinates => true;

  @override
  Set<int> get forbiddenPoints => const {};

  @override
  bool get canInteract => true;

  @override
  int get sideToMove => black;

  @override
  void tapCell(int index) {}
}

MoveRecord _move(int index, int side, int number) => MoveRecord(
  index: index,
  side: side,
  notation: '${rowOf(index)}-${colOf(index)}',
  moveNumber: number,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MoveFeedback> played;

  setUp(() {
    played = [];
    SoundService.reset();
    SoundService.hapticsEnabled = false;
    SoundService.sink = played.add;
  });

  tearDown(SoundService.reset);

  test('新增落子播放落子音', () {
    final cells = emptyCells();
    final index = indexOf(7, 7);
    cells[index] = black;
    final tracker = MoveFeedbackTracker(
      _FakeView(cells, [_move(index, black, 1)]),
    );

    tracker.sync();
    expect(played, [MoveFeedback.place]);
  });

  test('形成活四时播放威胁提示音', () {
    final cells = emptyCells();
    for (var col = 4; col <= 7; col++) {
      cells[indexOf(7, col)] = black;
    }
    final last = indexOf(7, 7);
    final tracker = MoveFeedbackTracker(
      _FakeView(cells, [_move(last, black, 1)]),
    );

    tracker.sync();
    expect(played, [MoveFeedback.threat]);
  });

  test('棋谱缩短时只对齐游标，不补放音效', () {
    final cells = emptyCells();
    cells[indexOf(7, 7)] = black;
    final history = [_move(indexOf(7, 7), black, 1)];
    final tracker = MoveFeedbackTracker(_FakeView(cells, history));

    tracker.sync();
    expect(played, [MoveFeedback.place]);

    history.clear();
    tracker.sync();
    expect(played, [MoveFeedback.place]);
  });

  test('重开后首手重新播放反馈', () {
    final cells = emptyCells();
    final history = <MoveRecord>[];
    final tracker = MoveFeedbackTracker(_FakeView(cells, history));

    tracker.sync();
    expect(played, isEmpty);

    tracker.reset();
    final index = indexOf(7, 7);
    cells[index] = black;
    history.add(_move(index, black, 1));
    tracker.sync();
    expect(played, [MoveFeedback.place]);
  });
}
