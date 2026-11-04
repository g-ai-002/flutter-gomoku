import 'package:flutter/material.dart';

import '../../services/file_system_service.dart';

/// 导入棋谱弹窗：粘贴文本，或直接选取应用导出目录里的棋谱文件。
class ImportGameDialog extends StatefulWidget {
  const ImportGameDialog({super.key});

  @override
  State<ImportGameDialog> createState() => _ImportGameDialogState();
}

class _ImportGameDialogState extends State<ImportGameDialog> {
  final TextEditingController _input = TextEditingController();
  List<String> _files = const [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final files = await FileSystemService.instance.listRecordFiles();
    if (!mounted || files.isEmpty) return;
    setState(() => _files = files);
  }

  Future<void> _pickFile(String name) async {
    final text = await FileSystemService.instance.readRecordFile(name);
    if (!mounted || text == null) return;
    setState(() {
      _input.text = text;
      _input.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('导入棋谱'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '粘贴导出的棋谱文本，也支持「H8 I9 J10」这类纯坐标记法。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '从已导出的文件导入',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _files.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ActionChip(
                    label: Text(
                      _files[index],
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: () => _pickFile(_files[index]),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _input,
              minLines: 5,
              maxLines: 8,
              style: theme.textTheme.bodySmall,
              decoration: const InputDecoration(
                hintText: '在此粘贴棋谱…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_input.text),
          child: const Text('开始复盘'),
        ),
      ],
    );
  }
}
