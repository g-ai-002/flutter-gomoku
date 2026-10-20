import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ai/ai_engine.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final game = context.watch<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // 外观
          const _SectionHeader(title: '外观'),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('切换深色/浅色主题'),
            value: game.darkMode,
            onChanged: (_) => game.toggleDarkMode(),
            secondary: Icon(
              game.darkMode ? Icons.dark_mode : Icons.light_mode,
              color: colorScheme.primary,
            ),
          ),
          const Divider(),
          // 音效
          const _SectionHeader(title: '音效'),
          SwitchListTile(
            title: const Text('音效'),
            subtitle: const Text('开启落子与胜负音效'),
            value: game.soundEnabled,
            onChanged: (_) => game.toggleSound(),
            secondary: Icon(
              game.soundEnabled ? Icons.volume_up : Icons.volume_off,
              color: colorScheme.primary,
            ),
          ),
          const Divider(),
          // 游戏模式
          const _SectionHeader(title: '游戏模式'),
          ...GameMode.values.map((mode) {
            return RadioListTile<GameMode>(
              title: Text(mode.label),
              value: mode,
              groupValue: game.mode,
              onChanged: (v) {
                if (v != null) {
                  game.setGameMode(v);
                }
              },
              secondary: Icon(
                mode == GameMode.pve ? Icons.smart_toy : Icons.people,
                color: colorScheme.primary,
              ),
            );
          }),
          // AI 难度：仅人机对弈时展示
          if (game.mode == GameMode.pve) ...[
            const Divider(),
            const _SectionHeader(title: 'AI 难度'),
            ...AIDifficulty.values.map((diff) {
              return RadioListTile<AIDifficulty>(
                title: Text(diff.label),
                value: diff,
                groupValue: game.aiDifficulty,
                onChanged: (v) {
                  if (v != null) {
                    game.setAIDifficulty(v);
                  }
                },
                secondary: Icon(
                  Icons.psychology,
                  color: colorScheme.primary,
                ),
              );
            }),
          ],
          const Divider(),
          // 棋盘大小
          const _SectionHeader(title: '棋盘大小'),
          ...AppConstants.boardSizeOptions.map((size) {
            return RadioListTile<int>(
              title: Text(_boardSizeLabel(size)),
              value: size,
              groupValue: game.boardSize,
              onChanged: (v) {
                if (v != null) {
                  game.setBoardSize(v);
                }
              },
              secondary: Icon(Icons.grid_on, color: colorScheme.primary),
            );
          }),
          const Divider(),
          // 关于
          const _SectionHeader(title: '关于'),
          ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: const Text('版本'),
            trailing: const Text(AppConstants.version),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

String _boardSizeLabel(int size) {
  return switch (size) {
    9 => '小 (9×9)',
    13 => '中 (13×13)',
    15 => '大 (15×15)',
    _ => '标准 (19×19)',
  };
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
