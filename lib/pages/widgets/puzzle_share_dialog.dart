import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/custom_puzzles.dart';
import '../../game/puzzle_share_code.dart';
import 'app_snack.dart';

const TextStyle _codeStyle = TextStyle(
  fontFamily: 'Consolas',
  fontFamilyFallback: ['Menlo', 'monospace'],
  fontSize: 12,
  height: 1.5,
);

/// 展示残局分享码：关闭弹窗后再写入剪贴板，避免阻塞界面。
Future<void> showPuzzleShareDialog(
  BuildContext context,
  CustomPuzzle puzzle,
) async {
  final theme = Theme.of(context);
  final code = PuzzleShareCode.encode(puzzle);
  final copy = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('分享「${puzzle.title}」'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '把分享码发给好友，在残局挑战页点「导入」粘贴即可离线添加。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(code, style: _codeStyle),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.copy_all_outlined, size: 17),
          label: const Text('复制分享码'),
        ),
      ],
    ),
  );
  if (copy != true) return;
  // 剪贴板写入在部分平台需要额外往返；先给出反馈，失败也不影响展示的分享码。
  Clipboard.setData(ClipboardData(text: code)).ignore();
  if (context.mounted) showSnack(context, '分享码已复制到剪贴板');
}

/// 粘贴并解析分享码，返回校验通过的残局；取消或格式错误时返回 null。
Future<CustomPuzzle?> showPuzzleImportDialog(BuildContext context) async {
  final theme = Theme.of(context);
  var draft = '';
  String? error;
  final result = await showDialog<CustomPuzzle>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('导入分享码'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '粘贴好友发来的 GMK1~ 分享码，导入后保存在「我的残局」。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                minLines: 3,
                maxLines: 5,
                style: _codeStyle,
                onChanged: (value) {
                  draft = value;
                  if (error != null) setState(() => error = null);
                },
                decoration: InputDecoration(
                  hintText: 'GMK1~…',
                  border: const OutlineInputBorder(),
                  errorText: error,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final puzzle = PuzzleShareCode.decode(draft);
              if (puzzle == null) {
                setState(() => error = '分享码无效或已损坏');
                return;
              }
              Navigator.of(dialogContext).pop(puzzle);
            },
            child: const Text('导入'),
          ),
        ],
      ),
    ),
  );
  return result;
}
