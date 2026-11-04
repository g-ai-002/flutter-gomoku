import 'dart:async';

import 'package:flutter/foundation.dart';

/// 走子提示的生命周期：请求序号、加载态、高亮点与自动清除。
///
/// 对局与残局控制器共用这套状态，避免各自维护定时器与请求竞态：
/// 悔棋、重开或发起新请求后，旧搜索的回包会被 [isCurrent] 丢弃。
class HintSession {
  HintSession(
    this._onChanged, {
    this.displayDuration = const Duration(seconds: 6),
  });

  final VoidCallback _onChanged;
  final Duration displayDuration;

  int? index;
  bool loading = false;

  int _serial = 0;
  Timer? _timer;
  bool _disposed = false;

  /// 开始一次异步搜索：清空高亮、标记加载中，并返回本次请求序号。
  int begin() {
    _serial++;
    _timer?.cancel();
    _timer = null;
    loading = true;
    index = null;
    _onChanged();
    return _serial;
  }

  /// 请求是否仍然有效；已撤销、重开或已被新请求取代时返回 false。
  bool isCurrent(int serial) => !_disposed && serial == _serial;

  /// 执行一次提示搜索：处理加载态、Web 首帧让步、回包竞态与合法着法校验。
  ///
  /// 返回展示的交叉点；搜索无结果、回包非法或请求已被取消时返回 null。
  /// 搜索异常交给 [onError] 记录，避免各控制器重复一套 try/catch。
  Future<int?> request(
    Future<int?> Function() search, {
    required bool Function(int move) isValid,
    void Function(Object error, StackTrace stack)? onError,
  }) async {
    final serial = begin();
    // Web 端搜索与界面同线程，先让「正在寻找提示」完成一帧绘制。
    if (kIsWeb) await Future<void>.delayed(Duration.zero);
    if (!isCurrent(serial)) return null;

    int? move;
    try {
      move = await search();
    } catch (error, stack) {
      onError?.call(error, stack);
    }
    if (!isCurrent(serial)) return null;

    if (move != null && isValid(move)) {
      show(move);
      return move;
    }
    finish();
    return null;
  }

  /// 展示推荐点并启动自动清除。
  void show(int move) {
    loading = false;
    index = move;
    _timer?.cancel();
    _timer = Timer(displayDuration, clear);
    _onChanged();
  }

  /// 搜索结束但没有可用着法时，仅结束加载态。
  void finish() {
    loading = false;
    _onChanged();
  }

  /// 取消尚未返回的请求并清除高亮。
  void clear({bool notify = true}) {
    _serial++;
    _timer?.cancel();
    _timer = null;
    loading = false;
    index = null;
    if (notify) _onChanged();
  }

  void dispose() {
    _disposed = true;
    _serial++;
    _timer?.cancel();
    _timer = null;
  }
}
