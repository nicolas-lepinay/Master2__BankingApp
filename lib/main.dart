import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/services/user_preferences_service.dart';
import 'package:bankapp/core/theme/app_theme.dart';
import 'package:bankapp/core/utils/app_logger.dart';
import 'package:bankapp/presentation/providers/settings_provider.dart';
import 'package:bankapp/presentation/providers/theme_provider.dart'
    as theme_provider;
import 'package:bankapp/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les variables d'environnement
  await dotenv.load(fileName: ".env");

  // Initialiser les préférences utilisateur au démarrage
  await UserPreferencesService.instance.init();

  // Test de logging au démarrage
  AppLogger.info(
    'MainApp',
    'main',
    '🚀 Application starting with logging system',
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(theme_provider.themeProvider);
    final selectedLanguage = ref.watch(languageProvider);

    return ScreenUtilInit(
      designSize: const Size(448.0, 997.34),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Bank App',

          // Localizations
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('fr')],

          // Use selected language or system default
          locale: selectedLanguage.locale,

          // Theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _getThemeMode(themeMode),

          // Disable debug banner
          debugShowCheckedModeBanner: false,

          // First screen launched
          home: const SplashScreen(),
        );
      },
    );
  }

  ThemeMode _getThemeMode(theme_provider.ThemeMode mode) {
    switch (mode) {
      case theme_provider.ThemeMode.light:
        return ThemeMode.light;
      case theme_provider.ThemeMode.dark:
        return ThemeMode.dark;
      case theme_provider.ThemeMode.system:
        return ThemeMode.system;
    }
  }
}
