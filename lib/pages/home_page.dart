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
              final horizontal = constraints.maxWidth >= 900 ? 40.0 : 20.0;
              final avail = constraints.maxWidth - horizontal * 2;
              // 横屏与桌面并排：左侧品牌预览、右侧入口列表，入口免滚动即可见。
              final panes =
                  constraints.maxWidth >= 600 &&
                  constraints.maxWidth > constraints.maxHeight;
              return Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 16),
                child: Column(
                  children: [
                    _TopBar(darkMode: settings.darkMode),
                    SizedBox(height: panes ? 6 : 20),
                    Expanded(
                      child: panes
                          ? _panes(context, cards, math.min(avail, 1200))
                          : _flow(context, cards, math.min(avail, 780)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 竖向窗口：品牌区在上、入口在下，整体滚动；平板宽度下入口排成两列。
  Widget _flow(BuildContext context, List<Widget> cards, double content) {
    // 矮窗口收窄品牌区，保证至少一列入口在首屏可见。
    final compact = MediaQuery.sizeOf(context).height < 620;
    final columns = content >= 560 ? 2 : 1;
    final width = columns == 2 ? (content - 12) / 2 : content;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _hero(context, compact: compact),
              SizedBox(height: compact ? 18 : 28),
              _grid(cards, width),
              const SizedBox(height: 22),
              _version(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 横屏与桌面：左侧预览收窄，右侧入口列表可滚动，够宽时排成两列。
  Widget _panes(BuildContext context, List<Widget> cards, double row) {
    final pane = (row - 24) * 5 / 9;
    final width = pane >= 520 ? (pane - 12) / 2 : pane;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: row),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  child: _hero(context, compact: true),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: ListView(
                children: [
                  _grid(cards, width),
                  const SizedBox(height: 16),
                  _version(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<Widget> cards, double width) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final card in cards) SizedBox(width: width, child: card),
    ],
  );

  Widget _version(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'v${AppConstants.version} · 本地运行，无需联网',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _hero(BuildContext context, {bool compact = false}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = Text(
      '五子棋',
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontSize: compact ? 26 : 32,
        letterSpacing: compact ? 6 : 8,
        color: colors.onSurface,
      ),
    );
    final subtle = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final ornament = Container(width: 36, height: 1, color: colors.outline);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BoardPreview(side: compact ? 128 : 172),
        SizedBox(height: compact ? 14 : 20),
        title,
        SizedBox(height: compact ? 8 : 10),
        if (!compact) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ornament,
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
              ornament,
            ],
          ),
          const SizedBox(height: 12),
        ],
        Text('黑白之间，方寸之上见胜负', textAlign: TextAlign.center, style: subtle),
      ],
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
