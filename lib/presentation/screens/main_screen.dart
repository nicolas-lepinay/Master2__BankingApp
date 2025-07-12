import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/providers/navigation_provider.dart';
import 'package:bankapp/presentation/screens/home_screen.dart';
import 'package:bankapp/presentation/screens/settings_screen.dart';
import 'package:bankapp/presentation/widgets/floating_navbar.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    final l10n = AppLocalizations.of(context)!;

    // Déterminer si le fond est sombre pour adapter la navbar
    bool isDarkBackground = _isDarkBackground(currentIndex);

    return Scaffold(
      body: Stack(
        children: [
          // Contenu principal
          IndexedStack(
            index: currentIndex,
            children: const [
              HomeScreen(), // Index 0 - Home
              Center(child: Text('Menu/Tiers')), // Index 1 - Menu/Tiers
              Center(child: Text('Statistiques')), // Index 2 - Statistiques
              SettingsScreen(), // Index 3 - Paramètres
            ],
          ),

          // Navbar flottante
          FloatingNavbar(
            currentIndex: currentIndex,
            isDarkBackground: isDarkBackground,
            onTap: (index) {
              ref.read(navigationProvider.notifier).setIndex(index);
            },
          ),
        ],
      ),
    );
  }

  /// Détermine si le fond de l'écran actuel est sombre
  bool _isDarkBackground(int screenIndex) {
    switch (screenIndex) {
      case 0: // Home Screen
        return true; // DraggableBlackContainer = fond sombre
      case 1: // Menu/Tiers
        return false; // Présumé fond clair
      case 2: // Statistiques
        return false; // Présumé fond clair
      case 3: // Paramètres
        return false; // Fond clair (SettingsScreen)
      default:
        return true;
    }
  }
}
