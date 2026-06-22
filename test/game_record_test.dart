import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gomoku/models/game_record.dart';
import 'package:flutter_gomoku/models/game_state.dart';
import 'package:flutter_gomoku/ai/ai_engine.dart';

void main() {
  group('GameRecord', () {
    final moves = [
      const Move(position: Position(7, 7), color: StoneColor.black, stepNumber: 1),
      const Move(position: Position(7, 8), color: StoneColor.white, stepNumber: 2),
    ];

    final record = GameRecord(
      id: '12345',
      date: DateTime(2026, 6, 22, 10, 30),
      mode: GameMode.pvp,
      boardSize: 15,
      result: GameStatus.blackWin,
      moves: moves,
    );

    test('基本属性', () {
      expect(record.id, equals('12345'));
      expect(record.boardSize, equals(15));
      expect(record.mode, equals(GameMode.pvp));
      expect(record.result, equals(GameStatus.blackWin));
      expect(record.totalMoves, equals(2));
    });

    test('resultLabel', () {
      expect(record.resultLabel, equals('黑棋胜'));
      expect(
        GameRecord(
          id: '1',
          date: DateTime.now(),
          mode: GameMode.pvp,
          boardSize: 15,
          result: GameStatus.whiteWin,
          moves: [],
        ).resultLabel,
        equals('白棋胜'),
      );
      expect(
        GameRecord(
          id: '2',
          date: DateTime.now(),
          mode: GameMode.pvp,
          boardSize: 15,
          result: GameStatus.draw,
          moves: [],
        ).resultLabel,
        equals('平局'),
      );
    });

    test('modeLabel', () {
      expect(record.modeLabel, equals('双人对弈'));
      final pveRecord = GameRecord(
        id: '3',
        date: DateTime.now(),
        mode: GameMode.pve,
        aiDifficulty: AIDifficulty.hard,
        boardSize: 15,
        result: GameStatus.blackWin,
        moves: [],
      );
      expect(pveRecord.modeLabel, equals('人机(困难)'));
    });

    test('JSON 序列化/反序列化', () {
      final json = record.toJson();
      expect(json['id'], equals('12345'));
      expect(json['boardSize'], equals(15));
      expect(json['mode'], equals('pvp'));
      expect(json['result'], equals('blackWin'));
      expect((json['moves'] as List).length, equals(2));

      final restored = GameRecord.fromJson(json);
      expect(restored.id, equals(record.id));
      expect(restored.boardSize, equals(record.boardSize));
      expect(restored.mode, equals(record.mode));
      expect(restored.result, equals(record.result));
      expect(restored.moves.length, equals(record.moves.length));
      expect(restored.moves[0].position.row, equals(7));
      expect(restored.moves[0].position.col, equals(7));
    });

    test('JSON 字符串序列化/反序列化', () {
      final str = record.toJsonString();
      final restored = GameRecord.fromJsonString(str);
      expect(restored.id, equals(record.id));
      expect(restored.moves.length, equals(2));
    });

    test('AI 难度为 null 时序列化', () {
      final json = record.toJson();
      expect(json['aiDifficulty'], isNull);

      final restored = GameRecord.fromJson(json);
      expect(restored.aiDifficulty, isNull);
    });

    test('AI 难度非 null 时序列化', () {
      final pveRecord = GameRecord(
        id: '4',
        date: DateTime.now(),
        mode: GameMode.pve,
        aiDifficulty: AIDifficulty.medium,
        boardSize: 13,
        result: GameStatus.whiteWin,
        moves: [],
      );
      final json = pveRecord.toJson();
      expect(json['aiDifficulty'], equals('medium'));

      final restored = GameRecord.fromJson(json);
      expect(restored.aiDifficulty, equals(AIDifficulty.medium));
    });
  });
}
