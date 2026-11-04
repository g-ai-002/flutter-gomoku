import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/file_system_service.dart';
import '../utils/constants.dart';
import '../utils/platform_info.dart';
import 'widgets/app_snack.dart';
import 'widgets/log_dialog.dart';
import 'widgets/page_list.dart';
import 'widgets/preference_pickers.dart';
import 'widgets/section_card.dart';
import 'widgets/skin_picker.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                DifficultyPicker(settings: settings),
                const SizedBox(height: 16),
                SidePicker(settings: settings, label: '默认执子'),
                const SizedBox(height: 16),
                TimeControlPicker(settings: settings),
                const SizedBox(height: 16),
                _SwitchRow(
                  title: '开局提示',
                  subtitle: '人机执黑时，前六手参考内置开局库',
                  value: settings.openingHints,
                  onChanged: settings.setOpeningHints,
                  switchKey: const ValueKey('switch-opening'),
                ),
                const SizedBox(height: 10),
                _SwitchRow(
                  title: '禁手规则',
                  subtitle: '黑棋不可长连、四四与三三，白棋不受限制',
                  value: settings.forbiddenRule,
                  onChanged: settings.setForbiddenRule,
                  switchKey: const ValueKey('switch-forbidden'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '外观与棋盘',
              icon: Icons.palette_outlined,
              children: [
                SkinPicker(settings: settings),
                const SizedBox(height: 16),
                _SwitchRow(
                  title: '深色模式',
                  subtitle: '暖墨底色，夜间对弈更舒适',
                  value: settings.darkMode,
                  onChanged: settings.setDarkMode,
                  switchKey: const ValueKey('switch-dark'),
                ),
                const SizedBox(height: 10),
                _SwitchRow(
                  title: '显示坐标',
                  subtitle: '棋盘边缘显示 A–O 与 1–15 坐标',
                  value: settings.showCoordinates,
                  onChanged: settings.setShowCoordinates,
                  switchKey: const ValueKey('switch-coords'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '音效与反馈',
              icon: Icons.graphic_eq_rounded,
              children: [
                _SwitchRow(
                  title: '落子音效',
                  subtitle: '运行时合成落子、威胁与终局音效',
                  value: settings.soundEnabled,
                  onChanged: settings.setSoundEnabled,
                  switchKey: const ValueKey('switch-sound'),
                ),
                const SizedBox(height: 10),
                _SwitchRow(
                  title: '背景音乐',
                  subtitle: '五声音阶循环，运行时合成，可随时关闭',
                  value: settings.musicEnabled,
                  onChanged: settings.setMusicEnabled,
                  switchKey: const ValueKey('switch-music'),
                ),
                const SizedBox(height: 10),
                _SwitchRow(
                  title: '震动反馈',
                  subtitle: '落子与终局时给出不同强度的触感',
                  value: settings.hapticsEnabled,
                  onChanged: settings.setHapticsEnabled,
                  switchKey: const ValueKey('switch-haptics'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '运行日志',
              icon: Icons.receipt_long_outlined,
              children: [
                FutureBuilder<String>(
                  future: FileSystemService.instance.getLogRootPath(),
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
            const SizedBox(height: 12),
            SectionCard(
              title: '关于',
              icon: Icons.info_outline,
              children: [
                const _AboutRow(label: '版本', value: 'v${AppConstants.version}'),
                const SizedBox(height: 8),
                const _AboutRow(label: '引擎', value: 'Flutter + Flame'),
                const SizedBox(height: 8),
                const _AboutRow(label: '平台', value: 'Android / Windows / Web'),
                const SizedBox(height: 12),
                Text(
                  '默认采用无禁手规则，黑白轮流落子，先连成五子者胜。'
                  '开启禁手后黑棋不可长连、四四与三三，禁手点会以红圈标记。'
                  '人机对战由本地棋型评估与 Alpha-Beta 搜索驱动，无需联网。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.switchKey,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Key? switchKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          key: switchKey,
          value: value,
          onChanged: onChanged,
          activeTrackColor: colors.primary,
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(value, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
