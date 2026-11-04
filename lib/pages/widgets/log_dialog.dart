import 'package:flutter/material.dart';

import '../../services/log_service.dart';

/// 最近日志弹窗：展示内存缓冲中的日志，便于用户定位问题。
void showLogDialog(BuildContext context) {
  final lines = LogService.getRecentLogs(300);
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: SizedBox(
        width: 680,
        height: 480,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
              child: Row(
                children: [
                  Text(
                    '最近日志',
                    style: Theme.of(dialogContext).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: '关闭',
                  ),
                ],
              ),
            ),
            Divider(
              color: Theme.of(dialogContext).colorScheme.outline
                  .withValues(alpha: 0.5),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: Theme.of(dialogContext)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: SelectableText(
                    lines.isEmpty ? '暂无日志' : lines.join('\n'),
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.55,
                      color: Theme.of(dialogContext).colorScheme.onSurface,
                      fontFamily: 'Consolas',
                      fontFamilyFallback: const ['Menlo', 'monospace'],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
