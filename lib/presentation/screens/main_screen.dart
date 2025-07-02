import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/providers/navigation_provider.dart';
import 'package:bankapp/presentation/screens/home_screen.dart';
import 'package:bankapp/presentation/widgets/add_transaction_bottom_sheet.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          // Autres écrans seront ajoutés plus tard
          Center(child: Text('Statistiques')),
          Center(child: Text('Paramètres')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // Le bouton central (index 1) ouvre l'écran d'ajout de transaction
          if (index == 1) {
            _showAddTransactionScreen(context);
          } else {
            // Ajuster l'index pour ignorer le bouton central
            final adjustedIndex = index > 1 ? index - 1 : index;
            ref.read(navigationProvider.notifier).setIndex(adjustedIndex);
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.textLight),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }

  void _showAddTransactionScreen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionBottomSheet(),
    );
  }
}
