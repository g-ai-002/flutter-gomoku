import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/services/prefs_json.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('读写与清空 JSON 数组', () async {
    final store = PrefsJson(key: 'test_list', label: '测试数据');
    expect(await store.read<int>(_asInt), isNull);

    await store.write([1, 2, 3]);
    expect(await store.read<int>(_asInt), [1, 2, 3]);

    await store.clear();
    expect(await store.read<int>(_asInt), isNull);
  });

  test('非数组内容视为损坏并返回 null', () async {
    SharedPreferences.setMockInitialValues({'test_list': '{"a":1}'});
    final store = PrefsJson(key: 'test_list', label: '测试数据');
    expect(await store.read<int>(_asInt), isNull);
  });

  test('单条解码异常被隔离，其余条目正常读取', () async {
    SharedPreferences.setMockInitialValues({'test_list': '[1, "坏数据", 2, 3]'});
    final store = PrefsJson(key: 'test_list', label: '测试数据');
    final values = await store.read<int>((item) {
      if (item == 2) throw StateError('坏条目');
      return _asInt(item);
    });
    expect(values, [1, 3]);
  });

  test('重置缓存后读取新的 mock 数据', () async {
    final store = PrefsJson(key: 'test_list', label: '测试数据');
    await store.write([1]);
    expect(await store.read<int>(_asInt), [1]);

    SharedPreferences.setMockInitialValues({'test_list': '[2]'});
    store.resetCache();
    expect(await store.read<int>(_asInt), [2]);
  });
}

int? _asInt(Object? item) => item is int ? item : null;
