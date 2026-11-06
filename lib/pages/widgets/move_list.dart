import 'package:flutter/material.dart';

import '../../models/move_record.dart';
import '../../theme/app_theme.dart';

/// 棋谱列表：按回合成对展示黑白双方的坐标，新着法自动滚到底部。
///
/// 复盘时可通过 [highlightIndex] 与 [onTapIndex] 高亮并跳转到任意一步。
class MoveList extends StatefulWidget {
  const MoveList({
    super.key,
    required this.history,
    this.padding = EdgeInsets.zero,
    this.highlightIndex,
    this.onTapIndex,
  });

  final List<MoveRecord> history;
  final EdgeInsets padding;

  /// 需要高亮的手数下标，缺省时高亮最后一手。
  final int? highlightIndex;

  final ValueChanged<int>? onTapIndex;

  @override
  State<MoveList> createState() => _MoveListState();
}

class _MoveListState extends State<MoveList> {
  final ScrollController _scroll = ScrollController();
  late int _lastLength;

  @override
  void initState() {
    super.initState();
    _lastLength = widget.history.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MoveList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // history 是同一个可变列表，不能依赖 oldWidget 的长度比较。
    if (widget.history.length != _lastLength) {
      _lastLength = widget.history.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (widget.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grid_on,
              size: 30,
              color: colors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            Text(
              '尚未落子',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    final rows = (widget.history.length + 1) ~/ 2;
    final highlight = widget.highlightIndex ?? widget.history.length - 1;
    return ListView.builder(
      controller: _scroll,
      padding: widget.padding,
      itemCount: rows,
      itemBuilder: (context, row) {
        final blackIndex = row * 2;
        final whiteIndex = blackIndex + 1;
        final blackMove = widget.history[blackIndex];
        final whiteMove = whiteIndex < widget.history.length
            ? widget.history[whiteIndex]
            : null;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.outline.withValues(alpha: 0.45),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${row + 1}.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: _NotationText(
                  record: blackMove,
                  highlight: blackIndex == highlight,
                  onTap: _tapHandler(blackIndex),
                ),
              ),
              Expanded(
                child: whiteMove == null
                    ? const SizedBox.shrink()
                    : _NotationText(
                        record: whiteMove,
                        highlight: whiteIndex == highlight,
                        onTap: _tapHandler(whiteIndex),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  VoidCallback? _tapHandler(int index) {
    final onTap = widget.onTapIndex;
    if (onTap == null) return null;
    return () => onTap(index);
  }
}

class _NotationText extends StatelessWidget {
  const _NotationText({
    required this.record,
    required this.highlight,
    this.onTap,
  });

  final MoveRecord record;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = sideAccentOf(context, record.side);
    final text = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          record.notation,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: highlight ? colors.primary : colors.onSurface,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
    if (onTap == null) return text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: text,
      ),
    );
  }
}
