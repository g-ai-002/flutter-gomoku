import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ai/ai_engine.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

/// 设置面板
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final game = context.read<GameProvider>();
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('游戏模式', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: GameMode.values.map((mode) {
                final isSelected = game.mode == mode;
                return ChoiceChip(
                  label: Text(mode.label),
                  selected: isSelected,
                  onSelected: (_) => game.setGameMode(mode),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (game.mode == GameMode.pve) ...[
              Text('AI 难度', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: AIDifficulty.values.map((diff) {
                  final isSelected = game.aiDifficulty == diff;
                  return ChoiceChip(
                    label: Text(diff.label),
                    selected: isSelected,
                    onSelected: (_) => game.setAIDifficulty(diff),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Text('棋盘大小', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [9, 13, 15, 19].map((size) {
                final isSelected = game.boardSize == size;
                return ChoiceChip(
                  label: Text('${size}x$size'),
                  selected: isSelected,
                  onSelected: (_) => game.setBoardSize(size),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('外观', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Consumer<GameProvider>(
              builder: (context, game, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('深色模式'),
                value: game.darkMode,
                onChanged: (_) => game.toggleDarkMode(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
