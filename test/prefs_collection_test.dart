import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/services/prefs_collection.dart';
import 'package:gomoku/services/prefs_json.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _key = 'test_collection';

/// 读取有延迟的偏好存储，用于覆盖「加载未完成时写入」的竞态。
class _SlowPrefsJson extends PrefsJson {
  _SlowPrefsJson() : super(key: _key, label: '测试集合');

  @override
  Future<List<T>?> read<T>(T? Function(Object? item) decode) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return super.read<T>(decode);
  }
}

class _StringCollection extends PrefsCollection<String> {
  _StringCollection(PrefsJson store, {super.maxCount = 0})
    : super(key: _key, label: '测试集合', store: store);

  Future<void> add(String value) => put(value);

  Future<bool> removeItem(String value) => removeById(value);

  Future<void> clearAllItems() => clearAll();

  @override
  String idOf(String item) => item;

  @override
  Object? encode(String item) => item;

  @override
  String? decode(Object? item) => item is String ? item : null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      _key: '["disk_1","disk_2"]',
    });
  });

  test('加载未完成时写入会等待并合并磁盘数据', () async {
    final collection = _StringCollection(_SlowPrefsJson());

    final loading = collection.load();
    final adding = collection.add('local');
    await Future.wait([loading, adding]);

    expect(collection.items, ['local', 'disk_1', 'disk_2']);
  });

  test('重复 id 覆盖而不是新增，超出上限丢弃最旧条目', () async {
    final collection = _StringCollection(
      PrefsJson(key: _key, label: '测试集合'),
      maxCount: 3,
    );

    await collection.add('disk_1');
    expect(collection.items, ['disk_1', 'disk_2']);

    await collection.add('disk_3');
    expect(collection.items, ['disk_3', 'disk_1', 'disk_2']);

    await collection.add('disk_4');
    expect(collection.items, ['disk_4', 'disk_3', 'disk_1']);
  });

  test('删除与清空同步落盘', () async {
    final collection = _StringCollection(PrefsJson(key: _key, label: '测试集合'));

    expect(await collection.removeItem('disk_1'), isTrue);
    expect(await collection.removeItem('missing'), isFalse);
    expect(collection.items, ['disk_2']);

    await collection.clearAllItems();
    expect(collection.items, isEmpty);

    final reloaded = _StringCollection(
      PrefsJson(key: _key, label: '测试集合'),
    );
    await reloaded.load();
    expect(reloaded.items, isEmpty);
  });

  test('上限为零时不裁剪', () async {
    final collection = _StringCollection(
      PrefsJson(key: _key, label: '测试集合'),
    );
    await collection.add('a');
    await collection.add('b');
    await collection.add('c');
    expect(collection.items, ['c', 'b', 'a', 'disk_1', 'disk_2']);
  });

  test('旧加载完成后不会覆盖重置后的空状态', () async {
    final collection = _StringCollection(_SlowPrefsJson());
    final loading = collection.load();
    collection.resetForTest();
    await loading;
    expect(collection.items, isEmpty);
    expect(collection.isEmpty, isTrue);
  });
}
