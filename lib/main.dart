import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'providers/game_provider.dart';
import 'services/log_service.dart';
import 'services/logging_init.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'utils/window_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupDesktopWindow();

  final storage = await StorageService.instance;
  await initLogging();
  LogService.info('应用启动: ${AppConstants.appName} v${AppConstants.version}');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(GomokuApp(storage: storage));
}

class GomokuApp extends StatelessWidget {
  final StorageService storage;
  const GomokuApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final fontFamily =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
            ? 'Microsoft YaHei UI'
            : null;
    return ChangeNotifierProvider(
      create: (_) => GameProvider(storage),
      child: Consumer<GameProvider>(
        builder: (context, game, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(fontFamily: fontFamily),
            darkTheme: buildDarkTheme(fontFamily: fontFamily),
            themeMode: game.darkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('zh', 'CN')],
            locale: const Locale('zh', 'CN'),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
