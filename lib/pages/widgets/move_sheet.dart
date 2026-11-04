import 'package:flutter/material.dart';

import '../../models/move_record.dart';
import 'move_list.dart';

/// 底部棋谱面板，对局页与残局页共用。
Future<void> showMoveSheet(
  BuildContext context, {
  required Listenable listenable,
  required List<MoveRecord> moves,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.of(sheetContext).size.height * 0.55,
      child: AnimatedBuilder(
        animation: listenable,
        builder: (context, _) => MoveList(
          history: moves,
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
        ),
      ),
    ),
  );
}
