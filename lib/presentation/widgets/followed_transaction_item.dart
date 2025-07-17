import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FollowedTransactionItem extends StatelessWidget {
  final domain.TransactionWithBalance transactionWithCounterparty;
  final VoidCallback? onTap;
  final VoidCallback? onIconTap;
  final double? width;
  final Widget? slideAnimation;

  const FollowedTransactionItem({
    super.key,
    required this.transactionWithCounterparty,
    this.onTap,
    this.onIconTap,
    this.width = 320,
    this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final transaction = transactionWithCounterparty.transaction;
    final counterparty = transactionWithCounterparty.counterparty;
    final isExpense = transactionWithCounterparty.isExpense;

    final content = Container(
      width: width != null ? width?.w : width,
      margin: EdgeInsets.only(right: 18.r),
      padding: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding.r),
      decoration: BoxDecoration(
        color: AppColors.containerDarkGray,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.0),
          width: 1.w,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icône du tiers/catégorie dans un cercle
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTransactionIcon(transaction, counterparty),
                color: AppColors.textLight100,
                size: 16.sp, // Réduire la taille de l'icône
              ),
            ),

            SizedBox(width: AppConstants.defaultPadding.r),
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
                    style: AppTextStyles.followedTransactionName.copyWith(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 2.r),
                  // Date
                  Text(
                    AppFormatters.formatDate(
                      transaction.date,
                      context,
                    ).toUpperCase(),
                    style: AppTextStyles.followedTransactionDate.copyWith(
                      color: AppColors.textDefaultGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: AppConstants.defaultPadding.r),
            // Montant
            Text(
              AppFormatters.formatAmountClean(
                transaction.amount,
                transaction.currency,
                showSign: true,
                context: context,
              ),
              style: AppTextStyles.followedTransactionAmount.copyWith(
                color: isExpense
                    ? AppColors.secondaryPink
                    : AppColors.primaryGreen,
              ),
            ),

            SizedBox(width: AppConstants.defaultPadding.r),
            // Étoile (bouton pour retirer du suivi)
            GestureDetector(
              onTap: onIconTap,
              child: Container(
                padding: EdgeInsets.all(2.r), // Réduire le padding
                child: Icon(
                  Icons.bookmark,
                  color: AppColors.onSurfaceDark,
                  size: 22.sp, // Réduire la taille
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Si une animation est fournie, l'appliquer
    return slideAnimation ?? content;
  }

  /// Récupère l'icône à afficher pour la transaction
  IconData _getTransactionIcon(
    domain.Transaction transaction,
    domain.Counterparty? counterparty,
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
    domain.Transaction transaction,
    domain.Counterparty? counterparty,
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
    return transaction.type == domain.TransactionType.expense
        ? 'Dépense'
        : 'Revenu';
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
