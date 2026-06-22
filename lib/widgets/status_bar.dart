import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

/// 游戏状态栏组件
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final state = game.state;
    final theme = Theme.of(context);

    String statusText;
    Color statusColor;

    if (game.aiThinking) {
      statusText = 'AI 思考中...';
      statusColor = theme.colorScheme.primary;
    } else {
      switch (state.status) {
        case GameStatus.playing:
          statusText = '当前: ${state.currentPlayer.label}';
          statusColor = state.currentPlayer == StoneColor.black
              ? Colors.black87
              : Colors.grey.shade700;
          break;
        case GameStatus.blackWin:
          statusText = '黑棋获胜!';
          statusColor = Colors.black87;
          break;
        case GameStatus.whiteWin:
          statusText = '白棋获胜!';
          statusColor = Colors.grey.shade700;
          break;
        case GameStatus.draw:
          statusText = '平局!';
          statusColor = theme.colorScheme.onSurfaceVariant;
          break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.status == GameStatus.playing && !game.aiThinking)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StoneIcon(color: state.currentPlayer),
            ),
          if (game.aiThinking)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Text(
            statusText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state.status == GameStatus.playing && !game.aiThinking)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                '第 ${state.history.length + 1} 手',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _StoneIcon extends StatelessWidget {
  final StoneColor color;
  const _StoneIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: color == StoneColor.black
              ? [const Color(0xFF555555), const Color(0xFF111111)]
              : [const Color(0xFFFFFFFF), const Color(0xFFCCCCCC)],
        ),
        border: Border.all(
          color: color == StoneColor.black
              ? const Color(0xFF333333)
              : const Color(0xFFAAAAAA),
          width: 0.5,
        ),
      ),
    );
  }
}
