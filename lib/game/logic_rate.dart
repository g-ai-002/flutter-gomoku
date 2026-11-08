/// 棋盘逻辑更新速率：以固定步长推进落子动画与脉冲，渲染仍按屏幕刷新逐帧绘制。
///
/// 30Hz 更省电，120Hz 更顺滑；默认 60Hz，与主流屏幕刷新保持一致。
enum LogicRate {
  hz30('30 Hz 省电', 30),
  hz60('60 Hz 均衡', 60),
  hz120('120 Hz 顺滑', 120);

  const LogicRate(this.label, this.hz);

  final String label;
  final int hz;

  double get step => 1 / hz;

  /// 未设置或未知值时回退到默认 60Hz。
  static LogicRate byName(String? name) => values.firstWhere(
    (item) => item.name == name,
    orElse: () => LogicRate.hz60,
  );
}

/// 固定步长累加器：把不稳定的渲染帧间隔折算成固定数量的逻辑步。
///
/// 单帧最多补 4 步，切后台或严重卡顿后不会为了追帧一次推进过长时间。
class FixedStepClock {
  FixedStepClock(this.step);

  final double step;
  double _pending = 0;

  static const int _maxSteps = 4;

  /// 消费 [dt] 并回调一次合并后的逻辑步长，返回本帧推进的步数。
  int advance(double dt, void Function(double span) onStep) {
    if (dt <= 0) return 0;
    _pending += dt;
    var steps = 0;
    while (_pending + 1e-9 >= step && steps < _maxSteps) {
      _pending -= step;
      steps++;
    }
    if (steps == 0) return 0;
    onStep(steps * step);
    return steps;
  }
}
