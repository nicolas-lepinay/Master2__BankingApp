import 'package:flutter/material.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/core/constants/app_constants.dart';

class PerspectiveTransactionItem extends StatelessWidget {
  final TransactionWithCounterparty transactionWithCounterparty;
  final VoidCallback? onTap;

  const PerspectiveTransactionItem({
    super.key,
    required this.transactionWithCounterparty,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final transaction = transactionWithCounterparty.transaction;
    final counterparty = transactionWithCounterparty.counterparty;
    final isDebit =
        transaction.transactionType == AppConstants.transactionTypeDebit;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ), // Réduire margin verticale
        padding: const EdgeInsets.all(12), // Réduire padding
        decoration: BoxDecoration(
          color: AppColors.transactionItemBg, // #FFCDF8
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2), // Ombre vers le haut
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icône du tiers/catégorie dans un cercle
            Container(
              width: 44, // Réduire la taille
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getTransactionIcon(transaction, counterparty),
                color: AppColors.textDark,
                size: 20, // Réduire la taille de l'icône
              ),
            ),

            const SizedBox(width: 12), // Réduire l'espacement
            // Informations de la transaction
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize
                    .min, // Important : ajuster la taille au contenu
                children: [
                  // Nom du tiers ou titre de la transaction
                  Text(
                    _getTransactionDisplayName(transaction, counterparty),
                    style: AppTextStyles.transactionNamePerspective.copyWith(
                      fontSize: 15, // Réduire légèrement la taille
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),
                  // Date de la transaction
                  Text(
                    AppFormatters.formatDate(transaction.date, context),
                    style: AppTextStyles.transactionCategoryPerspective
                        .copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),
            // Montant de la transaction
            Text(
              AppFormatters.formatAmountClean(
                isDebit ? -transaction.amount : transaction.amount,
                transaction.currency,
                showSign: true,
                context: context,
              ),
              style: AppTextStyles.transactionAmountPerspective,
            ),
          ],
        ),
      ),
    );
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
