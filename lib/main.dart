import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bankapp/core/theme/app_theme.dart';
import 'package:bankapp/presentation/providers/theme_provider.dart'
    as theme_provider;
import 'package:bankapp/presentation/providers/settings_provider.dart';
import 'package:bankapp/presentation/screens/splash_screen.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(theme_provider.themeProvider);
    final selectedLanguage = ref.watch(languageProvider);

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

      // Home screen
      home: const SplashScreen(),
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
