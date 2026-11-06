import 'engine/board_utils.dart';

/// 让子方案：黑棋在天元与星位预置若干子，再由白方先行。
///
/// 让子棋用于强者让弱者：黑方多出的棋子由固定星位预置，白方先走一步。
enum Handicap {
  none('不让子', []),
  one('让一子', [centerIndex]),
  two('让二子', [_d4, _l12]),
  three('让三子', [centerIndex, _d4, _l12]),
  four('让四子', [_d4, _l4, _d12, _l12]);

  const Handicap(this.label, this.points);

  final String label;

  /// 预置黑子的交叉点；不受让时为空。
  final List<int> points;

  bool get enabled => points.isNotEmpty;

  int get count => points.length;

  static Handicap byName(String? name) => values.firstWhere(
    (item) => item.name == name,
    orElse: () => Handicap.none,
  );

  static Handicap byCount(int? count) => values.firstWhere(
    (item) => item.count == count,
    orElse: () => Handicap.none,
  );
}

const int _d4 = 3 * boardSize + 3;
const int _l4 = 3 * boardSize + 11;
const int _d12 = 11 * boardSize + 3;
const int _l12 = 11 * boardSize + 11;
