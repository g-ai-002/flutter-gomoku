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
  return _showResultDialog(
    context,
    icon: result.isDraw
        ? Icons.handshake_outlined
        : Icons.emoji_events_outlined,
    title: result.title,
    message: result.reason,
    note: '共 $moveCount 手',
    actions: [
      _ResultAction(
        label: '返回首页',
        onPressed: () => Navigator.of(context).pop(),
      ),
      if (onReview != null) _ResultAction(label: '复盘', onPressed: onReview),
      _ResultAction(
        label: '再来一局',
        style: _ActionStyle.filled,
        onPressed: onRestart,
      ),
    ],
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

enum _ActionStyle { text, outlined, filled }

class _ResultAction {
  const _ResultAction({
    required this.label,
    required this.onPressed,
    this.style = _ActionStyle.text,
  });

  final String label;
  final VoidCallback onPressed;
  final _ActionStyle style;
}

Future<void> _showResultDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String note,
  required List<_ResultAction> actions,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      void run(_ResultAction action) {
        Navigator.of(dialogContext).pop();
        action.onPressed();
      }

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
          actions: [
            for (final action in actions)
              switch (action.style) {
                _ActionStyle.filled => FilledButton(
                  onPressed: () => run(action),
                  child: Text(action.label),
                ),
                _ActionStyle.outlined => OutlinedButton(
                  onPressed: () => run(action),
                  child: Text(action.label),
                ),
                _ActionStyle.text => TextButton(
                  onPressed: () => run(action),
                  child: Text(action.label),
                ),
              },
          ],
        ),
      );
    },
  );
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
            _RuleLine('横、竖、斜任意方向先连成五子者获胜，本作采用无禁手规则。'),
            _RuleLine('长连（六子及以上）同样计为胜。'),
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
