import 'package:flutter/material.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/core/theme/app_colors.dart';

class CardColorUtils {
  // Liste des couleurs dans l'ordre souhaité
  static List<Color> cardColors = [
    AppColors.cardPurple, // Violet
    AppColors.cardPink, // Rose
    AppColors.cardGreen, // Vert fluo
    AppColors.cardOrange, // Orange
    AppColors.cardPurple2, // Violet clair
    AppColors.cardRed, // Rouge/Rose foncé
  ];

  /// Retourne la couleur d'une carte basée sur la liste des comptes
  /// Respecte l'ordre des couleurs même avec des IDs non-consécutifs
  static Color getCardColor(Account account, List<Account> allAccounts) {
    // Trier les comptes par ID pour avoir un ordre stable
    final sortedAccounts = List<Account>.from(allAccounts)
      ..sort((a, b) => a.id.compareTo(b.id));

    // Trouver l'index du compte dans la liste triée
    final accountIndex = sortedAccounts.indexWhere((a) => a.id == account.id);

    // Si le compte n'est pas trouvé, utiliser l'ID comme fallback
    if (accountIndex == -1) {
      return cardColors[(account.id - 1) % cardColors.length];
    }

    // Utiliser l'index dans la liste triée pour déterminer la couleur
    return cardColors[accountIndex % cardColors.length];
  }

  /// Version simplifiée pour quand on a juste l'ID du compte
  static Color getCardColorById(int accountId, List<Account> allAccounts) {
    final account = allAccounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => Account(
        id: accountId,
        name: '',
        currency: '',
        initialBalance: 0,
        creationDate: DateTime.now(),
      ),
    );
    return getCardColor(account, allAccounts);
  }
}
