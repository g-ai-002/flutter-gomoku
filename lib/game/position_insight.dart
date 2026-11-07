import 'dart:math' as math;
import 'dart:typed_data';

import 'engine/board_utils.dart';
import 'engine/evaluation.dart';
import 'engine/rules.dart';

/// 形势判断：把棋型评估折算成黑棋胜率，仅供界面参考。
///
/// 评估只读取棋盘，不搜索后续着法，因此以「优势」而非「胜负」解读；
/// 未分胜负的局面把胜率限制在 2%–98%，避免静态分数给出虚假的确定性。
class PositionInsight {
  const PositionInsight._(this.blackRate);

  /// 黑棋胜率，取值 0–1。
  final double blackRate;

  int get blackPercent => (blackRate * 100).round();

  int get whitePercent => 100 - blackPercent;

  /// 形势概括，用于浮层与测试。
  String get label {
    if ((blackRate - 0.5).abs() < 0.05) return '均势';
    return blackRate > 0.5 ? '黑优' : '白优';
  }

  /// 评估分差每增加该值，胜率再向两侧推进一个 logistic 单位。
  static const double _scale = 6000;

  static const double _minRate = 0.02;

  static PositionInsight of(Uint8List cells) {
    final line = GomokuRules.firstWinningLine(cells);
    if (line.isNotEmpty) {
      return PositionInsight._(cells[line.first] == black ? 1 : 0);
    }
    final scores = GomokuEvaluation.totalScores(cells);
    final rate = 1 / (1 + math.exp(-(scores[0] - scores[1]) / _scale));
    return PositionInsight._(rate.clamp(_minRate, 1 - _minRate));
  }
}
