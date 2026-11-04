import 'package:flutter/material.dart';

import '../../models/game_models.dart';

/// 终局弹窗：展示胜负原因，可返回首页、复盘或再来一局。
Future<void> showGameResultDialog(
  BuildContext context, {
  required GameResult result,
  required int moveCount,
  required VoidCallback onRestart,
  VoidCallback? onReview,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _ResultDialog(
      icon: result.isDraw
          ? Icons.handshake_outlined
          : Icons.emoji_events_outlined,
      title: result.title,
      message: result.reason,
      note: '共 $moveCount 手',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('返回首页'),
        ),
        if (onReview != null)
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onReview();
            },
            child: const Text('复盘'),
          ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            onRestart();
          },
          child: const Text('再来一局'),
        ),
      ],
    ),
  );
}

/// 残局结果弹窗的操作：再练一次、进入下一关或返回列表。
enum PuzzleResultAction { retry, next, close }

/// 残局通关或失败后的结果弹窗。
Future<PuzzleResultAction?> showPuzzleResultDialog(
  BuildContext context, {
  required bool solved,
  required String message,
  required String note,
  required bool hasNext,
}) {
  return showDialog<PuzzleResultAction>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      void choose(PuzzleResultAction action) =>
          Navigator.of(dialogContext).pop(action);
      return _ResultDialog(
        icon: solved ? Icons.emoji_events_outlined : Icons.flag_outlined,
        title: solved ? '通关！' : '挑战失败',
        message: message,
        note: note,
        actions: [
          TextButton(
            onPressed: () => choose(PuzzleResultAction.close),
            child: const Text('返回列表'),
          ),
          OutlinedButton(
            onPressed: () => choose(PuzzleResultAction.retry),
            child: const Text('再练一次'),
          ),
          if (solved && hasNext)
            FilledButton(
              onPressed: () => choose(PuzzleResultAction.next),
              child: const Text('下一关'),
            ),
        ],
      );
    },
  );
}

/// 通用二次确认弹窗，返回 true 表示确认。
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = '取消',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// 认输二次确认，返回 true 表示确认认输。
Future<bool> confirmResign(BuildContext context) => showConfirmDialog(
  context,
  title: '认输',
  message: '确认认输并结束本局吗？',
  confirmLabel: '认输',
  cancelLabel: '继续对局',
);

/// 终局与残局共用的结果弹窗骨架：图标、标题、原因、备注与操作按钮。
///
/// 弹窗不可点击遮罩关闭，操作按钮由调用方决定顺序与语义。
class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.note,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String message;
  final String note;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: Icon(icon, size: 36, color: theme.colorScheme.primary),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 6),
            Text(note, style: theme.textTheme.bodySmall),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: actions,
      ),
    );
  }
}

/// 行棋规则说明。
void showRulesDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('行棋规则'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _RuleLine('黑棋先行，双方轮流在交叉点落下一枚棋子。'),
            _RuleLine('横、竖、斜任意方向先连成五子者获胜，五连优先于四四与三三。'),
            _RuleLine('默认无禁手，长连（六子及以上）同样计为胜。'),
            _RuleLine('开启禁手规则后黑棋受限：长连、四四、三三均为禁手，禁手点以红圈标记。'),
            _RuleLine('禁手规则下白棋不受限制，白棋长连仍计为胜。'),
            _RuleLine('棋盘下满仍无五连时判和。'),
            _RuleLine('点击棋盘交叉点直接落子，最后一手以圆点标记。'),
            _RuleLine('悔棋会撤回最近一手；人机对战会同时撤回双方各一手。'),
            _RuleLine('限时对局中本方棋钟走完即超时判负。'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
