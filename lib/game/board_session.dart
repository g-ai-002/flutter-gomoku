import 'package:flutter/foundation.dart';

import 'board_view.dart';
import 'hint_session.dart';

/// 对局与残局控制器共用的异步生命周期。
///
/// 统一持有提示会话、请求序号与释放状态：重开、悔棋或发起新请求时，
/// 旧搜索的回包通过 [isCurrent] 丢弃，避免各控制器重复维护一套标志位。
abstract class BoardSession extends ChangeNotifier implements BoardView {
  late final HintSession hint = HintSession(notifyBoard);

  int _serial = 0;
  bool _disposed = false;

  @override
  int? get hintIndex => hint.index;

  bool get hintLoading => hint.loading;

  /// 开始一轮异步操作，返回用于识别回包的序号。
  int beginSerial() => ++_serial;

  /// 回包是否仍然有效；重开、悔棋、新请求或页面释放后返回 false。
  bool isCurrent(int serial) => !_disposed && serial == _serial;

  /// 作废所有尚未完成的异步操作。
  void cancelPending() => _serial++;

  /// 清除提示并取消尚未返回的提示搜索。
  void clearHint({bool notify = true}) => hint.clear(notify: notify);

  /// 仅在页面仍挂载时通知界面。
  @protected
  void notifyBoard() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _serial++;
    hint.dispose();
    super.dispose();
  }
}
