import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/presentation/providers/theme_provider.dart'
    as theme_provider;
import 'package:bankapp/presentation/providers/settings_provider.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentTheme = ref.watch(theme_provider.themeProvider);
    final currentLanguage = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // Section Apparence
          _buildSectionHeader(context, 'Apparence'),

          // Thème
          Card(
            child: ListTile(
              leading: Icon(
                _getThemeIcon(currentTheme),
                color: AppColors.primary,
              ),
              title: const Text('Thème'),
              subtitle: Text(_getThemeLabel(currentTheme)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showThemeSelector(context, ref, currentTheme),
            ),
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Section Langue
          _buildSectionHeader(context, 'Langue / Language'),

          // Sélecteur de langue
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: const Text('Langue de l\'application'),
              subtitle: Text(currentLanguage.displayName),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageSelector(context, ref, currentLanguage),
            ),
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Section Application
          _buildSectionHeader(context, 'Application'),

          // Version de l'app
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('Version'),
              subtitle: const Text('1.0.0+1'),
            ),
          ),

          // À propos
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline, color: AppColors.primary),
              title: const Text('À propos'),
              subtitle: const Text('Application de gestion bancaire'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showAboutDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.defaultPadding,
        bottom: AppConstants.smallPadding,
      ),
      child: Text(
        title,
        style: AppTextStyles.h6.copyWith(color: AppColors.primary),
      ),
    );
  }

  IconData _getThemeIcon(theme_provider.ThemeMode themeMode) {
    switch (themeMode) {
      case theme_provider.ThemeMode.light:
        return Icons.light_mode;
      case theme_provider.ThemeMode.dark:
        return Icons.dark_mode;
      case theme_provider.ThemeMode.system:
        return Icons.settings_brightness;
    }
  }

  String _getThemeLabel(theme_provider.ThemeMode themeMode) {
    switch (themeMode) {
      case theme_provider.ThemeMode.light:
        return 'Clair';
      case theme_provider.ThemeMode.dark:
        return 'Sombre';
      case theme_provider.ThemeMode.system:
        return 'Automatique (Système)';
    }
  }

  void _showThemeSelector(
    BuildContext context,
    WidgetRef ref,
    theme_provider.ThemeMode currentTheme,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choisir le thème', style: AppTextStyles.h6),

            const SizedBox(height: AppConstants.defaultPadding),

            ...theme_provider.ThemeMode.values.map((theme) {
              return ListTile(
                leading: Icon(_getThemeIcon(theme)),
                title: Text(_getThemeLabel(theme)),
                trailing: currentTheme == theme
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref
                      .read(theme_provider.themeProvider.notifier)
                      .setTheme(theme);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    AppLanguage currentLanguage,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisir la langue / Choose language',
              style: AppTextStyles.h6,
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            ...AppLanguage.values.map((language) {
              return ListTile(
                leading: Icon(
                  _getLanguageIcon(language),
                  color: AppColors.primary,
                ),
                title: Text(language.displayName),
                trailing: currentLanguage == language
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage(language);
                  Navigator.of(context).pop();

                  // Afficher un message de confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        language == AppLanguage.french
                            ? 'Langue changée vers ${language.displayName}'
                            : 'Language changed to ${language.displayName}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getLanguageIcon(AppLanguage language) {
    switch (language) {
      case AppLanguage.system:
        return Icons.settings;
      case AppLanguage.english:
        return Icons.flag; // Ou une icône spécifique
      case AppLanguage.french:
        return Icons.flag; // Ou une icône spécifique
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Bank App',
      applicationVersion: '1.0.0+1',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.account_balance,
          color: AppColors.textLight,
          size: 30,
        ),
      ),
      children: [
        const Text(
          'Application de gestion de transactions bancaires développée avec Flutter.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Fonctionnalités:\n'
          '• Gestion des comptes\n'
          '• Suivi des transactions\n'
          '• Calcul automatique des soldes\n'
          '• Interface multilingue\n'
          '• Thème clair/sombre',
        ),
      ],
    );
  }
}
