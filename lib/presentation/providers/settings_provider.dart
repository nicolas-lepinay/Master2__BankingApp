import 'package:bankapp/core/services/user_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enum pour les langues supportées
enum AppLanguage { system, english, french }

extension AppLanguageExtension on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.system:
        return 'system';
      case AppLanguage.english:
        return 'en';
      case AppLanguage.french:
        return 'fr';
    }
  }

  // Méthode pour convertir une string vers AppLanguage
  static AppLanguage fromString(String value) {
    switch (value) {
      case 'system':
        return AppLanguage.system;
      case 'en':
        return AppLanguage.english;
      case 'fr':
        return AppLanguage.french;
      default:
        return AppLanguage.system; // Valeur par défaut
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.system:
        return 'Système / System';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.french:
        return 'Français';
    }
  }

  Locale? get locale {
    switch (this) {
      case AppLanguage.system:
        return null; // Utilise la locale du système
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.french:
        return const Locale('fr');
    }
  }
}

// State notifier pour gérer la langue avec persistance
class LanguageNotifier extends StateNotifier<AppLanguage> {
  final UserPreferencesService _preferencesService;

  LanguageNotifier(this._preferencesService) : super(AppLanguage.system) {
    _loadLanguage();
  }

  // Charger la langue sauvegardée
  Future<void> _loadLanguage() async {
    await _preferencesService.init();
    final savedLanguage = _preferencesService.getLanguage();
    state = AppLanguageExtension.fromString(savedLanguage);
  }

  // Définir la langue et la sauvegarder
  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    await _preferencesService.setLanguage(language.code);
  }
}

// Provider pour la langue
final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((
  ref,
) {
  return LanguageNotifier(UserPreferencesService.instance);
});
