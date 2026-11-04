import 'package:flutter/material.dart';

/// 列表页统一骨架：居中限宽 + 纵向留白。
///
/// 设置、棋谱库、残局列表与开局库共用同一套滚动与留白规则，
/// 宽屏时内容不会无限拉伸，手机与平板上的边距保持一致。
class PageList extends StatelessWidget {
  const PageList({
    super.key,
    required this.children,
    this.maxWidth = 760,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 24),
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(padding: padding, children: children),
      ),
    );
  }
}
