import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/status_bar.dart';
import 'records_page.dart';

/// 游戏主页面
class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('五子棋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: '对局记录',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordsPage()),
              );
            },
          ),
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
            const StatusBar(),
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
            _buildActionBar(context, game, theme),
          ],
        ),
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
            onPressed: game.canUndo && !game.aiThinking ? () => game.undo() : null,
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('悔棋'),
          ),
          ElevatedButton.icon(
            onPressed: game.aiThinking ? null : () => _confirmRestart(context, game),
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
