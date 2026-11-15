import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../flame/gomoku_game.dart';
import '../../game/board_session.dart';
import '../../providers/settings_provider.dart';
import '../../services/move_feedback_tracker.dart';

/// 对局与残局页共用的棋盘装配：Flame 游戏、落子反馈与控制器监听。
///
/// 游戏实例、反馈游标和监听解绑集中在这里，页面只保留自己的结果弹窗与
/// 操作按钮，避免两个页面各写一份 initState/dispose 而漏掉清理。
class SessionBoardView<C extends BoardSession> extends StatefulWidget {
  const SessionBoardView({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.boardBuilder,
  });

  final C controller;

  /// 控制器通知后回调；落子反馈已在此之前对齐。
  final VoidCallback onChanged;

  /// 用当前游戏实例构建棋盘区域。
  final Widget Function(BuildContext context, GomokuGame game) boardBuilder;

  @override
  State<SessionBoardView<C>> createState() => _SessionBoardViewState<C>();
}

class _SessionBoardViewState<C extends BoardSession>
    extends State<SessionBoardView<C>> {
  late final GomokuGame _game;
  late final MoveFeedbackTracker _feedback;

  @override
  void initState() {
    super.initState();
    _game = GomokuGame(
      view: widget.controller,
      repaint: widget.controller,
      logicRate: context.read<SettingsProvider>().logicRate,
    );
    _feedback = MoveFeedbackTracker(widget.controller);
    widget.controller.addListener(_handleChanged);
  }

  void _handleChanged() {
    if (!mounted) return;
    _feedback.sync();
    widget.onChanged();
  }

  @override
  void dispose() {
    _game.stop();
    widget.controller.removeListener(_handleChanged);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.boardBuilder(context, _game);
}
