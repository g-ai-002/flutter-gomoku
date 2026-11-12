import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/engine/board_utils.dart';
import '../game/handicap.dart';
import '../game/logic_rate.dart';
import '../models/game_models.dart';
import '../providers/settings_provider.dart';
import '../services/file_system_service.dart';
import '../utils/platform_info.dart';
import 'widgets/app_snack.dart';
import 'widgets/choice_pill.dart';
import 'widgets/log_dialog.dart';
import 'widgets/page_list.dart';
import 'widgets/section_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Future<String> _logRoot = FileSystemService.instance
      .getLogRootPath();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: PageList(
          maxWidth: 680,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionCard(
              title: '对局',
              icon: Icons.tune_rounded,
              children: [
                _choices(
                  'AI 难度',
                  Difficulty.values,
                  settings.difficulty,
                  (value) => value.label,
                  settings.setDifficulty,
                ),
                _choices(
                  '默认执子',
                  const [black, white],
                  settings.humanSide,
                  (value) => value == black ? '执黑先行' : '执白后行',
                  settings.setHumanSide,
                  (value) =>
                      value == black ? colors.onSurface : colors.secondary,
                ),
                _choices(
                  '让子（执黑时·白方先行）',
                  Handicap.values,
                  settings.handicap,
                  (value) => value.label,
                  settings.setHandicap,
                  (_) => colors.tertiary,
                ),
                _choices(
                  '棋钟',
                  TimeControl.values,
                  settings.timeControl,
                  (value) => value.label,
                  settings.setTimeControl,
                ),
                _choices(
                  '逻辑更新速率',
                  LogicRate.values,
                  settings.logicRate,
                  (value) => value.label,
                  settings.setLogicRate,
                ),
                _switch(
                  'switch-opening',
                  '开局提示',
                  '人机执黑或 AI 对演时，前八手参考本地开局库',
                  settings.openingHints,
                  settings.setOpeningHints,
                ),
                _switch(
                  'switch-forbidden',
                  '禁手规则',
                  '黑棋不可长连、四四与三三，白棋不受限制',
                  settings.forbiddenRule,
                  settings.setForbiddenRule,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '外观与棋盘',
              icon: Icons.palette_outlined,
              children: [
                _switch(
                  'switch-dark',
                  '深色模式',
                  '暖墨底色，夜间对弈更舒适',
                  settings.darkMode,
                  settings.setDarkMode,
                ),
                _switch(
                  'switch-coords',
                  '显示坐标',
                  '棋盘边缘显示 A–O 与 1–15 坐标',
                  settings.showCoordinates,
                  settings.setShowCoordinates,
                ),
                _switch(
                  'switch-position',
                  '形势判断',
                  '棋盘浮层显示实时胜率，随每手棋更新',
                  settings.showPosition,
                  settings.setShowPosition,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '音效与反馈',
              icon: Icons.graphic_eq_rounded,
              children: [
                _switch(
                  'switch-sound',
                  '落子音效',
                  '运行时合成落子、威胁与终局音效',
                  settings.soundEnabled,
                  settings.setSoundEnabled,
                ),
                _switch(
                  'switch-music',
                  '背景音乐',
                  '五声音阶循环，运行时合成，可随时关闭',
                  settings.musicEnabled,
                  settings.setMusicEnabled,
                ),
                _switch(
                  'switch-haptics',
                  '震动反馈',
                  '落子与终局时给出不同强度的触感',
                  settings.hapticsEnabled,
                  settings.setHapticsEnabled,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '运行日志',
              icon: Icons.receipt_long_outlined,
              children: [
                FutureBuilder<String>(
                  future: _logRoot,
                  builder: (context, snapshot) {
                    final path = snapshot.data ?? '';
                    final text = path.isEmpty
                        ? (isDesktopPlatform ? '正在读取日志目录…' : '当前平台日志仅保留在内存中')
                        : path;
                    return SelectableText(
                      text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFamily: 'Consolas',
                        fontFamilyFallback: const ['Menlo', 'monospace'],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => showLogDialog(context),
                      icon: const Icon(Icons.article_outlined, size: 17),
                      label: const Text('查看日志'),
                    ),
                    if (isDesktopPlatform)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final path = await FileSystemService.instance
                              .getLogRootPath();
                          final ok = await FileSystemService.instance
                              .openDirectory(path);
                          if (!context.mounted) return;
                          showSnack(context, ok ? '已打开日志目录' : '无法打开日志目录');
                        },
                        icon: const Icon(Icons.folder_open, size: 17),
                        label: const Text('打开目录'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 互斥选项组：设置页的难度、执子、让子与棋钟共用一套标题与胶囊。
  Widget _choices<T>(
    String label,
    List<T> values,
    T selected,
    String Function(T) labelOf,
    ValueChanged<T> onSelected, [
    Color Function(T)? accentOf,
  ]) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                ChoicePill(
                  label: labelOf(value),
                  selected: value == selected,
                  accent: accentOf?.call(value) ?? colors.primary,
                  onTap: () => onSelected(value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 开关行：统一上下间距与紧凑密度，省去每处重复的 SizedBox。
  Widget _switch(
    String key,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        key: ValueKey(key),
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeTrackColor: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
