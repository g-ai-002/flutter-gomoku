import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/engine/board_utils.dart';
import '../game/opening_book.dart';
import '../models/game_models.dart';
import '../providers/settings_provider.dart';
import 'game_page.dart';
import 'widgets/highlight_panel.dart';
import 'widgets/opening_preview.dart';
import 'widgets/page_list.dart';

/// 开局库：浏览内置开局、查看前六手棋形，并直接进入开局练习。
class OpeningBookPage extends StatelessWidget {
  const OpeningBookPage({super.key});

  void _practice(BuildContext context, OpeningLine line) {
    final settings = context.read<SettingsProvider>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          mode: GameMode.vsAi,
          difficulty: settings.difficulty,
          humanSide: black,
          opening: line,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('开局库')),
      body: SafeArea(
        child: PageList(
          maxWidth: 820,
          children: [
            HighlightPanel(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 18,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text('前六手参考', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '开局库覆盖直指与斜指两类起手。人机对战执黑时自动生效，'
                    '「提示」按钮会优先给出棋谱着法；脱谱后立即交回本地引擎。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final line in kOpeningLines) ...[
              _OpeningCard(
                line: line,
                onPractice: () => _practice(context, line),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpeningCard extends StatelessWidget {
  const _OpeningCard({required this.line, required this.onPractice});

  final OpeningLine line;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline.withValues(alpha: 0.75)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 540;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OpeningPreview(line: line, size: wide ? 138 : 116),
                  const SizedBox(width: 14),
                  Expanded(child: _heading(context)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                line.idea,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 10),
              _practiceButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _heading(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                line.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                line.family,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          line.tagline,
          maxLines: 2,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _practiceButton() => OutlinedButton.icon(
    onPressed: onPractice,
    icon: const Icon(Icons.play_circle_outline, size: 17),
    label: const Text('练习此开局'),
  );
}
