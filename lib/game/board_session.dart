import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/log_service.dart';
import 'ai_player.dart';
import 'board_state.dart';
import 'board_view_adapter.dart';
import 'engine/board_utils.dart';
import 'hint_session.dart';
import 'notation.dart';

/// 对局与残局控制器共用的棋盘状态与异步生命周期。
///
/// 统一持有提示会话、AI 思考态、请求序号与释放状态：重开、悔棋或发起
/// 新请求时，旧搜索的回包通过 [isCurrent] 丢弃，避免各控制器重复维护
/// 一套标志位。子类只需提供 [board]，棋盘与棋谱的只读状态由这里映射。
abstract class BoardSession extends ChangeNotifier with BoardViewAdapter {
  /// 当前棋局；对局控制器持有固定实例，残局控制器在重开时替换。
  @override
  GomokuBoard get board;

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

  /// 悔棋、重开或终局共用的收尾：作废回包、收起提示并结束思考态。
  @protected
  void clearPending() {
    cancelPending();
    clearHint(notify: false);
    endThinking();
  }

  /// 请求一次走子提示，统一加载态、回包竞态与合法着法校验。
  ///
  /// [side] 是发起请求时的行棋方；搜索期间局面变化或提示点被占用时，
  /// 通过 [HintSession.isValid] 丢弃结果。返回展示的交叉点，失败时为 null。
  @protected
  Future<int?> requestMoveHint({
    required int side,
    required Future<int?> Function() search,
    required String label,
  }) async {
    if (!canInteract || hintLoading) return null;
    final move = await hint.request(
      search,
      isValid: (move) =>
          move >= 0 &&
          move < cellCount &&
          board.cells[move] == empty &&
          board.sideToMove == side &&
          board.forbiddenAt(move) == null &&
          canInteract,
      onError: (error, stack) => LogService.error('$label失败', error, stack),
    );
    if (move == null) return null;
    LogService.info('$label: ${MoveNotation.describe(move)}');
    return move;
  }

  /// 执行一次 AI 回合：进入思考态、等待搜索并在回包仍有效时交给 [onReply]。
  ///
  /// 重开、悔棋或新请求会作废搜索，此时直接返回，不调用 [onReply]；
  /// 搜索异常由 [searchAi] 记录，[onReply] 收到 null 时可走兜底着法。
  @protected
  Future<void> runAiTurn({
    required Future<AiReply> Function() search,
    required String label,
    required void Function(AiReply? reply) onReply,
  }) async {
    if (thinking) return;
    final serial = beginThinking();
    final reply = await searchAi(serial: serial, search: search, label: label);
    if (!isCurrent(serial)) return;
    endThinking();
    onReply(reply);
  }

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
