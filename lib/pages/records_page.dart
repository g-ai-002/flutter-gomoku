import 'package:flutter/material.dart';
import '../models/game_record.dart';
import '../models/game_state.dart';
import '../services/game_record_service.dart';
import 'replay_page.dart';

/// 对局记录列表页面
class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  List<GameRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    final records = await GameRecordService.instance.loadAll();
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
      });
    }
  }

  Future<void> _deleteRecord(GameRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除对局记录'),
        content: const Text('确定要删除这条对局记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GameRecordService.instance.delete(record.id);
      _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('对局记录'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Text(
                    '暂无对局记录',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _records.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return _buildRecordItem(record, theme);
                    },
                  ),
                ),
    );
  }

  Widget _buildRecordItem(GameRecord record, ThemeData theme) {
    final dateStr =
        '${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')} '
        '${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}';

    final resultColor = switch (record.result) {
      GameStatus.blackWin => Colors.black87,
      GameStatus.whiteWin => Colors.grey.shade600,
      GameStatus.draw => theme.colorScheme.onSurfaceVariant,
      _ => theme.colorScheme.onSurfaceVariant,
    };

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReplayPage(record: record),
          ),
        ).then((_) => _loadRecords());
      },
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.sports_esports_outlined,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        '${record.modeLabel} · ${record.boardSize}x${record.boardSize}',
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        '$dateStr · ${record.totalMoves} 手',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            record.resultLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: resultColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: theme.colorScheme.onSurfaceVariant),
            onSelected: (action) {
              if (action == 'delete') _deleteRecord(record);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        ],
      ),
    );
  }
}
