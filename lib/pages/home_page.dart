import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/engine/board_utils.dart';
import '../models/game_models.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/board_painting.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import 'game_history_page.dart';
import 'game_page.dart';
import 'puzzle_library_page.dart';
import 'settings_page.dart';
import 'widgets/board_preview.dart';
import 'widgets/entry_tile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cards = _modeCards(context, settings, theme.colorScheme);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF201B14), Color(0xFF121009)]
                : const [Color(0xFFFCF7EC), Color(0xFFF1E5CF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 各尺寸共用一套居中滚动布局，避免横屏与桌面切换分栏造成观感跳变。
              // 折叠屏展开约 600dp 起即可并排两张入口卡片。
              final twoColumns = constraints.maxWidth >= 600;
              final horizontal = constraints.maxWidth >= 900 ? 40.0 : 20.0;
              final contentWidth = math.min(
                constraints.maxWidth - horizontal * 2,
                780.0,
              );
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - 38),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 780),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TopBar(darkMode: settings.darkMode),
                          const SizedBox(height: 22),
                          const _Hero(),
                          const SizedBox(height: 30),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final card in cards)
                                SizedBox(
                                  width: twoColumns
                                      ? (contentWidth - 12) / 2
                                      : contentWidth,
                                  child: card,
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'v${AppConstants.version} · 本地运行，无需联网',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _startGame(
    BuildContext context,
    SettingsProvider settings,
    GameMode mode,
  ) {
    pushScreen<void>(
      context,
      GamePage(
        mode: mode,
        difficulty: settings.difficulty,
        humanSide: mode == GameMode.vsAi ? settings.humanSide : black,
      ),
    );
  }

  /// 棋谱库：最近 20 局回放与导入导出入口。
  void _openArchives(BuildContext context) =>
      pushScreen<void>(context, const GameHistoryPage());

  /// 残局挑战：十道内置杀法，按难度分组。
  void _openPuzzles(BuildContext context) =>
      pushScreen<void>(context, const PuzzleLibraryPage());

  /// 首页模式入口，宽屏两列、窄屏堆叠都复用同一份定义。
  List<Widget> _modeCards(
    BuildContext context,
    SettingsProvider settings,
    ColorScheme colors,
  ) {
    final entries = <(IconData, Color, String, String, VoidCallback)>[
      (
        Icons.smart_toy_outlined,
        colors.primary,
        GameMode.vsAi.label,
        settings.handicap.enabled && settings.humanSide == black
            ? '${settings.handicap.label} · 白方先行'
            : '三档 AI 难度 · 可执黑或执白',
        () => _startGame(context, settings, GameMode.vsAi),
      ),
      (
        Icons.people_alt_outlined,
        colors.tertiary,
        GameMode.twoPlayers.label,
        '同屏轮流落子 · 面对面手谈',
        () => _startGame(context, settings, GameMode.twoPlayers),
      ),
      (
        Icons.smart_display_outlined,
        colors.primary,
        GameMode.aiSelf.label,
        '双方 AI 自动对弈 · 观战学习',
        () => _startGame(context, settings, GameMode.aiSelf),
      ),
      (
        Icons.flag_outlined,
        colors.secondary,
        '残局挑战',
        '10 道杀法 · 支持自建残局',
        () => _openPuzzles(context),
      ),
      (
        Icons.history_edu_outlined,
        appWood,
        '棋谱复盘',
        '最近 20 局 · 导入导出',
        () => _openArchives(context),
      ),
    ];
    return [
      for (final (icon, accent, title, subtitle, onTap) in entries)
        EntryTile(
          leading: EntryBadge(icon: icon, accent: accent),
          title: title,
          subtitle: subtitle,
          onTap: onTap,
        ),
    ];
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.darkMode});

  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: colors.primary, width: 1.4),
          ),
          child: Text(
            '五',
            style: pieceTextStyle(fontSize: 20, color: colors.primary),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              'GOMOKU',
              style: TextStyle(
                fontSize: 8.5,
                letterSpacing: 1.4,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          tooltip: darkMode ? '切换浅色' : '切换深色',
          onPressed: () => settings.setDarkMode(!darkMode),
          icon: Icon(
            darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 21,
          ),
        ),
        IconButton(
          tooltip: '设置',
          onPressed: () => pushScreen<void>(context, const SettingsPage()),
          icon: const Icon(Icons.settings_outlined, size: 21),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        const BoardPreview(),
        const SizedBox(height: 20),
        Text(
          '五子棋',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 32,
            letterSpacing: 8,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ornament(colors),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '縱 橫 · 五 連',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 3,
                ),
              ),
            ),
            _ornament(colors),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '黑白之间，方寸之上见胜负',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _ornament(ColorScheme colors) => Container(
    width: 36,
    height: 1,
    color: colors.outline.withValues(alpha: 0.9),
  );
}
