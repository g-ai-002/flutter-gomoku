import 'dart:convert';
import '../ai/ai_engine.dart';
import 'game_state.dart';

/// 对局记录
class GameRecord {
  final String id;
  final DateTime date;
  final GameMode mode;
  final AIDifficulty? aiDifficulty;
  final int boardSize;
  final GameStatus result;
  final List<Move> moves;

  const GameRecord({
    required this.id,
    required this.date,
    required this.mode,
    this.aiDifficulty,
    required this.boardSize,
    required this.result,
    required this.moves,
  });

  int get totalMoves => moves.length;

  String get resultLabel => result.label;

  String get modeLabel {
    if (mode == GameMode.pve && aiDifficulty != null) {
      return '人机(${aiDifficulty!.label})';
    }
    return mode.label;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'mode': mode.name,
        'aiDifficulty': aiDifficulty?.name,
        'boardSize': boardSize,
        'result': result.name,
        'moves': moves
            .map((m) => {
                  'row': m.position.row,
                  'col': m.position.col,
                  'color': m.color.name,
                  'stepNumber': m.stepNumber,
                })
            .toList(),
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mode: GameMode.values.firstWhere((e) => e.name == json['mode']),
      aiDifficulty: json['aiDifficulty'] != null
          ? AIDifficulty.values.firstWhere((e) => e.name == json['aiDifficulty'])
          : null,
      boardSize: json['boardSize'] as int,
      result: GameStatus.values.firstWhere((e) => e.name == json['result']),
      moves: (json['moves'] as List)
          .map((m) => Move(
                position: Position(m['row'] as int, m['col'] as int),
                color: StoneColor.values.firstWhere((e) => e.name == m['color']),
                stepNumber: m['stepNumber'] as int,
              ))
          .toList(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory GameRecord.fromJsonString(String s) =>
      GameRecord.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
