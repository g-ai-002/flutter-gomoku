import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/game/hint_session.dart';

void main() {
  test('清除提示后旧请求序号失效', () {
    var changes = 0;
    final session = HintSession(() => changes++);
    final serial = session.begin();

    expect(session.loading, isTrue);
    expect(session.index, isNull);
    expect(session.isCurrent(serial), isTrue);
    expect(changes, 1);

    session.clear(notify: false);
    expect(session.isCurrent(serial), isFalse);
    expect(session.loading, isFalse);
    expect(changes, 1);
    session.dispose();
  });

  test('展示提示后自动清除高亮', () async {
    var changes = 0;
    final session = HintSession(
      () => changes++,
      displayDuration: const Duration(milliseconds: 10),
    );

    session.show(42);
    expect(session.index, 42);
    expect(session.loading, isFalse);
    expect(changes, 1);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(session.index, isNull);
    expect(changes, 2);
    session.dispose();
  });

  test('搜索无结果时只结束加载态', () {
    var changes = 0;
    final session = HintSession(() => changes++);
    session.begin();
    session.finish();

    expect(session.loading, isFalse);
    expect(session.index, isNull);
    expect(changes, 2);
    session.dispose();
  });

  test('销毁后取消定时器且不再接受旧请求', () async {
    var changes = 0;
    final session = HintSession(
      () => changes++,
      displayDuration: const Duration(milliseconds: 10),
    );
    final serial = session.begin();
    session.dispose();

    expect(session.isCurrent(serial), isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(changes, 1);
  });

  test('请求返回合法着法后展示并结束加载', () async {
    final session = HintSession(() {});
    final move = await session.request(
      () async => 42,
      isValid: (value) => value == 42,
    );

    expect(move, 42);
    expect(session.index, 42);
    expect(session.loading, isFalse);
    session.dispose();
  });

  test('请求返回非法着法时只结束加载态', () async {
    final session = HintSession(() {});
    final move = await session.request(() async => 8, isValid: (_) => false);

    expect(move, isNull);
    expect(session.index, isNull);
    expect(session.loading, isFalse);
    session.dispose();
  });

  test('搜索异常交给回调且不保留高亮', () async {
    Object? captured;
    final session = HintSession(() {});
    final move = await session.request(
      () async => throw StateError('搜索失败'),
      isValid: (_) => true,
      onError: (error, _) => captured = error,
    );

    expect(move, isNull);
    expect(captured, isA<StateError>());
    expect(session.loading, isFalse);
    session.dispose();
  });

  test('请求进行中清除提示后丢弃迟到回包', () async {
    final completer = Completer<int?>();
    final session = HintSession(() {});
    final pending = session.request(
      () => completer.future,
      isValid: (_) => true,
    );
    session.clear(notify: false);
    completer.complete(9);

    expect(await pending, isNull);
    expect(session.index, isNull);
    expect(session.loading, isFalse);
    session.dispose();
  });
}
