import '../game/board_view.dart';
import '../game/engine/rules.dart';
import 'sound_service.dart';

/// 监听棋谱增长并播放落子反馈，对局页与残局页共用。
///
/// 新增着法时播放落子音；形成活四时改播上行提示音。悔棋、重开或复盘
/// 跳转导致棋谱缩短时只对齐游标，不补放音效。
class MoveFeedbackTracker {
  MoveFeedbackTracker(this.view);

  final BoardView view;
  int _seen = 0;

  /// 重开一局时重置游标，避免首手被当作已有着法跳过。
  void reset() => _seen = 0;

  void sync() {
    final history = view.history;
    if (history.length <= _seen) {
      _seen = history.length;
      return;
    }
    for (var i = _seen; i < history.length; i++) {
      final record = history[i];
      final threat = GomokuRules.makesOpenFour(
        view.cells,
        record.index,
        record.side,
      );
      SoundService.play(threat ? MoveFeedback.threat : MoveFeedback.place);
    }
    _seen = history.length;
  }
}
