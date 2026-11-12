import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 纵向界面（状态条与操作按钮）占用的高度，与棋盘页骨架保持一致。
const double _chrome = 104;

/// 把窗口按指定朝向摆放时棋盘可用的边长。
double _side(double width, double height) => math.min(width, height - _chrome);

/// 15×15 网格是正方形：只有横屏能给出明显更大的边长时才值得旋转。
bool prefersLandscapeGrid(Size size) =>
    _side(size.height, size.width) > _side(size.width, size.height) * 1.02;

/// 仅手机与折叠屏折叠态等窄屏 Android 设备考虑自动横屏，平板、桌面与 Web 不旋转。
bool shouldEnterImmersiveLandscape(Size size) =>
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android &&
    size.shortestSide < 600 &&
    prefersLandscapeGrid(size);

/// 对局、残局与复盘页共用的页面骨架：单行紧凑标题栏与安全区内容。
///
/// 标题栏只占 46 高，把纵向空间尽量留给棋盘；窄屏设备按网格比例决定是否横屏。
class BoardPageScaffold extends StatelessWidget {
  const BoardPageScaffold({
    super.key,
    required this.title,
    required this.caption,
    required this.body,
    this.actions = const [],
  });

  final String title;

  /// 标题右侧的副标题，展示难度、执子或棋谱名称。
  final String caption;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 46,
        titleSpacing: 4,
        title: Row(
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        actions: [...actions, const SizedBox(width: 4)],
      ),
      body: SafeArea(child: BoardDisplayMode(child: body)),
    );
  }
}

/// 棋盘页显示模式：需要横屏时锁定横屏并隐藏系统栏，离开页面后恢复系统方向。
class BoardDisplayMode extends StatefulWidget {
  const BoardDisplayMode({super.key, required this.child});

  final Widget child;

  @override
  State<BoardDisplayMode> createState() => _BoardDisplayModeState();
}

class _BoardDisplayModeState extends State<BoardDisplayMode> {
  bool _applied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wanted = shouldEnterImmersiveLandscape(MediaQuery.sizeOf(context));
    if (wanted == _applied) return;
    _applied = wanted;
    _apply(wanted);
  }

  void _apply(bool landscape) {
    SystemChrome.setPreferredOrientations(
      landscape
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : DeviceOrientation.values,
    );
    SystemChrome.setEnabledSystemUIMode(
      landscape ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  @override
  void dispose() {
    if (_applied) _apply(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
