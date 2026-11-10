import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../services/log_service.dart';
import '../services/sound_service.dart';
import 'constants.dart';

/// 桌面窗口初始化：仅 Windows 生效，设定初始尺寸并居中显示。
Future<void> setupDesktopWindow() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;
  try {
    final window = WindowManager.instance.getCurrent();
    if (window == null) {
      LogService.warning('窗口管理器初始化失败: 未取到当前窗口');
      return;
    }
    window.title = AppConstants.appName;
    window.titleBarStyle = TitleBarStyle.normal;
    window.isVisibleInTaskbar = true;
    window.minimumSize = const Size(400, 360).toNative();
    window.setSize(const Size(1120, 820).toNative(), false);
    window.center();
    window.show();
    window.focus();
    window.addListener(_handleWindowEvent);
  } catch (e) {
    LogService.warning('窗口管理器初始化失败: $e');
  }
}

/// 关窗请求：先释放音频引擎，再让它继续关窗。
///
/// 标题栏关闭会先变成可挂起的关闭请求，回调返回的 Future 完成前窗口不会被销毁，
/// 这段等待正好用来 deinit。否则音频设备与回调只能被动拆除，Windows 上进程会
/// 卡住不退出（窗口关了、进程还在）。
Future<void> _handleWindowEvent(WindowEvent event) async {
  if (event is! WindowCloseRequestedEvent) return;
  try {
    await SoundService.shutdown();
  } catch (error) {
    // 释放失败也要放行关闭，不能把窗口卡住。
    LogService.warning('退出前释放音频引擎失败: $error');
  }
}
