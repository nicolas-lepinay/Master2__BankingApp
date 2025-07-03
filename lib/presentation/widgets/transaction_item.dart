import 'package:flutter/material.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/core/constants/app_constants.dart';

class TransactionItem extends StatelessWidget {
  final TransactionWithBalance transactionWithBalance;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transactionWithBalance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final transaction = transactionWithBalance.transaction;
    final isDebit =
        transaction.transactionType == AppConstants.transactionTypeDebit;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            // Icône de catégorie (carré blanc pour l'instant)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTransactionIcon(transaction.title),
                color: AppColors.textSecondary,
                size: 24,
              ),
            ),

            const SizedBox(width: AppConstants.defaultPadding),

            // Informations de la transaction
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre/nom du tiers
                  Text(
                    transaction.title ?? 'Transaction',
                    style: AppTextStyles.transactionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Commentaire
                  if (transaction.comment?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.comment!,
                      style: AppTextStyles.transactionDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppConstants.defaultPadding),

            // Montant et solde
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Montant de la transaction
                Text(
                  AppFormatters.formatAmount(
                    isDebit ? -transaction.amount : transaction.amount,
                    transaction.currency,
                    context: context,
                  ),
                  style: AppTextStyles.transactionAmount,
                ),

                const SizedBox(height: 2),

                // Solde après transaction
                Text(
                  AppFormatters.formatCurrency(
                    transactionWithBalance.balanceAfter,
                    transaction.currency,
                    context,
                  ),
                  style: AppTextStyles.transactionBalance.copyWith(
                    color: transactionWithBalance.balanceAfter < 0
                        ? AppColors.debitColor
                        : AppColors.creditColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String? title) {
    if (title == null) return Icons.payment;

    final titleLower = title.toLowerCase();

    if (titleLower.contains('netflix')) return Icons.tv;
    if (titleLower.contains('spotify')) return Icons.music_note;
    if (titleLower.contains('restaurant') || titleLower.contains('food'))
      return Icons.restaurant;
    if (titleLower.contains('gas') || titleLower.contains('essence'))
      return Icons.local_gas_station;
    if (titleLower.contains('shopping') || titleLower.contains('achat'))
      return Icons.shopping_cart;
    if (titleLower.contains('salary') || titleLower.contains('salaire'))
      return Icons.work;
    if (titleLower.contains('bank') || titleLower.contains('banque'))
      return Icons.account_balance;

    return Icons.payment;
  }
}
