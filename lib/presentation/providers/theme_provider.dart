import 'package:bankapp/core/services/user_preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enum pour les modes de thème
enum ThemeMode { light, dark, system }

// Extension pour convertir enum vers string et vice versa
extension ThemeModeExtension on ThemeMode {
  String get value {
    switch (this) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode fromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light; // Valeur par défaut
    }
  }
}

// State notifier pour gérer le thème avec persistance
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final UserPreferencesService _preferencesService;

  ThemeNotifier(this._preferencesService) : super(ThemeMode.light) {
    _loadTheme();
  }

  // Charger le thème sauvegardé
  Future<void> _loadTheme() async {
    await _preferencesService.init();
    final savedTheme = _preferencesService.getThemeMode();
    state = ThemeModeExtension.fromString(savedTheme);
  }

  // Définir le thème et le sauvegarder
  Future<void> setTheme(ThemeMode theme) async {
    state = theme;
    await _preferencesService.setThemeMode(theme.value);
  }

  void toggleTheme() {
    switch (state) {
      case ThemeMode.light:
        setTheme(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setTheme(ThemeMode.light);
        break;
      case ThemeMode.system:
        setTheme(ThemeMode.light);
        break;
    }
  }
}

// Provider pour le thème
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier(UserPreferencesService.instance);
});
