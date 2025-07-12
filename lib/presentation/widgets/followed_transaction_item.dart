import 'package:flutter/material.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/utils/formatters.dart';

class FollowedTransactionItem extends StatelessWidget {
  final TransactionWithCounterparty transactionWithCounterparty;
  final VoidCallback? onTap;
  final VoidCallback? onStarTap;
  final double? width;
  final Widget? slideAnimation;

  const FollowedTransactionItem({
    super.key,
    required this.transactionWithCounterparty,
    this.onTap,
    this.onStarTap,
    this.width = 250,
    this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final transaction = transactionWithCounterparty.transaction;
    final counterparty = transactionWithCounterparty.counterparty;
    final isDebit =
        transaction.transactionType == AppConstants.transactionTypeDebit;

    final content = Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.containerDarkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.1), width: 1),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: IntrinsicHeight(
          // Permet au widget de prendre la hauteur nécessaire
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icône du tiers/catégorie dans un cercle
              Container(
                width: 32, // Réduire la taille
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTransactionIcon(transaction, counterparty),
                  color: AppColors.textLight,
                  size: 16, // Réduire la taille de l'icône
                ),
              ),

              const SizedBox(width: 8), // Réduire l'espacement
              // Informations de la transaction
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize:
                      MainAxisSize.min, // Important : ajuster au contenu
                  children: [
                    // Nom du tiers ou titre
                    Text(
                      _getTransactionDisplayName(transaction, counterparty),
                      style: AppTextStyles.followedTransactionName.copyWith(
                        fontSize: 12, // Réduire la taille
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 1), // Réduire l'espacement
                    // Date
                    Text(
                      AppFormatters.formatDate(transaction.date, context),
                      style: AppTextStyles.followedTransactionDate.copyWith(
                        color: AppColors.textGray,
                        fontSize: 10, // Réduire la taille
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6), // Réduire l'espacement
              // Montant
              Text(
                AppFormatters.formatAmountClean(
                  isDebit ? -transaction.amount : transaction.amount,
                  transaction.currency,
                  showSign: false,
                  context: context,
                ),
                style: AppTextStyles.followedTransactionAmount.copyWith(
                  fontSize: 11, // Réduire la taille
                ),
              ),

              const SizedBox(width: 6), // Réduire l'espacement
              // Étoile (bouton pour retirer du suivi)
              GestureDetector(
                onTap: onStarTap,
                child: Container(
                  padding: const EdgeInsets.all(2), // Réduire le padding
                  child: const Icon(
                    Icons.star,
                    color: AppColors.textLight,
                    size: 14, // Réduire la taille
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Si une animation est fournie, l'appliquer
    return slideAnimation ?? content;
  }

  /// Récupère l'icône à afficher pour la transaction
  IconData _getTransactionIcon(
    Transaction transaction,
    Counterparty? counterparty,
  ) {
    // Si la transaction a un tiers avec une icône
    if (counterparty?.icon != null) {
      return _getIconFromString(counterparty!.icon!);
    }

    // Sinon, utiliser l'icône basée sur le titre
    return _getIconFromTitle(transaction.title);
  }

  /// Récupère le nom à afficher pour la transaction
  String _getTransactionDisplayName(
    Transaction transaction,
    Counterparty? counterparty,
  ) {
    // Priorité 1: Nom du tiers
    if (counterparty?.name != null) {
      return counterparty!.name;
    }

    // Priorité 2: Titre de la transaction
    if (transaction.title?.isNotEmpty == true) {
      return transaction.title!;
    }

    // Priorité 3: Type de transaction par défaut
    return transaction.transactionType == AppConstants.transactionTypeDebit
        ? 'Débit'
        : 'Crédit';
  }

  /// Convertit une string d'icône en IconData
  IconData _getIconFromString(String iconString) {
    switch (iconString.toLowerCase()) {
      case 'tv':
        return Icons.tv;
      case 'phone_iphone':
        return Icons.phone_iphone;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'music_note':
        return Icons.music_note;
      case 'restaurant':
        return Icons.restaurant;
      case 'work':
        return Icons.work;
      case 'account_balance':
        return Icons.account_balance;
      case 'business':
        return Icons.business;
      default:
        return Icons.payment;
    }
  }

  /// Récupère une icône basée sur le titre de la transaction
  IconData _getIconFromTitle(String? title) {
    if (title == null) return Icons.payment;

    final titleLower = title.toLowerCase();

    if (titleLower.contains('netflix')) return Icons.tv;
    if (titleLower.contains('spotify')) return Icons.music_note;
    if (titleLower.contains('restaurant') || titleLower.contains('food')) {
      return Icons.restaurant;
    }
    if (titleLower.contains('gas') || titleLower.contains('essence')) {
      return Icons.local_gas_station;
    }
    if (titleLower.contains('shopping') || titleLower.contains('achat')) {
      return Icons.shopping_cart;
    }
    if (titleLower.contains('salary') || titleLower.contains('salaire')) {
      return Icons.work;
    }
    if (titleLower.contains('bank') || titleLower.contains('banque')) {
      return Icons.account_balance;
    }

    return Icons.payment;
  }
}
