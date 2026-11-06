import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/move_record.dart';
import '../services/log_service.dart';
import 'ai_player.dart';
import 'board_state.dart';
import 'board_view.dart';
import 'hint_session.dart';

/// 对局与残局控制器共用的棋盘状态与异步生命周期。
///
/// 统一持有提示会话、AI 思考态、请求序号与释放状态：重开、悔棋或发起
/// 新请求时，旧搜索的回包通过 [isCurrent] 丢弃，避免各控制器重复维护
/// 一套标志位。子类只需提供 [board]，棋盘与棋谱的只读状态由这里映射。
abstract class BoardSession extends ChangeNotifier implements BoardView {
  /// 当前棋局；对局控制器持有固定实例，残局控制器在重开时替换。
  GomokuBoard get board;

  @override
  Uint8List get cells => board.cells;

  @override
  List<MoveRecord> get history => board.history;

  @override
  int? get lastIndex => board.lastIndex;

  @override
  List<int> get winningLine => board.winningLine;

  @override
  int get sideToMove => board.sideToMove;

  late final HintSession hint = HintSession(notifyBoard);

  int _serial = 0;
  bool _disposed = false;
  bool _thinking = false;

  @override
  int? get hintIndex => hint.index;

  bool get hintLoading => hint.loading;

  /// AI 是否正在搜索；界面据此禁用落子并展示思考状态。
  bool get thinking => _thinking;

  /// 开始一轮异步操作，返回用于识别回包的序号。
  int beginSerial() => ++_serial;

  /// 回包是否仍然有效；重开、悔棋、新请求或页面释放后返回 false。
  bool isCurrent(int serial) => !_disposed && serial == _serial;

  /// 作废所有尚未完成的异步操作。
  void cancelPending() => _serial++;

  /// 清除提示并取消尚未返回的提示搜索。
  void clearHint({bool notify = true}) => hint.clear(notify: notify);

  /// 进入 AI 回合：清除提示、标记思考中并返回本次请求序号。
  @protected
  int beginThinking() {
    clearHint(notify: false);
    _thinking = true;
    final serial = beginSerial();
    notifyBoard();
    return serial;
  }

  /// 结束 AI 回合；重开、悔棋或终局时由调用方清理。
  @protected
  void endThinking() => _thinking = false;

  /// 执行一次 AI 搜索，统一 Web 首帧让步、异常日志与回包竞态校验。
  ///
  /// 返回 null 表示请求已被重开、悔棋或新请求取代，调用方应直接返回，
  /// 不要复位思考态——新流程已经接管了它。
  @protected
  Future<AiReply?> searchAi({
    required int serial,
    required Future<AiReply> Function() search,
    required String label,
  }) async {
    // Web 端搜索与界面同线程，先让「思考中」完成一帧绘制。
    if (kIsWeb) await Future<void>.delayed(Duration.zero);
    if (!isCurrent(serial)) return null;

    AiReply? reply;
    try {
      reply = await search();
    } catch (error, stack) {
      LogService.error('$label失败', error, stack);
    }
    if (!isCurrent(serial)) return null;
    return reply;
  }

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
