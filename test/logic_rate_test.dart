import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/logic_rate.dart';

void main() {
  test('逻辑更新速率提供 30/60/120Hz，默认 60Hz', () {
    expect(LogicRate.values.map((rate) => rate.hz), [30, 60, 120]);
    expect(LogicRate.byName(null), LogicRate.hz60);
    expect(LogicRate.byName('hz120'), LogicRate.hz120);
    expect(LogicRate.byName('unknown'), LogicRate.hz60);
  });

  test('30Hz 下每两帧渲染推进一次逻辑步', () {
    final clock = FixedStepClock(LogicRate.hz30.step);
    var span = 0.0;

    expect(clock.advance(1 / 60, (value) => span = value), 0);
    expect(clock.advance(1 / 60, (value) => span = value), 1);
    expect(span, closeTo(1 / 30, 1e-9));
  });

  test('120Hz 下单帧渲染可推进两步', () {
    final clock = FixedStepClock(LogicRate.hz120.step);
    var span = 0.0;

    expect(clock.advance(1 / 60, (value) => span = value), 2);
    expect(span, closeTo(1 / 60, 1e-9));
  });

  test('卡顿后单帧最多补 4 步，不一次追平长时间', () {
    final clock = FixedStepClock(LogicRate.hz60.step);
    expect(clock.advance(1.0, (_) {}), 4);
  });

  test('零或负的帧间隔不推进逻辑', () {
    final clock = FixedStepClock(LogicRate.hz60.step);
    expect(clock.advance(0, (_) {}), 0);
    expect(clock.advance(-0.1, (_) {}), 0);
  });
}
