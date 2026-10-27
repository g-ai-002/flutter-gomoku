import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ai/ai_engine.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../utils/game_hints.dart';
import 'game_page.dart';
import 'records_page.dart';
import 'settings_page.dart';

/// 首页：应用入口枢纽
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final game = context.read<GameProvider>();
    final darkMode = context.select<GameProvider, bool>((g) => g.darkMode);
    final mode = context.select<GameProvider, GameMode>((g) => g.mode);
    final boardSize = context.select<GameProvider, int>((g) => g.boardSize);
    final aiDifficulty = context.select<GameProvider, AIDifficulty>(
      (g) => g.aiDifficulty,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(darkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: darkMode ? '切换浅色模式' : '切换深色模式',
            onPressed: () => game.toggleDarkMode(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.grid_on,
                  size: 80,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '经典黑白对弈',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GamePage()),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始游戏', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecordsPage()),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('对局记录'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '模式: ${mode.label}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.secondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  mode == GameMode.pve
                      ? '棋盘: $boardSize×$boardSize  |  难度: ${aiDifficulty.label}'
                      : '棋盘: $boardSize×$boardSize',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Text(
                  GameHints.homeHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
