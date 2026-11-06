import 'package:flutter/material.dart';

import '../../game/engine/board_utils.dart';
import '../../game/handicap.dart';
import '../../models/game_models.dart';
import '../../providers/settings_provider.dart';
import 'choice_pill.dart';

/// 难度选择：设置页使用。
class DifficultyPicker extends StatelessWidget {
  const DifficultyPicker({
    super.key,
    required this.settings,
    this.label = 'AI 难度',
  });

  final SettingsProvider settings;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _ChoiceGroup<Difficulty>(
      label: label,
      values: Difficulty.values,
      selected: settings.difficulty,
      labelOf: (value) => value.label,
      accentOf: (_) => colors.primary,
      onSelected: settings.setDifficulty,
    );
  }
}

/// 先后手选择：黑棋先行，白棋后行。
class SidePicker extends StatelessWidget {
  const SidePicker({super.key, required this.settings, this.label = '先后手'});

  final SettingsProvider settings;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _ChoiceGroup<int>(
      label: label,
      values: const [black, white],
      selected: settings.humanSide,
      labelOf: (value) => value == black ? '执黑先行' : '执白后行',
      accentOf: (value) => value == black ? colors.onSurface : colors.secondary,
      onSelected: settings.setHumanSide,
    );
  }
}

/// 让子选择：人机执黑时预置黑子，由白方先行。
class HandicapPicker extends StatelessWidget {
  const HandicapPicker({super.key, required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _ChoiceGroup<Handicap>(
      label: '让子（执黑时·白方先行）',
      values: Handicap.values,
      selected: settings.handicap,
      labelOf: (value) => value.label,
      accentOf: (_) => colors.tertiary,
      onSelected: settings.setHandicap,
    );
  }
}

/// 棋钟方案选择。
class TimeControlPicker extends StatelessWidget {
  const TimeControlPicker({
    super.key,
    required this.settings,
    this.label = '棋钟',
  });

  final SettingsProvider settings;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _ChoiceGroup<TimeControl>(
      label: label,
      values: TimeControl.values,
      selected: settings.timeControl,
      labelOf: (value) => value.label,
      accentOf: (_) => colors.primary,
      onSelected: settings.setTimeControl,
    );
  }
}

/// 一组互斥选项：标题、胶囊按钮与统一回调。
class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.accentOf,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final Color Function(T value) accentOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
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
                accent: accentOf(value),
                onTap: () => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}
