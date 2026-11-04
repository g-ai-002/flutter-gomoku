import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/engine/board_utils.dart';
import 'package:gomoku/game/match_clock.dart';
import 'package:gomoku/models/game_models.dart';

void main() {
  group('棋钟', () {
    test('只扣除当前行棋方的剩余时间', () {
      final clock = MatchClock(TimeControl.blitz);
      clock.start(black);
      expect(clock.charge(const Duration(seconds: 1)), isNull);
      expect(clock.remainingMs(black), 299000);
      expect(clock.remainingMs(white), 300000);

      clock.start(white);
      expect(clock.charge(const Duration(seconds: 2)), isNull);
      expect(clock.remainingMs(white), 298000);
      expect(clock.remainingMs(black), 299000);
    });

    test('扣到零返回超时方并停表', () {
      final clock = MatchClock(TimeControl.blitz);
      clock.start(white);
      expect(clock.charge(const Duration(minutes: 5)), white);
      expect(clock.remainingMs(white), 0);
      expect(clock.isRunning, isFalse);
    });

    test('快照与恢复', () {
      final clock = MatchClock(TimeControl.rapid);
      clock.start(black);
      clock.charge(const Duration(seconds: 10));
      final snapshot = clock.snapshot();
      clock.charge(const Duration(seconds: 30));
      clock.restore(snapshot, side: white);
      expect(clock.remainingMs(black), 590000);
      expect(clock.remainingMs(white), 600000);
      expect(clock.activeSide, white);
    });

    test('重开清零双方时间', () {
      final clock = MatchClock(TimeControl.blitz);
      clock.start(black);
      clock.charge(const Duration(seconds: 20));
      clock.reset();
      expect(clock.remainingMs(black), 300000);
      expect(clock.remainingMs(white), 300000);
      expect(clock.isRunning, isFalse);
    });
  });

  group('计时簿记', () {
    test('落子快照与悔棋还原', () {
      final tracker = ClockTracker(TimeControl.blitz);
      tracker.resume(black);
      expect(tracker.settle(const Duration(seconds: 1)), isNull);
      tracker.mark();
      tracker.resume(white);
      expect(tracker.settle(const Duration(seconds: 2)), isNull);
      tracker.mark();

      tracker.rewind(keepMoves: 0, side: black);
      expect(tracker.clock.remainingMs(black), 300000);
      expect(tracker.clock.remainingMs(white), 300000);
      expect(tracker.clock.activeSide, black);
    });

    test('重开清空历史快照', () {
      final tracker = ClockTracker(TimeControl.blitz);
      tracker.resume(black);
      tracker.settle(const Duration(seconds: 3));
      tracker.mark();
      tracker.restart(white);
      expect(tracker.clock.remainingMs(black), 300000);
      expect(tracker.clock.activeSide, white);
    });
  });
}
