import 'opening_book.dart';

/// 一条自对弈学到的开局：八手着法，前六手与内置开局一致。
typedef LearnedLine = ({OpeningLine opening, int wins});

/// 本地开局精研库：训练结果编码成一行文本存入偏好，无需联网。
class LearnedBook {
  const LearnedBook(this.lines);

  static const LearnedBook empty = LearnedBook([]);

  final List<LearnedLine> lines;

  bool get isEmpty => lines.isEmpty;

  int get totalWins => lines.fold(0, (sum, line) => sum + line.wins);

  /// 精研线替换同 id 的内置开局，未被精研的开局保持原样。
  OpeningBook applyTo(OpeningBook base) {
    final ids = {for (final line in lines) line.opening.id};
    return OpeningBook([
      for (final line in lines) line.opening,
      for (final line in base.lines)
        if (!ids.contains(line.id)) line,
    ]);
  }

  String encode() => [
    for (final line in lines)
      '${line.opening.id}|${line.opening.name}|${line.wins}'
          '|${line.opening.moves.join('.')}',
  ].join(';');

  static LearnedBook decode(String? raw) {
    if (raw == null || raw.isEmpty) return empty;
    final lines = <LearnedLine>[];
    for (final entry in raw.split(';')) {
      final parts = entry.split('|');
      if (parts.length != 4) continue;
      final wins = int.tryParse(parts[2]);
      final moves = [
        for (final token in parts[3].split('.')) int.tryParse(token) ?? -1,
      ];
      if (wins == null || moves.length < 7 || moves.any((move) => move < 0)) {
        continue;
      }
      lines.add((
        opening: OpeningLine(id: parts[0], name: parts[1], moves: moves),
        wins: wins,
      ));
    }
    return LearnedBook(lines);
  }
}
