import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/learned_book.dart';
import '../game/self_play_trainer.dart';
import '../providers/settings_provider.dart';
import '../services/file_system_service.dart';
import '../utils/platform_info.dart';
import 'widgets/app_snack.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/log_dialog.dart';
import 'widgets/page_list.dart';
import 'widgets/preference_pickers.dart';
import 'widgets/section_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const int _games = 8;

  final SelfPlayTrainer _trainer = SelfPlayTrainer();
  bool _training = false;
  bool _cancelled = false;
  int _done = 0;
  int _plies = 0;

  Future<void> _train() async {
    final settings = context.read<SettingsProvider>();
    setState(() {
      _training = true;
      _cancelled = false;
      _done = 0;
      _plies = 0;
    });
    final report = await _trainer.run(
      onProgress: (game, plies) {
        if (!mounted) return;
        setState(() {
          _done = game;
          _plies = plies;
        });
      },
      isCancelled: () => _cancelled,
    );
    // 取消或全部和棋时保留原有开局库，避免残缺结果覆盖。
    if (!report.cancelled && !report.book.isEmpty) {
      await settings.setLearnedBook(report.book);
    }
    if (!mounted) return;
    setState(() => _training = false);
    if (report.cancelled) return;
    showSnack(
      context,
      report.book.isEmpty ? '训练未产生精研开局' : '已精研 ${report.book.lines.length} 条开局',
    );
  }

  Future<void> _clearLearned() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '清除精研开局？',
      message: '删除自对弈训练得到的开局，内置开局不受影响，可随时重新训练。',
      confirmLabel: '清除',
    );
    if (!confirmed || !mounted) return;
    await context.read<SettingsProvider>().setLearnedBook(LearnedBook.empty);
    if (mounted) showSnack(context, '已清除精研开局');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final subtle = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final learned = settings.learnedBook;
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
                HandicapPicker(settings: settings),
                const SizedBox(height: 16),
                TimeControlPicker(settings: settings),
                const SizedBox(height: 16),
                _SwitchRow(
                  title: '开局提示',
                  subtitle: '人机执黑或 AI 对演时，前八手参考本地开局库',
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
              title: 'AI 精研',
              icon: Icons.auto_awesome_outlined,
              children: [
                Text(
                  '双方 AI 以六条内置开局自对弈，胜方前八手中的延伸着法写入本地开局库，'
                  '训练全程离线，约半分钟完成。',
                  style: subtle,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _training
                            ? '训练中 · 第 $_done/$_games 局 · 已走 $_plies 手'
                            : learned.isEmpty
                            ? '尚未训练，开局库使用内置棋谱'
                            : '已精研 ${learned.lines.length} 条开局 · '
                                  '${learned.totalWins} 胜',
                        style: subtle,
                      ),
                    ),
                    if (_training)
                      OutlinedButton(
                        onPressed: () => setState(() => _cancelled = true),
                        child: const Text('停止'),
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: _train,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(learned.isEmpty ? '开始训练' : '重新训练'),
                      ),
                  ],
                ),
                if (_training) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _done / _games,
                      minHeight: 6,
                      backgroundColor: colors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ] else if (!learned.isEmpty) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _clearLearned,
                      child: const Text('清除精研开局'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '外观与棋盘',
              icon: Icons.palette_outlined,
              children: [
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
