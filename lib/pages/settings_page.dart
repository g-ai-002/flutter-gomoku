import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/engine/board_utils.dart';
import '../game/handicap.dart';
import '../game/learned_book.dart';
import '../game/self_play_trainer.dart';
import '../models/game_models.dart';
import '../providers/settings_provider.dart';
import '../services/file_system_service.dart';
import '../utils/platform_info.dart';
import 'widgets/app_snack.dart';
import 'widgets/choice_pill.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/log_dialog.dart';
import 'widgets/page_list.dart';
import 'widgets/section_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const int _games = 8;

  final SelfPlayTrainer _trainer = SelfPlayTrainer();

  late final Future<String> _logRoot = FileSystemService.instance
      .getLogRootPath();

  final ValueNotifier<(int, int)?> _progress = ValueNotifier(null);
  bool _training = false;
  bool _cancelled = false;

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _train() async {
    final settings = context.read<SettingsProvider>();
    _cancelled = false;
    _progress.value = (0, 0);
    setState(() => _training = true);
    final report = await _trainer.run(
      onProgress: (game, plies) {
        if (mounted) _progress.value = (game, plies);
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
                _choices('AI 难度', Difficulty.values, settings.difficulty,
                    (value) => value.label, settings.setDifficulty),
                _choices('默认执子', const [black, white], settings.humanSide,
                    (value) => value == black ? '执黑先行' : '执白后行',
                    settings.setHumanSide,
                    (value) => value == black ? colors.onSurface : colors.secondary),
                _choices('让子（执黑时·白方先行）', Handicap.values,
                    settings.handicap, (value) => value.label,
                    settings.setHandicap, (_) => colors.tertiary),
                _choices('棋钟', TimeControl.values, settings.timeControl,
                    (value) => value.label, settings.setTimeControl),
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
              title: 'AI 精研',
              icon: Icons.auto_awesome_outlined,
              children: [
                Text(
                  '双方 AI 以六条内置开局自对弈，胜方前八手中的延伸着法写入本地开局库，'
                  '训练全程离线，约半分钟完成。',
                  style: subtle,
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<(int, int)?>(
                  valueListenable: _progress,
                  builder: (context, progress, _) {
                    final done = progress?.$1 ?? 0;
                    final plies = progress?.$2 ?? 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _training
                                    ? '训练中 · 第 $done/$_games 局 · 已走 $plies 手'
                                    : learned.isEmpty
                                    ? '尚未训练，开局库使用内置棋谱'
                                    : '已精研 ${learned.lines.length} 条开局 · '
                                          '${learned.totalWins} 胜',
                                style: subtle,
                              ),
                            ),
                            if (_training)
                              OutlinedButton(
                                onPressed: () =>
                                    setState(() => _cancelled = true),
                                child: const Text('停止'),
                              )
                            else
                              FilledButton.tonalIcon(
                                onPressed: _train,
                                icon: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 18,
                                ),
                                label: Text(learned.isEmpty ? '开始训练' : '重新训练'),
                              ),
                          ],
                        ),
                        if (_training) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: done / _games,
                              minHeight: 6,
                              backgroundColor: colors.primary.withValues(
                                alpha: 0.12,
                              ),
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
                    );
                  },
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
