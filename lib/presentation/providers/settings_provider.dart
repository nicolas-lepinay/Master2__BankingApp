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

// State notifier pour gérer la langue
class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.system);

  void setLanguage(AppLanguage language) {
    state = language;
  }
}

// Provider pour la langue
final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((
  ref,
) {
  return LanguageNotifier();
});
