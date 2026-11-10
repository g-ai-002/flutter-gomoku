import 'dart:ui' show AppExitResponse;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'providers/settings_provider.dart';
import 'services/music_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'utils/system_ui.dart';

class GomokuApp extends StatefulWidget {
  const GomokuApp({super.key, required this.storage});

  final StorageService storage;

  @override
  State<GomokuApp> createState() => _GomokuAppState();
}

class _GomokuAppState extends State<GomokuApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        MusicService.resumeForLifecycle();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        MusicService.pauseForLifecycle();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Windows 关窗时引擎会先问框架是否允许退出，借这个时机释放 SoLoud。
  ///
  /// 带着音频设备直接退出时，窗口销毁后引擎的拆除会卡住，进程留在任务管理器里
  /// 不退出。这里不能走 window_manager 的关窗监听：它的异步监听会在 Android
  /// 的 AOT 快照阶段报 `Class with illegal cid`，构建直接失败。
  @override
  Future<AppExitResponse> didRequestAppExit() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      await SoundService.shutdown();
    }
    return AppExitResponse.exit;
  }

  @override
  Widget build(BuildContext context) {
    String? fontFamily;
    if (kIsWeb) {
      fontFamily = kWebFontFamily;
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      fontFamily = 'Microsoft YaHei UI';
    }
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(widget.storage),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(fontFamily: fontFamily),
            darkTheme: buildDarkTheme(fontFamily: fontFamily),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('zh', 'CN')],
            locale: const Locale('zh', 'CN'),
            // Web 首次点击用于解除浏览器的自动播放限制。
            builder: (context, child) => SystemUiOverlay(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: kIsWeb
                    ? (_) => MusicService.retryOnInteraction()
                    : null,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
