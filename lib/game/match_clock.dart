import '../models/game_models.dart';

/// 对局棋钟：只扣除当前行棋方的剩余时间，扣到 0 即超时。
class MatchClock {
  MatchClock(this.control) : _remaining = [control.millis, control.millis];

  final TimeControl control;

  /// 黑、白双方剩余毫秒，下标为 [side] 减一。
  final List<int> _remaining;
  int? _active;

  int remainingMs(int side) => _remaining[side - 1];

  int? get activeSide => _active;

  bool get isRunning => _active != null;

  void start(int side) => _active = side;

  void stop() => _active = null;

  void reset() {
    _remaining.fillRange(0, _remaining.length, control.millis);
    _active = null;
  }

  /// 扣除当前行棋方 [delta] 的时间，超时返回超时方，否则返回 null。
  int? charge(Duration delta) {
    final active = _active;
    if (active == null) return null;
    final index = active - 1;
    final left = _remaining[index] - delta.inMilliseconds;
    _remaining[index] = left.clamp(0, control.millis);
    if (left > 0) return null;
    _active = null;
    return active;
  }

  /// 落子前的时间快照，供悔棋还原。
  List<int> snapshot() => List.of(_remaining);

  void restore(List<int> snapshot, {required int side}) {
    _remaining.setAll(0, snapshot);
    _active = side;
  }
}

/// 对局计时簿记：把棋钟、真实耗时与每步落子的快照收在一处。
class ClockTracker {
  ClockTracker(TimeControl control) : clock = MatchClock(control);

  final MatchClock clock;

  final Stopwatch _watch = Stopwatch()..start();
  Duration _lastMark = Duration.zero;
  final List<List<int>> _marks = [];

  void resume(int side) {
    _lastMark = _watch.elapsed;
    clock.start(side);
  }

  void stop() {
    _lastMark = _watch.elapsed;
    clock.stop();
  }

  /// 结算当前行棋方从上次结算至今的用时，超时返回超时方。
  int? settle([Duration? elapsed]) {
    if (!clock.isRunning) return null;
    return clock.charge(elapsed ?? _consumeElapsed());
  }

  void mark() => _marks.add(clock.snapshot());

  /// 悔棋到只剩 [keepMoves] 手：还原落子前的时间并交给 [side]。
  void rewind({required int keepMoves, required int side}) {
    while (_marks.length > keepMoves) {
      _marks.removeLast();
    }
    if (_marks.isEmpty) {
      clock.reset();
    } else {
      clock.restore(_marks.last, side: side);
    }
    resume(side);
  }

  void restart(int side) {
    _marks.clear();
    clock.reset();
    resume(side);
  }

  Duration _consumeElapsed() {
    final now = _watch.elapsed;
    final delta = now - _lastMark;
    _lastMark = now;
    return delta;
  }
}
