import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/constants/gradient_colors.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PerspectiveTransactionItem extends StatelessWidget {
  final domain.TransactionWithBalance transactionWithCounterparty;
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
    final isExpense = transactionWithCounterparty.isExpense;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppConstants.mediumPadding.r,
          vertical: 4.r,
        ),
        padding: EdgeInsets.symmetric(horizontal: AppConstants.largePadding.r),
        decoration: BoxDecoration(
          color: AppColors.transactionItemBg,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: GradientColors.pink.first.withValues(alpha: 0.35),
              blurRadius: 10.r,
              offset: Offset(0, -8.0.r), // Ombre vers le haut
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icône du tiers/catégorie dans un cercle
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: GradientColors.pink.first.withValues(alpha: 0.35),
                    blurRadius: 6.r,
                    offset: Offset(0, 4.r),
                  ),
                ],
              ),
              child: Icon(
                _getTransactionIcon(transactionWithCounterparty),
                color: AppColors.textDark25,
                size: 22.sp, // Réduire la taille de l'icône
              ),
            ),

            SizedBox(width: AppConstants.largePadding.r),
            // Informations de la transaction
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nom du tiers ou titre de la transaction
                  Text(
                    _getTransactionDisplayName(transactionWithCounterparty),
                    style: AppTextStyles.transactionNamePerspective,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 2.r),
                  // Date de la transaction
                  Text(
                    AppFormatters.formatDate(
                      transaction.date,
                      context,
                    ).toUpperCase(),
                    style: AppTextStyles.transactionCategoryPerspective,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: AppConstants.defaultPadding.r),
            // Montant de la transaction
            Text(
              AppFormatters.formatAmountClean(
                isExpense ? -transaction.amount : transaction.amount,
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
  IconData _getTransactionIcon(domain.TransactionWithBalance transaction) {
    // Si la transaction a un tiers avec une icône
    if (transaction.counterparty?.icon != null) {
      return _getIconFromString(transaction.counterparty!.icon!);
    }

    // Sinon, utiliser l'icône basée sur le titre
    return _getIconFromTitle(transaction.transaction.title);
  }

  /// Récupère le nom à afficher pour la transaction
  String _getTransactionDisplayName(domain.TransactionWithBalance transaction) {
    // Priorité 1: Nom du tiers
    if (transaction.counterparty?.name != null) {
      return transaction.counterparty!.name;
    }

    // Priorité 2: Titre de la transaction
    if (transaction.transaction.title?.isNotEmpty == true) {
      return transaction.transaction.title!;
    }

    // Priorité 3: Type de transaction par défaut
    return transaction.isExpense ? 'Dépense' : 'Revenu';
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
