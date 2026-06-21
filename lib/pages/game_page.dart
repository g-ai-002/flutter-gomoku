import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/settings_sheet.dart';

/// 游戏主页面
class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final state = game.state;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('五子棋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 状态栏
            _buildStatusBar(state, theme),
            // 棋盘
            Expanded(
              child: const Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: BoardWidget(),
                  ),
                ),
              ),
            ),
            // 操作按钮
            _buildActionBar(context, game, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(GameState state, ThemeData theme) {
    String statusText;
    Color statusColor;

    switch (state.status) {
      case GameStatus.playing:
        statusText = '当前: ${state.currentPlayer.label}';
        statusColor = state.currentPlayer == StoneColor.black
            ? Colors.black87
            : Colors.grey.shade700;
        break;
      case GameStatus.blackWin:
        statusText = '🏆 黑棋获胜!';
        statusColor = Colors.black87;
        break;
      case GameStatus.whiteWin:
        statusText = '🏆 白棋获胜!';
        statusColor = Colors.grey.shade700;
        break;
      case GameStatus.draw:
        statusText = '🤝 平局!';
        statusColor = theme.colorScheme.onSurfaceVariant;
        break;
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
          // 当前玩家指示器
          if (state.status == GameStatus.playing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: state.currentPlayer == StoneColor.black
                        ? [const Color(0xFF555555), const Color(0xFF111111)]
                        : [const Color(0xFFFFFFFF), const Color(0xFFCCCCCC)],
                  ),
                  border: Border.all(
                    color: state.currentPlayer == StoneColor.black
                        ? const Color(0xFF333333)
                        : const Color(0xFFAAAAAA),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          Text(
            statusText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state.status == GameStatus.playing)
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

  Widget _buildActionBar(
    BuildContext context,
    GameProvider game,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          OutlinedButton.icon(
            onPressed: game.canUndo ? () => game.undo() : null,
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('悔棋'),
          ),
          ElevatedButton.icon(
            onPressed: () => _confirmRestart(context, game),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重新开始'),
          ),
        ],
      ),
    );
  }

  void _confirmRestart(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重新开始'),
        content: const Text('确定要重新开始当前对局吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              game.restart();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => const SettingsSheet(),
    );
  }
}
